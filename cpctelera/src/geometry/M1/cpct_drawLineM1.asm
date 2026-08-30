;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.globl cpct_plotColorTable_M1
.globl cpct_plotMasksTable_M1
.globl cpct_getScreenPtr_asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawLineM1
;;
;;    Draws a straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using an optimized dual-path Bresenham algorithm.
;;    Includes dedicated fast-path handlers for Single Point, Horizontal, and Vertical
;;    lines, as well as 4 inlined directional rasterizer loops.
;;
;;    This is the standard safe version that PRESERVES ALL ALTERNATE REGISTERS
;;    (AF', BC', DE', HL') for compatibility with interrupt-driven audio players (IM 1).
;;
;; C Definition:
;;    void cpct_drawLineM1(void* screen_base, u16 x0, u16 y0, u16 x1, u8 y1, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B DE) screen_base - Base VRAM memory address
;;    (2B HL) x0          - Starting X coordinate (0-319)
;;    (Stack) y0          - Starting Y coordinate (0-199, 16-bit integer)
;;    (Stack) x1          - Ending X coordinate (0-319, 16-bit integer)
;;    (Stack) color / y1  - Color index (B: 0-3) and Ending Y coordinate (C: 0-199)
;;
;; Assembly call:
;;     > call cpct_drawLineM1
;;
;; Fast-Path Special Cases:
;;    - Single Point  (DX = 0, DY = 0)  : Direct pixel plot using h_plot_one helper.
;;    - Horizontal    (DY = 0, DX != 0) : Byte-aligned fast solid fill.
;;    - Vertical      (DX = 0, DY != 0) : 8-line scanline stepping.
;;
;; Optimized Bresenham Architecture:
;;    1. Dual-Path Split:
;;       - Gentle Slope (DX >= DY) : X is the driving axis (steps unconditionally)
;;       - Steep Slope  (DY > DX)  : Y is the driving axis (steps unconditionally)
;;
;; Known limitations:
;;  * This function will not work from ROM, as it uses self-modifying code.
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;    1160 bytes (1114 bytes routine + 20 bytes data + 26 bytes binding wrapper)
;;
;; Time Measures (Includes +34 us / +136 CPU cycles binding wrapper overhead):
;; (start code)
;;    Case / Coordinates                       | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Setup Overhead (routine + binding)       | -      | ~280           | ~1120
;;    Single Point  (50,50) to (50,50) [Fast]  | 1      | 214            | 856
;;    Horizontal    (0,0)   to (100,0) [Fast]  | 101    | 790            | 3160
;;    Vertical      (0,0)   to (0,100) [Fast]  | 101    | 1730           | 6920
;;    Shallow Slope (0,0)   to (100,25)        | 101    | ~4150          | ~16600
;;    Diagonal 45°  (0,0)   to (100,100)       | 101    | ~4725          | ~18900
;;    Steep Slope   (0,0)   to (25,100)        | 101    | ~4275          | ~17100
;;   ---------------------------------------------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;-------------------------------------------------------------------------------
;; MACROS
;;-------------------------------------------------------------------------------
;; DIV4_HL: HL = HL / 4 (Converts X pixel coordinate to X byte column 0..79)
;;   Execution time: 8 us / 32 CPU cycles
;;   Size: 8 bytes
.macro DIV4_HL
    srl   h                       ;; [2] Shift H right
    rr    l                       ;; [2] Rotate L right through carry
    srl   h                       ;; [2] Shift H right second time
    rr    l                       ;; [2] Rotate L right second time (HL = HL / 4)
.endm

;; COLOR_PEN_FROM_B: color_pen = B * 4 (Pre-multiplied offset for color table)
;;   Execution time: 7 us / 28 CPU cycles
;;   Size: 6 bytes
.macro COLOR_PEN_FROM_B
    ld    a, b                    ;; [1] A = color index (0-3)
    add   a, a                    ;; [1] A = color * 2
    add   a, a                    ;; [1] A = color * 4
    ld    (color_pen), a          ;; [4] Store pre-multiplied color index into RAM
.endm

;;-------------------------------------------------------------------------------
;; DATA SECTION
;;-------------------------------------------------------------------------------
.area _DATA
rb_off_start:   .db 0          ;; Start pixel offset (0..3)
rb_off_end:     .db 0          ;; End pixel offset (0..3)
rb_byte_start:  .db 0          ;; Start byte column (0..79)
rb_byte_end:    .db 0          ;; End byte column (0..79)
rb_mid_count:   .db 0          ;; Number of full intermediate bytes
screen_start:   .ds 2          ;; Base VRAM address (16-bit)
screen_ptr_val: .dw 0          ;; Initial computed VRAM pointer (16-bit)
color_pen:      .db 0          ;; Pre-multiplied color index (color * 4)
y0_val:         .db 0          ;; Current Y coordinate (RAM storage)
x0_val:         .dw 0          ;; Current X0 coordinate (RAM storage)
abs_dx:         .dw 0          ;; Absolute DX distance (16-bit)
abs_dy:         .dw 0          ;; Absolute DY distance (16-bit)
sy_is_up:       .db 0          ;; SY direction flag (0 = Down, 1 = Up)
cur_mask:       .db 0          ;; Current Mode 1 pixel mask
cur_col:        .db 0          ;; Current Mode 1 pixel color byte

;;-------------------------------------------------------------------------------
;; CODE SECTION
;;-------------------------------------------------------------------------------
.area _CODE
jp    normal_draw             ;; [3] Jump to main entry and dispatch

;; ============================================================================
;; SINGLE POINT FAST-PATH (DX = 0, DY = 0)
;; ============================================================================
single_draw:
    COLOR_PEN_FROM_B              ;; [7] Calculate pre-multiplied color index
    ld    hl, (x0_val)            ;; [5] HL = X0 coordinate
    ld    a, l                    ;; [1] A = X0 low byte
    and   #3                      ;; [2] A = pixel offset (0..3)
    push  af                      ;; [4] Save pixel offset on stack
    DIV4_HL                       ;; [8] Convert X coordinate to byte column
    ld    c, l                    ;; [1] C = byte column
    ld    a, (y0_val)             ;; [4] A = Y0 coordinate
    ld    b, a                    ;; [1] B = Y0 coordinate
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] Call VRAM pointer helper
    pop   af                      ;; [3] Restore pixel offset into A
    ld    c, a                    ;; [1] C = pixel offset for h_plot_one
    call  h_plot_one              ;; [5] Plot pixel using unified helper
    jp    end_draw_line           ;; [3] Jump to binding end

;; ============================================================================
;; HORIZONTAL LINE FAST-PATH (DY = 0)
;; ============================================================================
horizontal_draw:
    COLOR_PEN_FROM_B              ;; [7] Calculate pre-multiplied color index
    push  hl                      ;; [4] Preserve HL = signed DX
    ld    a, (color_pen)          ;; [4] A = color * 4
    ld    c, a                    ;; [1] C = color * 4
    ld    h, #0                   ;; [2] Clear H
    ld    l, c                    ;; [1] HL = color * 4
    ld    de, #cpct_plotColorTable_M1 ;; [3] DE = color table base address
    add   hl, de                  ;; [3] HL = &color_table[color * 4]
    ld    a, (hl)                 ;; [2] Load pixel 0 byte pattern
    inc   hl                      ;; [2] Next pixel byte
    or    (hl)                    ;; [2] Merge pixel 1 byte pattern
    inc   hl                      ;; [2] Next pixel byte
    or    (hl)                    ;; [2] Merge pixel 2 byte pattern
    inc   hl                      ;; [2] Next pixel byte
    or    (hl)                    ;; [2] Merge pixel 3 byte pattern -> A = solid pattern
    ld    (solid_op + 1), a       ;; [4] Store solid byte pattern into SMC
    pop   hl                      ;; [3] Restore HL = signed DX
    ld    de, (x0_val)            ;; [5] DE = X0 coordinate
    add   hl, de                  ;; [3] HL = X1 = X0 + DX
    push  hl                      ;; [4] Save X1 on stack
    push  de                      ;; [4] Save X0 on stack
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] Compare X1 and X0
    jr    c, h_swap               ;; [2/3] IF X1 < X0 THEN swap start and end
    pop   hl                      ;; [3] HL = start_x = min(X0, X1)
    pop   de                      ;; [3] DE = end_x = max(X0, X1)
    jr    h_have                  ;; [3] Jump to start processing
h_swap:
    pop   de                      ;; [3] DE = end_x = max(X0, X1)
    pop   hl                      ;; [3] HL = start_x = min(X0, X1)
h_have:
    ld    a, l                    ;; [1] A = start_x low byte
    and   #3                      ;; [2] A = start pixel offset (0..3)
    ld    (rb_off_start), a       ;; [4] Store start offset
    DIV4_HL                       ;; [8] Convert start_x to byte column
    ld    a, l                    ;; [1] A = start byte column
    ld    (rb_byte_start), a      ;; [4] Store start byte column
    ld    a, e                    ;; [1] A = end_x low byte
    and   #3                      ;; [2] A = end pixel offset (0..3)
    ld    (rb_off_end), a         ;; [4] Store end offset
    ex    de, hl                  ;; [1] HL = end_x, E = start byte column
    ld    d, e                    ;; [1] D = start byte column
    DIV4_HL                       ;; [8] Convert end_x to byte column
    ld    a, l                    ;; [1] A = end byte column
    ld    (rb_byte_end), a        ;; [4] Store end byte column
    ld    e, a                    ;; [1] E = end byte column
    ld    a, e                    ;; [1] A = end byte column
    sub   d                       ;; [1] A = end_byte - start_byte
    dec   a                       ;; [1] A = middle byte count
    ld    (rb_mid_count), a       ;; [4] Store middle count
    ld    c, d                    ;; [1] C = start byte column
    ld    a, (y0_val)             ;; [4] A = Y0 coordinate
    ld    b, a                    ;; [1] B = Y0 coordinate
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] Call VRAM starting byte address helper
    ld    a, (rb_byte_start)      ;; [4] A = start byte column
    ld    c, a                    ;; [1] C = start byte column
    ld    a, (rb_byte_end)        ;; [4] A = end byte column
    cp    c                       ;; [1] Compare start_byte and end_byte
    jp    nz, h_multi             ;; [3] IF start_byte != end_byte THEN multi-byte

    ;; --- MONO-BYTE CASE: pixels [off_start .. off_end] ---
    ld    a, (rb_off_start)       ;; [4] A = start pixel offset
    ld    c, a                    ;; [1] C = current pixel offset
h_single_loop:
    call  h_plot_one              ;; [5] Plot pixel in single byte
    ld    a, (rb_off_end)         ;; [4] A = end pixel offset
    cp    c                       ;; [1] Compare with current offset
    jp    z, end_draw_line        ;; [3] IF finished THEN jump end
    inc   c                       ;; [1] Move to next pixel offset
    jr    h_single_loop           ;; [3] Loop next pixel
h_multi:
    ;; --- START BYTE: pixels [off_start .. 3] ---
    ld    a, (rb_off_start)       ;; [4] A = start pixel offset
    ld    c, a                    ;; [1] C = current pixel offset
h_start_loop:
    call  h_plot_one              ;; [5] Plot pixel in start byte
    inc   c                       ;; [1] Move to next pixel offset
    ld    a, c                    ;; [1] A = current pixel offset
    cp    #4                      ;; [2] Check byte boundary (4 pixels/byte)
    jr    nz, h_start_loop        ;; [2/3] IF not byte boundary THEN loop
    inc   hl                      ;; [2] Move to first middle byte column
solid_op:
    ld    d, #0x00                ;; [2] SMC patched solid color byte
    ;; --- MIDDLE BYTES: Fast solid fill loop ---
    ld    a, (rb_mid_count)       ;; [4] A = middle bytes count
    or    a                       ;; [1] Check if 0
    jr    z, h_no_mid             ;; [2/3] IF 0 middle bytes THEN skip loop
    ld    b, a                    ;; [1] B = middle bytes counter
h_mid_loop:
    ld    (hl), d                 ;; [2] Write solid color byte directly to VRAM
    inc   hl                      ;; [2] Move to next byte column
    djnz  h_mid_loop              ;; [3/4] Loop until middle bytes filled
h_no_mid:
    ;; --- END BYTE: pixels [0 .. off_end] ---
    ld    c, #0                   ;; [2] C = 0 (start offset for final byte)
h_end_loop:
    call  h_plot_one              ;; [5] Plot pixel in end byte
    ld    a, (rb_off_end)         ;; [4] A = end pixel offset
    cp    c                       ;; [1] Compare with current offset
    jp    z, end_draw_line        ;; [3] IF finished THEN jump end
    inc   c                       ;; [1] Move to next pixel offset
    jr    h_end_loop              ;; [3] Loop next pixel

;; ============================================================================
;; VERTICAL LINE FAST-PATH (DX = 0)
;; ============================================================================
vertical_draw:
    cp    c                       ;; [1] Compare Y0 and Y1
    jr    c, v_order_ok           ;; [2/3] IF Y0 < Y1 THEN ordered
    jp    z, single_draw          ;; [3] IF Y0 == Y1 THEN single point
    ld    e, a                    ;; [1] Swap Y0 and Y1
    ld    a, c                    ;; [1] |
    ld    c, e                    ;; [1] |
v_order_ok:
    ld    (v_ystart_op + 1), a    ;; [4] Store Y_start into SMC
    sub   c                       ;; [1] A = Y_start - Y_end
    neg                           ;; [2] A = Y_end - Y_start
    inc   a                       ;; [1] A = height in pixels
    ld    (v_count_op + 1), a     ;; [4] Store loop count into SMC
    COLOR_PEN_FROM_B              ;; [7] Calculate pre-multiplied color index
    ld    hl, (x0_val)            ;; [5] HL = X coordinate
    ld    a, l                    ;; [1] A = X low byte
    and   #3                      ;; [2] A = pixel_index (0..3)
    ld    e, a                    ;; [1] E = pixel_index
    ld    d, #0                   ;; [2] D = 0
    ld    hl, #cpct_plotMasksTable_M1 ;; [3] HL = masks table base
    add   hl, de                  ;; [3] HL = &masks[pixel_index]
    ld    a, (hl)                 ;; [2] A = mask byte
    ld    (v_mask_op + 1), a      ;; [4] Patch SMC mask byte
    ld    a, (color_pen)          ;; [4] A = color * 4
    or    e                       ;; [1] A = color * 4 + pixel_index
    ld    e, a                    ;; [1] E = combined offset
    ld    hl, #cpct_plotColorTable_M1 ;; [3] HL = color table base
    add   hl, de                  ;; [3] HL = &color[offset]
    ld    a, (hl)                 ;; [2] A = color byte
    ld    (v_col_op + 1), a       ;; [4] Patch SMC color byte
    ld    hl, (x0_val)            ;; [5] HL = X coordinate
    DIV4_HL                       ;; [8] Convert X coordinate to byte column
    ld    c, l                    ;; [1] C = X_byte
v_ystart_op:
    ld    b, #0x00                ;; [2] B = Y_start (SMC patched)
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM start address
    ld    de, #0x0800             ;; [3] DE = intra-block scanline step (+0x0800)
v_count_op:
    ld    b, #0x00                ;; [2] B = pixel count (SMC patched)
v_loop:
    ld    a, (hl)                 ;; [2] Single VRAM Read
v_mask_op:
    and   #0x00                   ;; [2] Apply background mask (SMC patched)
v_col_op:
    or    #0x00                   ;; [2] Inject foreground color (SMC patched)
    ld    (hl), a                 ;; [2] Single VRAM Write
    add   hl, de                  ;; [3] Move HL to next scanline (+0x0800)
    ld    a, h                    ;; [1] Check 8-line block boundary
    and   #0x38                   ;; [2] |
    jr    nz, v_step_ok           ;; [2/3] IF inside block THEN skip correction
    push  bc                      ;; [4] Preserve B (loop counter)
    ld    bc, #0xC050             ;; [3] Boundary correction offset (+0xC050)
    add   hl, bc                  ;; [3] Move HL to next character row
    pop   bc                      ;; [3] Restore B (loop counter)
v_step_ok:
    djnz  v_loop                  ;; [3/4] Loop until all vertical pixels drawn
    jp    end_draw_line           ;; [3] Finish vertical drawing

;; ----------------------------------------------------------------------------
;; Helper Routine: h_plot_one
;; ----------------------------------------------------------------------------
h_plot_one:
    push  hl                      ;; [4] Preserve VRAM address
    ld    h, #0                   ;; [2] Clear H for 16-bit offset calculation
    ld    l, c                    ;; [1] L = pixel index
    ld    de, #cpct_plotMasksTable_M1 ;; [3] DE = masks table base
    add   hl, de                  ;; [3] HL = &masks[pixel_index]
    ld    b, (hl)                 ;; [2] B = background mask
    ld    a, (color_pen)          ;; [4] A = color * 4
    or    c                       ;; [1] A = color * 4 + pixel_index
    ld    l, a                    ;; [1] L = color offset
    ld    h, #0                   ;; [2] Clear H
    ld    de, #cpct_plotColorTable_M1 ;; [3] DE = color table base
    add   hl, de                  ;; [3] HL = &color[combined_offset]
    ld    d, (hl)                 ;; [2] D = pixel color byte
    pop   hl                      ;; [3] Restore VRAM address
    ld    a, (hl)                 ;; [2] Read current VRAM byte
    and   b                       ;; [1] Clear target pixel, preserve background
    or    d                       ;; [1] Inject pixel color
    ld    (hl), a                 ;; [2] Write byte to VRAM
    ret                           ;; [3] Return

;; ============================================================================
;; MAIN ENTRY POINT & DISPATCHER
;; ============================================================================
normal_draw:
    ld    (screen_start), hl      ;; [5] Store base VRAM address into RAM
    ex    de, hl                  ;; [1] HL = X0 coordinate, DE = base VRAM address
    ld    (x0_val), hl            ;; [5] Save X0 coordinate into RAM
    pop   de                      ;; [3] DE = Y0 coordinate
    ld    a, e                    ;; [1] A = Y0 coordinate
    ld    (y0_val), a             ;; [4] Store initial Y0 into RAM
    ex    de, hl                  ;; [1] DE = X0, HL = Y0
    pop   hl                      ;; [3] HL = X1 coordinate
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = signed DX = X1 - X0
    ld    e, a                    ;; [1] E = Y0
    pop   bc                      ;; [3] B = color, C = Y1
    jr    nz, check_dy            ;; [2/3] IF DX != 0 THEN jump check_dy

    ;; ---- DX == 0 case ----
    sub   c                       ;; [1] A = Y0 - Y1
    jp    z, single_draw          ;; [3] IF Y0 == Y1 THEN single point
    ld    a, e                    ;; [1] Restore A = Y0
    jp    vertical_draw           ;; [3] DX == 0 and DY != 0 -> vertical_draw

check_dy:
    ;; ---- DX != 0 case ----
    sub   c                       ;; [1] A = Y0 - Y1
    jp    z, horizontal_draw      ;; [3] DY == 0 and DX != 0 -> horizontal_draw
    COLOR_PEN_FROM_B              ;; [7] Calculate pre-multiplied color index

    ;; ---- Configure X-Step (SX) in all loops via SMC ----
    ld    a, #0x08                ;; [2] Opcode 'rrc b' (SX = +1)
    ld    (gd_x_rot_m + 1), a     ;; [4] Store into Gentle Down loop
    ld    (gu_x_rot_m + 1), a     ;; [4] Store into Gentle Up loop
    ld    (sd_x_rot_m + 1), a     ;; [4] Store into Steep Down loop
    ld    (su_x_rot_m + 1), a     ;; [4] Store into Steep Up loop

    ld    a, #0x09                ;; [2] Opcode 'rrc c' (SX = +1)
    ld    (gd_x_rot_c + 1), a     ;; [4] Store into Gentle Down loop
    ld    (gu_x_rot_c + 1), a     ;; [4] Store into Gentle Up loop
    ld    (sd_x_rot_c + 1), a     ;; [4] Store into Steep Down loop
    ld    (su_x_rot_c + 1), a     ;; [4] Store into Steep Up loop

    ld    a, #0x01                ;; [2] Opcode 'rlc c' (for 3-rotations wrap alignment)
    ld    (gd_x_col_align1 + 1), a;; [4] Patch alignment rotation 1
    ld    (gd_x_col_align2 + 1), a;; [4] Patch alignment rotation 2
    ld    (gd_x_col_align3 + 1), a;; [4] Patch alignment rotation 3
    ld    (gu_x_col_align1 + 1), a;; [4]
    ld    (gu_x_col_align2 + 1), a;; [4]
    ld    (gu_x_col_align3 + 1), a;; [4]
    ld    (sd_x_col_align1 + 1), a;; [4]
    ld    (sd_x_col_align2 + 1), a;; [4]
    ld    (sd_x_col_align3 + 1), a;; [4]
    ld    (su_x_col_align1 + 1), a;; [4]
    ld    (su_x_col_align2 + 1), a;; [4]
    ld    (su_x_col_align3 + 1), a;; [4]

    ld    a, #0x13                ;; [2] Opcode 'inc de' (SX = +1)
    ld    (gd_x_ptr_step), a      ;; [4]
    ld    (gu_x_ptr_step), a      ;; [4]
    ld    (sd_x_ptr_step), a      ;; [4]
    ld    (su_x_ptr_step), a      ;; [4]

    bit   7, h                    ;; [2] Check sign of DX
    jr    z, dx_abs_ready         ;; [2/3] IF DX >= 0 THEN jump dx_abs_ready

    ;; SX = -1 (left):
    ld    a, #0x00                ;; [2] Opcode 'rlc b' (SX = -1)
    ld    (gd_x_rot_m + 1), a     ;; [4] Store into Gentle Down loop
    ld    (gu_x_rot_m + 1), a     ;; [4] Store into Gentle Up loop
    ld    (sd_x_rot_m + 1), a     ;; [4] Store into Steep Down loop
    ld    (su_x_rot_m + 1), a     ;; [4] Store into Steep Up loop

    ld    a, #0x01                ;; [2] Opcode 'rlc c' (SX = -1)
    ld    (gd_x_rot_c + 1), a     ;; [4] Store into Gentle Down loop
    ld    (gu_x_rot_c + 1), a     ;; [4] Store into Gentle Up loop
    ld    (sd_x_rot_c + 1), a     ;; [4] Store into Steep Down loop
    ld    (su_x_rot_c + 1), a     ;; [4] Store into Steep Up loop

    ld    a, #0x09                ;; [2] Opcode 'rrc c' (for 3-rotations wrap alignment)
    ld    (gd_x_col_align1 + 1), a;; [4] Patch alignment rotation 1
    ld    (gd_x_col_align2 + 1), a;; [4] Patch alignment rotation 2
    ld    (gd_x_col_align3 + 1), a;; [4] Patch alignment rotation 3
    ld    (gu_x_col_align1 + 1), a;; [4]
    ld    (gu_x_col_align2 + 1), a;; [4]
    ld    (gu_x_col_align3 + 1), a;; [4]
    ld    (sd_x_col_align1 + 1), a;; [4]
    ld    (sd_x_col_align2 + 1), a;; [4]
    ld    (sd_x_col_align3 + 1), a;; [4]
    ld    (su_x_col_align1 + 1), a;; [4]
    ld    (su_x_col_align2 + 1), a;; [4]
    ld    (su_x_col_align3 + 1), a;; [4]

    ld    a, #0x1B                ;; [2] Opcode 'dec de' (SX = -1)
    ld    (gd_x_ptr_step), a      ;; [4]
    ld    (gu_x_ptr_step), a      ;; [4]
    ld    (sd_x_ptr_step), a      ;; [4]
    ld    (su_x_ptr_step), a      ;; [4]

    xor   a                       ;; [1] Clear A
    sub   l                       ;; [1] HL = -DX
    ld    l, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   h                       ;; [1] |
    ld    h, a                    ;; [1] HL = |DX|

dx_abs_ready:
    ld    (abs_dx), hl            ;; [5] Store absolute DX into RAM

    ;; ---- Configure Y-Step (SY) Direction ----
    ld    a, c                    ;; [1] A = Y1
    sub   e                       ;; [1] A = Y1 - Y0
    jr    nc, sy_pos              ;; [2/3] IF Y1 >= Y0 THEN jump sy_pos
    neg                           ;; [2] A = |DY|
    ld    c, a                    ;; [1] C = |DY|
    ld    a, #1                   ;; [2] A = 1 (Up)
    ld    (sy_is_up), a           ;; [4] Flag Up = 1
    jr    dy_abs_ready            ;; [3] Jump dy_abs_ready

sy_pos:
    ld    c, a                    ;; [1] C = |DY|
    xor   a                       ;; [1] A = 0 (Down)
    ld    (sy_is_up), a           ;; [4] Flag Up = 0

dy_abs_ready:
    ld    b, #0                   ;; [2] BC = absolute DY (16-bit)
    ld    (abs_dy), bc            ;; [6] Store absolute DY into RAM

    ;; -------------------------------------------------------------
    ;; Compute Initial Screen Pointer & Mode 1 Pixel Mask/Color
    ;; -------------------------------------------------------------
    ld    hl, (x0_val)            ;; [5] HL = X0 coordinate
    push  hl                      ;; [4] Save X0 on stack
    DIV4_HL                       ;; [8] Convert X0 to byte column
    ld    c, l                    ;; [1] C = X_byte
    ld    a, (y0_val)             ;; [4] A = Y0
    ld    b, a                    ;; [1] B = Y0
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM address
    ld    (screen_ptr_val), hl    ;; [5] Store computed initial VRAM pointer
    pop   hl                      ;; [3] Restore X0

    ld    a, l                    ;; [1] A = X0 low byte
    and   #3                      ;; [2] A = pixel offset (0..3)
    ld    c, a                    ;; [1] C = pixel offset
    ld    hl, #cpct_plotMasksTable_M1 ;; [3] HL = masks table base
    ld    b, #0                   ;; [2] B = 0
    add   hl, bc                  ;; [3] HL = &masks[pixel_offset]
    ld    a, (hl)                 ;; [2] A = initial background mask
    ld    (cur_mask), a           ;; [4] Store initial mask

    ld    a, (color_pen)          ;; [4] A = color * 4
    add   a, c                    ;; [1] A = color * 4 + pixel_offset
    ld    c, a                    ;; [1] C = combined offset
    ld    hl, #cpct_plotColorTable_M1 ;; [3] HL = color table base
    ld    b, #0                   ;; [2] B = 0
    add   hl, bc                  ;; [3] HL = &color[combined_offset]
    ld    a, (hl)                 ;; [2] A = initial color byte
    ld    (cur_col), a            ;; [4] Store initial color byte

    ;; -------------------------------------------------------------
    ;; Clean 4-Way Dispatcher : Gentle/Steep x Down/Up
    ;; -------------------------------------------------------------
    ld    hl, (abs_dx)            ;; [5] HL = |DX|
    ld    bc, (abs_dy)            ;; [6] BC = |DY|
    or    a                       ;; [1] Clear carry flag
    sbc   hl, bc                  ;; [3] Compare |DX| and |DY|
    jp    c, is_steep_slope       ;; [3] IF |DX| < |DY| THEN Steep path

is_gentle_slope:
    ld    a, (sy_is_up)           ;; [4] A = SY direction flag
    or    a                       ;; [1] Check if Up
    jp    nz, setup_gentle_up_slope   ;; [3] IF Up THEN Gentle Up
    jp    setup_gentle_down_slope     ;; [3] IF Down THEN Gentle Down

is_steep_slope:
    ld    a, (sy_is_up)           ;; [4] A = SY direction flag
    or    a                       ;; [1] Check if Up
    jp    nz, setup_steep_up_slope    ;; [3] IF Up THEN Steep Up
    jp    setup_steep_down_slope      ;; [3] IF Down THEN Steep Down

;; ============================================================================
;; GENTLE DOWN (DX >= DY, SY = +1)
;; ============================================================================
setup_gentle_down_slope:
    ld    hl, (abs_dy)            ;; [5] HL = DY
    add   hl, hl                  ;; [3] HL = 2 * DY
    ld    a, l                    ;; [1] A = low byte of 2*DY
    ld    (gd_delta_nostep_lo), a ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of 2*DY
    ld    (gd_delta_nostep_hi), a ;; [4] Patch high byte into SMC

    ld    de, (abs_dx)            ;; [5] DE = DX
    ex    de, hl                  ;; [1] HL = DX, DE = 2*DY
    add   hl, hl                  ;; [3] HL = 2 * DX
    ex    de, hl                  ;; [1] HL = 2*DY, DE = 2*DX
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = 2*(DY - DX)
    ld    a, l                    ;; [1] A = low byte of delta_step
    ld    (gd_delta_step_lo), a   ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of delta_step
    ld    (gd_delta_step_hi), a   ;; [4] Patch high byte into SMC

    ld    hl, (abs_dy)            ;; [5] HL = DY
    add   hl, hl                  ;; [3] HL = 2 * DY
    ld    de, (abs_dx)            ;; [5] DE = DX
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = Err0 = 2*DY - DX

    ld    ix, (abs_dx)            ;; [6] IX = DX
    inc   ix                      ;; [3] IX = DX + 1 (total pixel count 16-bit)

    ld    de, (screen_ptr_val)    ;; [5] DE = initial VRAM pointer
    ld    a, (cur_mask)           ;; [4] A = initial background mask
    ld    b, a                    ;; [1] B = initial mask
    ld    a, (cur_col)            ;; [4] A = initial color byte
    ld    c, a                    ;; [1] C = initial color

gentle_down_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    and   b                       ;; [1] Apply background mask
    or    c                       ;; [1] Inject foreground color
    ld    (de), a                 ;; [2] Write updated byte back to VRAM

    ;; --- Step X with Fast Fall-Through ---
gd_x_rot_m:
    .db   #0xCB, #0x08            ;; [2] SMC: 'rrc b' / 'rlc b'
    jr    c, gd_x_nowrap          ;; [2/3] IF Carry=1 (75% no wrap) THEN jump gd_x_nowrap
gd_x_ptr_step:
    inc   de                      ;; [2] 25% wrap: Move DE to next byte column
gd_x_col_align1:
    .db   #0xCB, #0x01            ;; [2] Realign color byte (3x rlc c / rrc c)
gd_x_col_align2:
    .db   #0xCB, #0x01            ;; [2] |
gd_x_col_align3:
    .db   #0xCB, #0x01            ;; [2] |
    jr    gd_x_step_done          ;; [3] Jump to error evaluation
gd_x_nowrap:
gd_x_rot_c:
    .db   #0xCB, #0x09            ;; [2] SMC: 'rrc c' / 'rlc c'
gd_x_step_done:

    ;; --- Error Check ---
    bit   7, h                    ;; [2] Test if Err < 0
    jr    z, gd_yes_y_step        ;; [2/3] IF Err >= 0 THEN jump gd_yes_y_step

    ;; --- Fast-Path: No Y Step (Err < 0) ---
gd_delta_nostep_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*DY (SMC patched)
    add   a, l                    ;; [1] L += low(2*DY)
    ld    l, a                    ;; [1] |
gd_delta_nostep_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*DY (SMC patched)
    adc   a, h                    ;; [1] H += high(2*DY) + carry
    ld    h, a                    ;; [1] |
    jr    gd_dec_count            ;; [3] Jump to loop decrement

gd_yes_y_step:
    ;; --- Inlined Scanline Step Down ---
    ld    a, d                    ;; [1] A = high byte of VRAM address
    add   a, #0x08                ;; [2] Advance 1 scanline (+0x0800)
    ld    d, a                    ;; [1] D = updated high byte
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, gd_y_d_ok           ;; [2/3] IF inside block THEN skip correction
    ld    a, e                    ;; [1] A = low byte of VRAM address
    add   a, #0x50                ;; [2] E += 0x50 (with carry)
    ld    e, a                    ;; [1] E = updated low byte
    ld    a, d                    ;; [1] A = high byte
    adc   a, #0xC0                ;; [2] D += 0xC0 + carry
    ld    d, a                    ;; [1] D = updated high byte
gd_y_d_ok:

gd_delta_step_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*(DY - DX) (SMC patched)
    add   a, l                    ;; [1] L += low(delta_step)
    ld    l, a                    ;; [1] |
gd_delta_step_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*(DY - DX) (SMC patched)
    adc   a, h                    ;; [1] H += high(delta_step) + carry
    ld    h, a                    ;; [1] |

gd_dec_count:
    ;; --- 16-bit Loop Counter in IX (No Alternate Registers Used) ---
    dec   ix                      ;; [3] Decrement 16-bit counter IX
    ld__a_ixh                     ;; [2] A = high byte of IX
    or__ixl                       ;; [2] A = IXH | IXL (Zero flag set if IX == 0)
    jp    nz, gentle_down_loop    ;; [3] IF IX != 0 THEN loop next pixel
    jp    end_draw_line           ;; [3] Line completed

;; ============================================================================
;; GENTLE UP (DX >= DY, SY = -1)
;; ============================================================================
setup_gentle_up_slope:
    ld    hl, (abs_dy)            ;; [5] HL = DY
    add   hl, hl                  ;; [3] HL = 2 * DY
    ld    a, l                    ;; [1] A = low byte of 2*DY
    ld    (gu_delta_nostep_lo), a ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of 2*DY
    ld    (gu_delta_nostep_hi), a ;; [4] Patch high byte into SMC

    ld    de, (abs_dx)            ;; [5] DE = DX
    ex    de, hl                  ;; [1] HL = DX, DE = 2*DY
    add   hl, hl                  ;; [3] HL = 2 * DX
    ex    de, hl                  ;; [1] HL = 2*DY, DE = 2*DX
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = 2*(DY - DX)
    ld    a, l                    ;; [1] A = low byte of delta_step
    ld    (gu_delta_step_lo), a   ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of delta_step
    ld    (gu_delta_step_hi), a   ;; [4] Patch high byte into SMC

    ld    hl, (abs_dy)            ;; [5] HL = DY
    add   hl, hl                  ;; [3] HL = 2 * DY
    ld    de, (abs_dx)            ;; [5] DE = DX
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = Err0 = 2*DY - DX

    ld    ix, (abs_dx)            ;; [6] IX = DX
    inc   ix                      ;; [3] IX = DX + 1 (total pixel count 16-bit)

    ld    de, (screen_ptr_val)    ;; [5] DE = initial VRAM pointer
    ld    a, (cur_mask)           ;; [4] A = initial background mask
    ld    b, a                    ;; [1] B = initial mask
    ld    a, (cur_col)            ;; [4] A = initial color byte
    ld    c, a                    ;; [1] C = initial color

gentle_up_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    and   b                       ;; [1] Apply background mask
    or    c                       ;; [1] Inject foreground color
    ld    (de), a                 ;; [2] Write updated byte back to VRAM

    ;; --- Step X with Fast Fall-Through ---
gu_x_rot_m:
    .db   #0xCB, #0x08            ;; [2] SMC: 'rrc b' / 'rlc b'
    jr    c, gu_x_nowrap          ;; [2/3] IF Carry=1 (75% no wrap) THEN jump gu_x_nowrap
gu_x_ptr_step:
    inc   de                      ;; [2] 25% wrap: Move DE to next byte column
gu_x_col_align1:
    .db   #0xCB, #0x01            ;; [2] Realign color byte (3x rlc c / rrc c)
gu_x_col_align2:
    .db   #0xCB, #0x01            ;; [2] |
gu_x_col_align3:
    .db   #0xCB, #0x01            ;; [2] |
    jr    gu_x_step_done          ;; [3] Jump to error evaluation
gu_x_nowrap:
gu_x_rot_c:
    .db   #0xCB, #0x09            ;; [2] SMC: 'rrc c' / 'rlc c'
gu_x_step_done:

    bit   7, h                    ;; [2] Test if Err < 0
    jr    z, gu_yes_y_step        ;; [2/3] IF Err >= 0 THEN jump gu_yes_y_step

    ;; --- Fast-Path: No Y Step (Err < 0) ---
gu_delta_nostep_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*DY (SMC patched)
    add   a, l                    ;; [1] L += low(2*DY)
    ld    l, a                    ;; [1] |
gu_delta_nostep_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*DY (SMC patched)
    adc   a, h                    ;; [1] H += high(2*DY) + carry
    ld    h, a                    ;; [1] |
    jr    gu_dec_count            ;; [3] Jump to loop decrement

gu_yes_y_step:
    ;; --- Inlined Scanline Step Up ---
    ld    a, d                    ;; [1] A = high byte of VRAM address
    and   #0x38                   ;; [2] Check if line 0 of character row
    jr    z, gu_y_u_row           ;; [2/3] IF line 0 THEN jump gu_y_u_row
    ld    a, d                    ;; [1] A = high byte
    sub   #0x08                   ;; [2] Move 1 scanline up (-0x0800)
    ld    d, a                    ;; [1] D = updated high byte
    jr    gu_y_ok                 ;; [3] Skip row correction
gu_y_u_row:
    ld    a, e                    ;; [1] A = low byte of VRAM address
    add   a, #0xB0                ;; [2] E += 0xB0 (with carry)
    ld    e, a                    ;; [1] E = updated low byte
    ld    a, d                    ;; [1] A = high byte
    adc   a, #0x37                ;; [2] D += 0x37 + carry
    ld    d, a                    ;; [1] D = updated high byte
gu_y_ok:

gu_delta_step_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*(DY - DX) (SMC patched)
    add   a, l                    ;; [1] L += low(delta_step)
    ld    l, a                    ;; [1] |
gu_delta_step_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*(DY - DX) (SMC patched)
    adc   a, h                    ;; [1] H += high(delta_step) + carry
    ld    h, a                    ;; [1] |

gu_dec_count:
    ;; --- 16-bit Loop Counter in IX ---
    dec   ix                      ;; [3] Decrement 16-bit counter IX
    ld__a_ixh                     ;; [2] A = high byte of IX
    or__ixl                       ;; [2] A = IXH | IXL (Zero flag set if IX == 0)
    jp    nz, gentle_up_loop      ;; [3] IF IX != 0 THEN loop next pixel
    jp    end_draw_line           ;; [3] Line completed

;; ============================================================================
;; STEEP DOWN (DY > DX, SY = +1)
;; ============================================================================
setup_steep_down_slope:
    ld    hl, (abs_dx)            ;; [5] HL = DX
    add   hl, hl                  ;; [3] HL = 2 * DX
    ld    a, l                    ;; [1] A = low byte of 2*DX
    ld    (sd_delta_nostep_lo), a ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of 2*DX
    ld    (sd_delta_nostep_hi), a ;; [4] Patch high byte into SMC

    ld    de, (abs_dy)            ;; [5] DE = DY
    ex    de, hl                  ;; [1] HL = DY, DE = 2*DX
    add   hl, hl                  ;; [3] HL = 2 * DY
    ex    de, hl                  ;; [1] HL = 2*DX, DE = 2*DY
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = 2*(DX - DY)
    ld    a, l                    ;; [1] A = low byte of delta_step
    ld    (sd_delta_step_lo), a   ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of delta_step
    ld    (sd_delta_step_hi), a   ;; [4] Patch high byte into SMC

    ld    hl, (abs_dx)            ;; [5] HL = DX
    add   hl, hl                  ;; [3] HL = 2 * DX
    ld    de, (abs_dy)            ;; [5] DE = DY
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = Err0 = 2*DX - DY

    ld    ix, (abs_dy)            ;; [6] IX = DY
    inc   ix                      ;; [3] IX = DY + 1 (total pixel count 16-bit)

    ld    de, (screen_ptr_val)    ;; [5] DE = initial VRAM pointer
    ld    a, (cur_mask)           ;; [4] A = initial background mask
    ld    b, a                    ;; [1] B = initial mask
    ld    a, (cur_col)            ;; [4] A = initial color byte
    ld    c, a                    ;; [1] C = initial color

steep_down_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    and   b                       ;; [1] Apply background mask
    or    c                       ;; [1] Inject foreground color
    ld    (de), a                 ;; [2] Write updated byte back to VRAM

    ;; --- Inlined Scanline Step Down (Always) ---
    ld    a, d                    ;; [1] A = high byte of VRAM address
    add   a, #0x08                ;; [2] Move down 1 scanline (+0x0800)
    ld    d, a                    ;; [1] D = updated high byte
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, sd_y_d_ok           ;; [2/3] IF inside block THEN skip correction
    ld    a, e                    ;; [1] A = low byte of VRAM address
    add   a, #0x50                ;; [2] E += 0x50 (with carry)
    ld    e, a                    ;; [1] E = updated low byte
    ld    a, d                    ;; [1] A = high byte
    adc   a, #0xC0                ;; [2] D += 0xC0 + carry
    ld    d, a                    ;; [1] D = updated high byte
sd_y_d_ok:

    bit   7, h                    ;; [2] Test if Err < 0
    jr    nz, sd_no_x_step        ;; [2/3] IF Err < 0 THEN skip X step

    ;; --- Step X with Fast Fall-Through ---
sd_x_rot_m:
    .db   #0xCB, #0x08            ;; [2] SMC: 'rrc b' / 'rlc b'
    jr    c, sd_x_nowrap          ;; [2/3] IF Carry=1 (75% no wrap) THEN jump sd_x_nowrap
sd_x_ptr_step:
    inc   de                      ;; [2] 25% wrap: Move DE to next byte column
sd_x_col_align1:
    .db   #0xCB, #0x01            ;; [2] Realign color byte (3x rlc c / rrc c)
sd_x_col_align2:
    .db   #0xCB, #0x01            ;; [2] |
sd_x_col_align3:
    .db   #0xCB, #0x01            ;; [2] |
    jr    sd_x_step_done          ;; [3] Jump to delta addition
sd_x_nowrap:
sd_x_rot_c:
    .db   #0xCB, #0x09            ;; [2] SMC: 'rrc c' / 'rlc c'
sd_x_step_done:

    ;; HL = HL + 2*(DX - DY)
sd_delta_step_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*(DX - DY) (SMC patched)
    add   a, l                    ;; [1] L += low(delta_step)
    ld    l, a                    ;; [1] |
sd_delta_step_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*(DX - DY) (SMC patched)
    adc   a, h                    ;; [1] H += high(delta_step) + carry
    ld    h, a                    ;; [1] |
    jr    sd_dec_count            ;; [3] Jump to loop decrement

sd_no_x_step:
    ;; HL = HL + 2*DX
sd_delta_nostep_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*DX (SMC patched)
    add   a, l                    ;; [1] L += low(2*DX)
    ld    l, a                    ;; [1] |
sd_delta_nostep_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*DX (SMC patched)
    adc   a, h                    ;; [1] H += high(2*DX) + carry
    ld    h, a                    ;; [1] |

sd_dec_count:
    ;; --- 16-bit Loop Counter in IX ---
    dec   ix                      ;; [3] Decrement 16-bit counter IX
    ld__a_ixh                     ;; [2] A = high byte of IX
    or__ixl                       ;; [2] A = IXH | IXL (Zero flag set if IX == 0)
    jp    nz, steep_down_loop     ;; [3] IF IX != 0 THEN loop next pixel
    jp    end_draw_line           ;; [3] Line completed

;; ============================================================================
;; STEEP UP (DY > DX, SY = -1)
;; ============================================================================
setup_steep_up_slope:
    ld    hl, (abs_dx)            ;; [5] HL = DX
    add   hl, hl                  ;; [3] HL = 2 * DX
    ld    a, l                    ;; [1] A = low byte of 2*DX
    ld    (su_delta_nostep_lo), a ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of 2*DX
    ld    (su_delta_nostep_hi), a ;; [4] Patch high byte into SMC

    ld    de, (abs_dy)            ;; [5] DE = DY
    ex    de, hl                  ;; [1] HL = DY, DE = 2*DX
    add   hl, hl                  ;; [3] HL = 2 * DY
    ex    de, hl                  ;; [1] HL = 2*DX, DE = 2*DY
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = 2*(DX - DY)
    ld    a, l                    ;; [1] A = low byte of delta_step
    ld    (su_delta_step_lo), a   ;; [4] Patch low byte into SMC
    ld    a, h                    ;; [1] A = high byte of delta_step
    ld    (su_delta_step_hi), a   ;; [4] Patch high byte into SMC

    ld    hl, (abs_dx)            ;; [5] HL = DX
    add   hl, hl                  ;; [3] HL = 2 * DX
    ld    de, (abs_dy)            ;; [5] DE = DY
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] HL = Err0 = 2*DX - DY

    ld    ix, (abs_dy)            ;; [6] IX = DY
    inc   ix                      ;; [3] IX = DY + 1 (total pixel count 16-bit)

    ld    de, (screen_ptr_val)    ;; [5] DE = initial VRAM pointer
    ld    a, (cur_mask)           ;; [4] A = initial background mask
    ld    b, a                    ;; [1] B = initial mask
    ld    a, (cur_col)            ;; [4] A = initial color byte
    ld    c, a                    ;; [1] C = initial color

steep_up_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    and   b                       ;; [1] Apply background mask
    or    c                       ;; [1] Inject foreground color
    ld    (de), a                 ;; [2] Write updated byte back to VRAM

    ;; --- Inlined Scanline Step Up (Always) ---
    ld    a, d                    ;; [1] A = high byte of VRAM address
    and   #0x38                   ;; [2] Check if line 0 of character row
    jr    z, su_y_u_row           ;; [2/3] IF line 0 THEN jump su_y_u_row
    ld    a, d                    ;; [1] A = high byte
    sub   #0x08                   ;; [2] Move 1 scanline up (-0x0800)
    ld    d, a                    ;; [1] D = updated high byte
    jr    su_y_ok                 ;; [3] Skip row correction
su_y_u_row:
    ld    a, e                    ;; [1] A = low byte of VRAM address
    add   a, #0xB0                ;; [2] E += 0xB0 (with carry)
    ld    e, a                    ;; [1] E = updated low byte
    ld    a, d                    ;; [1] A = high byte
    adc   a, #0x37                ;; [2] D += 0x37 + carry
    ld    d, a                    ;; [1] D = updated high byte
su_y_ok:

    bit   7, h                    ;; [2] Test if Err < 0
    jr    nz, su_no_x_step        ;; [2/3] IF Err < 0 THEN skip X step

    ;; --- Step X with Fast Fall-Through ---
su_x_rot_m:
    .db   #0xCB, #0x08            ;; [2] SMC: 'rrc b' / 'rlc b'
    jr    c, su_x_nowrap          ;; [2/3] IF Carry=1 (75% no wrap) THEN jump su_x_nowrap
su_x_ptr_step:
    inc   de                      ;; [2] 25% wrap: Move DE to next byte column
su_x_col_align1:
    .db   #0xCB, #0x01            ;; [2] Realign color byte (3x rlc c / rrc c)
su_x_col_align2:
    .db   #0xCB, #0x01            ;; [2] |
su_x_col_align3:
    .db   #0xCB, #0x01            ;; [2] |
    jr    su_x_step_done          ;; [3] Jump to delta addition
su_x_nowrap:
su_x_rot_c:
    .db   #0xCB, #0x09            ;; [2] SMC: 'rrc c' / 'rlc c'
su_x_step_done:

    ;; HL = HL + 2*(DX - DY)
su_delta_step_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*(DX - DY) (SMC patched)
    add   a, l                    ;; [1] L += low(delta_step)
    ld    l, a                    ;; [1] |
su_delta_step_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*(DX - DY) (SMC patched)
    adc   a, h                    ;; [1] H += high(delta_step) + carry
    ld    h, a                    ;; [1] |
    jr    su_dec_count            ;; [3] Jump to loop decrement

su_no_x_step:
    ;; HL = HL + 2*DX
su_delta_nostep_lo = .+1
    ld    a, #0x00                ;; [2] Low byte of 2*DX (SMC patched)
    add   a, l                    ;; [1] L += low(2*DX)
    ld    l, a                    ;; [1] |
su_delta_nostep_hi = .+1
    ld    a, #0x00                ;; [2] High byte of 2*DX (SMC patched)
    adc   a, h                    ;; [1] H += high(2*DX) + carry
    ld    h, a                    ;; [1] |

su_dec_count:
    ;; --- 16-bit Loop Counter in IX ---
    dec   ix                      ;; [3] Decrement 16-bit counter IX
    ld__a_ixh                     ;; [2] A = high byte of IX
    or__ixl                       ;; [2] A = IXH | IXL (Zero flag set if IX == 0)
    jp    nz, steep_up_loop       ;; [3] IF IX != 0 THEN loop next pixel
    jp    end_draw_line           ;; [3] Line completed

;; ============================================================================
;; END OF ROUTINE (Falls through to restore_iy in binding wrapper .s)
;; ============================================================================
end_draw_line: