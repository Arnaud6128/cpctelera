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
;; Function: cpct_geometryLineM1_f
;;
;;    Draws a straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using Bresenham's line algorithm. Includes
;;    dedicated fast-path handlers for Single Point, Horizontal, and Vertical lines.
;;
;; C Definition:
;;    void cpct_geometryLineM1_f(void* screen_base, u16 x0, u16 y0, u16 x1, u8 y1, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B DE) screen_base - Base VRAM memory address
;;    (2B HL) x0          - Starting X coordinate (0-319)
;;    (Stack) y0          - Starting Y coordinate (0-199, 16-bit integer)
;;    (Stack) x1          - Ending X coordinate (0-319, 16-bit integer)
;;    (Stack) color / y1  - Color index (B: 0-3) and Ending Y coordinate (C: 0-199)
;;
;; Assembly call:
;;     > call cpct_geometryLineM1_f
;;
;; Fast-Path Special Cases:
;;    - Single Point  (DX = 0, DY = 0)  : Direct pixel plot using h_plot_one helper.
;;    - Horizontal    (DY = 0, DX != 0) : Byte-aligned fast fill.
;;    - Vertical      (DX = 0, DY != 0) : 8-line scanline stepping.
;;
;; Bresenham's Line Algorithm Description:
;;    Bresenham's algorithm determines which discrete pixels on a 2D raster 
;;    grid should be selected to form a close approximation of a straight 
;;    line between two given points (X0, Y0) and (X1, Y1).
;;
;;    1. Deltas and Directions:
;;       Calculates delta distances DX = |X1 - X0| and DY = |Y1 - Y0|, as well
;;       as directional steps SX = sgn(X1 - X0) and SY = sgn(Y1 - Y0).
;;
;;    2. Decision Error Variable:
;;       Initializes an accumulated decision error term: err = DX - DY.
;;
;;    3. At each pixel step:
;;       - Evaluates e2 = 2 * err.
;;       - If e2 >= -DY: subtracts DY from err and steps X in direction SX.
;;       - If e2 <= DX: adds DX to err and steps Y in direction SY.
;;
;; Known limitations:
;;  * This function *will not work from ROM*, as it uses self-modifying code.
;;  * This function disable interruptions
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL, IX, IY, AF', BC', DE', HL'
;;
;; Required memory:
;;    755 bytes (729 bytes routine + 26 bytes binding wrapper)
;;
;; Time Measures (Includes +34 us / +136 CPU cycles binding wrapper overhead):
;; (start code)
;;    Case / Coordinates                       | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Setup Overhead (routine + binding)       | -      | ~248           | ~990
;;    Single Point  (50,50) to (50,50) [Fast]  | 1      | 214            | 856
;;    Horizontal    (0,0)   to (100,0) [Fast]  | 101    | 790            | 3160
;;    Vertical      (0,0)   to (0,100) [Fast]  | 101    | 1730           | 6920
;;    Shallow Slope (0,0)   to (100,25)        | 101    | ~8800          | ~35200
;;    Diagonal 45°  (0,0)   to (100,100)       | 101    | ~9625          | ~38500
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
rb_off_start:  .db 0          ;; Start pixel offset (0..3)
rb_off_end:    .db 0          ;; End pixel offset (0..3)
rb_byte_start: .db 0          ;; Start byte column (0..79)
rb_byte_end:   .db 0          ;; End byte column (0..79)
rb_mid_count:  .db 0          ;; Number of full intermediate bytes
screen_start:  .ds 2          ;; Base VRAM address (16-bit)
color_pen:     .db 0          ;; Pre-multiplied color index (color * 4)
y0_val:        .db 0          ;; Current Y coordinate (RAM storage)

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
    ld    hl, (x0)                ;; [5] HL = X0 coordinate
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
    or    (hl)                    ;; [2] Merge pixel 3 byte pattern -> A = solid byte pattern
    ld    (solid_op + 1), a       ;; [4] Store solid byte pattern operand into SMC
    pop   hl                      ;; [3] Restore HL = signed DX
    ld    de, (x0)                ;; [5] DE = X0 coordinate
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
    jp    z, h_done               ;; [3] IF finished THEN jump h_done
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
    jp    z, h_done               ;; [3] IF finished THEN jump h_done
    inc   c                       ;; [1] Move to next pixel offset
    jr    h_end_loop              ;; [3] Loop next pixel
h_done:
    jp    end_draw_line           ;; [3] Jump to binding end

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
    ld    hl, (x0)                ;; [5] HL = X coordinate
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
    ld    hl, (x0)                ;; [5] HL = X coordinate
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
    ld    l, a                    ;; [1] L = color offset (color * 4 + pixel_index)
    ld    h, #0                   ;; [2] Clear H for 16-bit offset calculation
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
;; GENERIC BRESENHAM (v3a, alternate registers)
;; ============================================================================
normal_draw:
    ld    (screen_start), hl      ;; [5] Store VRAM base address into RAM
    ex    de, hl                  ;; [1] HL = X0 coordinate, DE = base VRAM address
    ld    (x0), hl                ;; [5] Save X0 coordinate into RAM
    pop   de                      ;; [3] DE = Y0 coordinate
    ld    a, e                    ;; [1] A = Y0 coordinate
    ld    (y0_val), a             ;; [4] Store initial Y0 into RAM
    ex    de, hl                  ;; [1] DE = X0, HL = Y0
    pop   hl                      ;; [3] HL = X1 coordinate
    sbc   hl, de                  ;; [3] HL = DX = X1 - X0 (Sets Z flag if DX == 0)
    ld    e, a                    ;; [1] E = Y0
    pop   bc                      ;; [3] B = color, C = Y1 (Z flag from sbc)
    jr    nz, dx_nonzero          ;; [2/3] IF DX != 0 THEN jump dx_nonzero

    ;; ---- DX == 0 case ----
    sub   c                       ;; [1] A = Y0 - Y1
    jp    z, single_draw          ;; [3] IF Y0 == Y1 THEN single point
    ld    a, e                    ;; [1] Restore A = Y0
    jp    vertical_draw           ;; [3] DX == 0 and DY != 0 -> vertical_draw

dx_nonzero:
    ;; ---- DX != 0 case ----
    sub   c                       ;; [1] A = Y0 - Y1
    jp    z, horizontal_draw      ;; [3] DY == 0 and DX != 0 -> horizontal_draw
    COLOR_PEN_FROM_B              ;; [7] Calculate pre-multiplied color index

compute_dx:
    ld    b, #0x23                ;; [2] B = opcode 'inc iy' (SX = +1)
    ld    a, #0x08                ;; [2] A = second byte opcode 'rrc b' (SX = +1)
    ld    (bg_rot), a             ;; [4] Store mask rotation opcode into SMC
    ld    a, #0x09                ;; [2] A = second byte opcode 'rrc c' (SX = +1)
    ld    (col_rot), a            ;; [4] Store color rotation opcode into SMC
    ld    a, #0x00                ;; [2] Byte boundary offset for SX = +1 (0)
    ld    (sx_bound_val), a       ;; [4] Store boundary offset into SMC
    ld    a, #0x01                ;; [2] Opcode 'rlc c' for byte wrap color alignment (SX = +1)
    ld    (col_align_rot1), a     ;; [4] Store alignment rotation 1 opcode into SMC
    ld    (col_align_rot2), a     ;; [4] Store alignment rotation 2 opcode into SMC
    ld    (col_align_rot3), a     ;; [4] Store alignment rotation 3 opcode into SMC
    bit   7, h                    ;; [2] Check sign of DX
    jr    z, compute_dy           ;; [2/3] IF DX >= 0 THEN jump compute_dy
    ld    b, #0x2B                ;; [2] B = opcode 'dec iy' (SX = -1)
    ld    a, #0x00                ;; [2] A = second byte opcode 'rlc b' (SX = -1)
    ld    (bg_rot), a             ;; [4] Store mask rotation opcode into SMC
    ld    a, #0x01                ;; [2] A = second byte opcode 'rlc c' (SX = -1)
    ld    (col_rot), a            ;; [4] Store color rotation opcode into SMC
    ld    a, #0x03                ;; [2] Byte boundary offset for SX = -1 (3)
    ld    (sx_bound_val), a       ;; [4] Store boundary offset into SMC
    ld    a, #0x09                ;; [2] Opcode 'rrc c' for byte wrap color alignment (SX = -1)
    ld    (col_align_rot1), a     ;; [4] Store alignment rotation 1 opcode into SMC
    ld    (col_align_rot2), a     ;; [4] Store alignment rotation 2 opcode into SMC
    ld    (col_align_rot3), a     ;; [4] Store alignment rotation 3 opcode into SMC
    xor   a                       ;; [1] Clear A
    sub   l                       ;; [1] HL = -DX
    ld    l, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   h                       ;; [1] |
    ld    h, a                    ;; [1] HL = |DX|

compute_dy:
    ld    (dx), hl                ;; [4] Save absolute DX into SMC
    ld    a, b                    ;; [1] A = SX step opcode ('inc iy' / 'dec iy')
    ld    (add_sx), a             ;; [4] Store SX opcode into SMC
    ld    (sx_ptr_op), a          ;; [4] Store VRAM pointer opcode ('inc hl' / 'dec hl')
    ld    a, c                    ;; [1] A = Y1
    sub   e                       ;; [1] A = DY = Y1 - Y0

compute_sy:
    ld    b, #0x3C                ;; [2] B = opcode 'inc a' (SY = +1)
    jr    nc, compute_err         ;; [2/3] IF Y1 >= Y0 THEN jump compute_err
    neg                           ;; [2] A = -DY
    ld    b, #0x3D                ;; [2] B = opcode 'dec a' (SY = -1)

compute_err:
    ld    c, a                    ;; [1] C = absolute DY
    ld    a, b                    ;; [1] A = SY step opcode
    ld    (add_sy_op), a          ;; [4] Store SY opcode into SMC
    ld    b, #00                  ;; [2] BC = absolute DY

compute_pixels:
    push  hl                      ;; [4] Save absolute DX on stack
    or    a                       ;; [1] Clear carry flag
    sbc   hl, bc                  ;; [3] Compare DX and DY
    add   hl, bc                  ;; [3] Restore HL = DX
    jr    nc, dx_is_max           ;; [2/3] IF DX >= DY THEN DX is max
dy_is_max:
    ld    h, b                    ;; [1] HL = DY
    ld    l, c                    ;; [1] |
dx_is_max:
    inc   hl                      ;; [2] HL = max(DX, DY) + 1 (total pixel count)
    push  hl                      ;; [4] Put HL on stack for alternate DE'
    exx                           ;; [1] Switch to alternate register set
    pop   de                      ;; [3] DE' = total pixel count
    exx                           ;; [1] Switch back to main register set
    pop   hl                      ;; [4] Restore HL = DX from stack
    xor   a                       ;; [1] BC = -DY
    sub   c                       ;; [1] |
    ld    c, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   b                       ;; [1] |
    ld    b, a                    ;; [1] |
    ld    (dy), bc                ;; [4] Store -DY into SMC
    or    a                       ;; [1] Clear carry flag
    add   hl, bc                  ;; [3] HL = ERR = DX + (-DY)
    ld    b, h                    ;; [1] BC = ERR
    ld    c, l                    ;; [1] |
    ld__ixh_b                     ;; [2] IXH = high byte of ERR
    ld__ixl_c                     ;; [2] IXL = low byte of ERR
x0=.+1
    ld    hl, #0000               ;; [3] HL = X0 (SMC loaded)
    push  hl                      ;; [4] Save X0 on stack
    pop   iy                      ;; [4] IY = X0 (current X)

compute_start_vmem:
    push  hl                      ;; [4] Save X0 on stack
    DIV4_HL                       ;; [8] Convert X0 to byte column
    ld    c, l                    ;; [1] C = X_byte
    ld    a, e                    ;; [1] A = Y0
    ld    b, a                    ;; [1] B = Y0
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM address of (X_byte, Y0)
    push  hl                      ;; [4] Save VRAM address on stack
    exx                           ;; [1] Switch to alternate register set
    pop   hl                      ;; [3] HL' = initial VRAM pointer
    exx                           ;; [1] Switch back to main register set
    pop   hl                      ;; [4] Restore X0 from stack
    ld    a, l                    ;; [1] A = X0 low byte
    and   #3                      ;; [2] A = pixel offset (0..3)
    ld    c, a                    ;; [1] C = pixel offset
    ld    hl, #cpct_plotMasksTable_M1 ;; [3] HL = masks table base
    ld    b, #00                  ;; [2] B = 0
    add   hl, bc                  ;; [3] HL = &masks[pixel_offset]
    ld    d, (hl)                 ;; [2] D = initial background mask
    ld    a, (color_pen)          ;; [4] A = color * 4
    add   a, c                    ;; [1] A = color * 4 + pixel_offset
    ld    hl, #cpct_plotColorTable_M1 ;; [3] HL = color table base
    ld    c, a                    ;; [1] C = combined offset
    ld    b, #00                  ;; [2] B = 0
    add   hl, bc                  ;; [3] HL = &color[combined_offset]
    ld    e, (hl)                 ;; [2] E = initial foreground color byte
    push  de                      ;; [4] Save D (mask) and E (color) on stack
    exx                           ;; [1] Switch to alternate register set
    pop   bc                      ;; [3] B' = initial mask, C' = initial color byte
    exx                           ;; [1] Switch back to main register set

;; --- MAIN LOOP ---
loop_line_pixel:
    di                            ;; [1] Disable interrupts during pixel update
plot_pixel:
    exx                           ;; [1] Switch to alternate register set
    ld    a, (hl)                 ;; [2] Read VRAM byte via HL'
    and   b                       ;; [1] Apply background mask stored in B'
    or    c                       ;; [1] Inject foreground color byte stored in C'
    ld    (hl), a                 ;; [2] Write byte back to VRAM via HL'
    exx                           ;; [1] Switch back to main register set
err_2_compute:
    ld__d_ixh                     ;; [2] D = IXH (high byte of ERR)
    ld__e_ixl                     ;; [2] E = IXL (low byte of ERR)
    sla   e                       ;; [2] Shift E left
    rl    d                       ;; [2] Rotate D left through carry (DE = e2 = 2*ERR)
x_move:
dy=.+1
    ld    hl, #0000               ;; [3] HL = -DY (SMC loaded)
    ex    de, hl                  ;; [1] HL = e2, DE = -DY
    ld    a, h                    ;; [1] Flip sign bit of H
    xor   #0x80                   ;; [2] |
    ld    h, a                    ;; [1] |
    ld    b, d                    ;; [1] Save original D
    ld    a, d                    ;; [1] Flip sign bit of D
    xor   #0x80                   ;; [2] |
    ld    d, a                    ;; [1] |
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] Compare e2 with -DY
    add   hl, de                  ;; [3] Restore e2
    jr    c, y_move               ;; [2/3] IF e2 < -DY THEN skip X step
    jr    z, y_move               ;; [2/3] IF e2 == -DY THEN skip X step
    ld    d, b                    ;; [1] Restore original D
    add   ix, de                  ;; [4] ERR -= DY
add_sx=.+1
    .db   #0xFD                   ;; [3] SMC: 'inc iy' or 'dec iy'
    .db   #0x00
    exx                           ;; [1] Switch to alternate register set
    .db   #0xCB                   ;; [2] SMC prefix
bg_rot:
    .db   #0x08                   ;; [2] SMC opcode: 0x08 = 'rrc b' / 0x00 = 'rlc b'
    ld__a_iyl                     ;; [2] A = IYL (current X low byte)
    and   #3                      ;; [2] Check pixel offset
sx_bound_val=.+1
    cp    #0x00                   ;; [2] SMC boundary test (0x00 for SX=+1, 0x03 for SX=-1)
    jr    z, col_wrap             ;; [2/3] IF boundary crossed THEN jump col_wrap
    .db   #0xCB                   ;; [2] SMC prefix
col_rot:
    .db   #0x09                   ;; [2] SMC opcode: 0x09 = 'rrc c' / 0x01 = 'rlc c'
    jr    x_move_done             ;; [3] Jump to completion of X step
col_wrap:
    .db   #0xCB                   ;; [2] SMC prefix
col_align_rot1:
    .db   #0x01                   ;; [2] SMC opcode: color alignment shift 1 ('rlc c' / 'rrc c')
    .db   #0xCB                   ;; [2] SMC prefix
col_align_rot2:
    .db   #0x01                   ;; [2] SMC opcode: color alignment shift 2 ('rlc c' / 'rrc c')
    .db   #0xCB                   ;; [2] SMC prefix
col_align_rot3:
    .db   #0x01                   ;; [2] SMC opcode: color alignment shift 3 ('rlc c' / 'rrc c')
sx_ptr_op:
    .db   #0x23                   ;; [2] SMC: 'inc hl' / 'dec hl' (updates HL')
x_move_done:
    exx                           ;; [1] Switch back to main register set
y_move:
dx=.+1
    ld    de, #0000               ;; [3] DE = DX (SMC loaded)
    ld    b, d                    ;; [1] BC = DX
    ld    c, e                    ;; [1] |
    ld    a, d                    ;; [1] Flip sign bit of D
    xor   #0x80                   ;; [2] |
    ld    d, a                    ;; [1] |
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] Compare e2 with DX
    jp    p, last_pixel           ;; [2/3] IF e2 >= DX THEN skip Y step
    add   ix, bc                  ;; [4] ERR += DX
    ld    a, (y0_val)             ;; [4] A = current Y
add_sy_op:
    .db   #0x00                   ;; [1] SMC: 'inc a' or 'dec a'
    ld    (y0_val), a             ;; [4] Save updated Y
    ld    a, (add_sy_op)          ;; [4] Reload SY opcode (0x3C / 0x3D)
    cp    #0x3C                   ;; [2] Check if SY == +1 ('inc a')
    jr    nz, y_up                ;; [2/3] IF SY != +1 THEN jump y_up
y_down:
    exx                           ;; [1] Switch to alternate register set
    ld    a, h                    ;; [1] A = H' byte
    add   a, #0x08                ;; [2] Move H' down 1 scanline (+0x0800)
    ld    h, a                    ;; [1] H' = updated high byte
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, y_d_ok              ;; [2/3] IF inside block THEN jump y_d_ok
    ld    a, l                    ;; [1] A = L' byte
    add   a, #0x50                ;; [2] L' += 0x50 (with carry)
    ld    l, a                    ;; [1] L' = updated low byte
    ld    a, h                    ;; [1] A = H' byte
    adc   a, #0xC0                ;; [2] H' += 0xC0 + carry
    ld    h, a                    ;; [1] H' = updated high byte
y_d_ok:
    exx                           ;; [1] Switch back to main register set
    jr    last_pixel              ;; [3] Jump to last_pixel
y_up:
    exx                           ;; [1] Switch to alternate register set
    ld    a, h                    ;; [1] A = H' byte
    and   #0x38                   ;; [2] Check if line 0 of character row
    jr    z, y_u_row              ;; [2/3] IF line 0 THEN jump y_u_row
    ld    a, h                    ;; [1] A = H' byte
    sub   #0x08                   ;; [2] Move H' up 1 scanline (-0x0800)
    ld    h, a                    ;; [1] H' = updated high byte
    jr    y_u_ok                  ;; [3] Jump to y_u_ok
y_u_row:
    ld    a, l                    ;; [1] A = L' byte
    add   a, #0xB0                ;; [2] L' += 0xB0 (with carry)
    ld    l, a                    ;; [1] L' = updated low byte
    ld    a, h                    ;; [1] A = H' byte
    adc   a, #0x37                ;; [2] H' += 0x37 + carry
    ld    h, a                    ;; [1] H' = updated high byte
y_u_ok:
    exx                           ;; [1] Switch back to main register set
    jr    last_pixel              ;; [3] Jump to last_pixel
last_pixel:
    exx                           ;; [1] Switch to alternate register set
    dec   de                      ;; [2] Decrement total pixel count DE'
    ld    a, d                    ;; [1] Check if pixel count DE' == 0
    or    e                       ;; [1] |
    exx                           ;; [1] Switch back to main register set
    ei                            ;; [1] Re-enable interrupts to service pending IRQs
    jp    nz, loop_line_pixel     ;; [3] IF pixels remaining THEN loop

end_draw_line:
    ;; Return in binding wrapper