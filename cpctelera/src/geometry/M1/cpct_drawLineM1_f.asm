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
;; Function: cpct_drawLineM1_f
;;
;;    Draws a straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using an optimized dual-path Bresenham algorithm.
;;    Includes dedicated fast-path handlers for Single Point, Horizontal, and Vertical
;;    lines, as well as 8 inlined directional rasterizer loops.
;;
;; C Definition:
;;    void cpct_drawLineM1_f(void* screen_base, u16 x0, u16 y0, u16 x1, u8 y1, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B DE) screen_base - Base VRAM memory address
;;    (2B HL) x0          - Starting X coordinate (0-319)
;;    (Stack) y0          - Starting Y coordinate (0-199, 16-bit integer)
;;    (Stack) x1          - Ending X coordinate (0-319, 16-bit integer)
;;    (Stack) color / y1  - Color index (B: 0-3) and Ending Y coordinate (C: 0-199)
;;
;; Assembly call:
;;     > call cpct_drawLineM1_f
;;
;; Fast-Path Special Cases:
;;
;;    - Single Point  (DX = 0, DY = 0)  : Direct pixel plot.
;;    - Horizontal    (DY = 0, DX != 0) : Byte-aligned fast solid fill.
;;    - Vertical      (DX = 0, DY != 0) : 8-line scanline stepping.
;;
;; Optimized Bresenham Architecture:
;;    1. Dual-Path Split:
;;
;;       - Gentle Slope (DX >= DY) : X is the driving axis (steps unconditionally)
;;       - Steep Slope  (DY > DX)  : Y is the driving axis (steps unconditionally)
;;    2. Pixel write with a constant solid color byte: (VRAM ^ solid) & mask ^ solid,
;;       so that only the pixel mask is rotated when stepping in X.
;;    3. Error term kept in alternate registers (HL' = error, DE' = -2*minor,
;;       BC' = 2*major): one 16-bit ADD gives both the update and the step decision
;;       (Carry = 0 when the minor axis has to step).
;;    4. Pixel counter split in IXL / IXH (8-bit decrement in the loop).
;;
;; Known limitations:
;;
;;  * This function will not work from ROM, as it uses self-modifying code.
;;  * This function disables interrupts while drawing sloped lines (alternate
;;    registers are used) and restores the previous interrupt status on exit.
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL, BC', DE', HL'
;;
;; Required memory:
;;    939 bytes (901 bytes routine + 12 bytes data + 26 bytes binding wrapper)
;;
;; Time Measures (From C, including call and binding wrapper overhead; sloped lines
;; estimated from <cpct_drawLineM1> measures and per pixel cycle differences, as
;; interrupts are disabled while drawing them):
;; (start code)
;;    Case / Coordinates                       | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Single Point  (50,50) to (50,50) [Fast]  | 1      | ~290           | ~1160
;;    Horizontal    (0,0)   to (100,0) [Fast]  | 101    | ~860           | ~3440
;;    Vertical      (0,0)   to (0,100) [Fast]  | 101    | ~2570          | ~10280
;;    Shallow Slope (0,0)   to (100,25)        | 101    | ~3290          | ~13160
;;    Diagonal 45°  (0,0)   to (100,100)       | 101    | ~4390          | ~17560
;;    Steep Slope   (0,0)   to (25,100)        | 101    | ~3650          | ~14600
;;   ---------------------------------------------------------------------------------
;; (end code)
;;
;; Credits:
;;    Ervin Pajor for optimized code example https://github.com/lronaldo/cpctelera/issues/21
;;
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

;; SOLID_FROM_B: A = 4 pixels solid color byte for color index B (0-3)
;;   (0 -> 0x00, 1 -> 0xF0, 2 -> 0x0F, 3 -> 0xFF)
;;   Execution time: 10/11 us / 40/44 CPU cycles
;;   Size: 11 bytes
.macro SOLID_FROM_B
    ld    a, b                    ;; [1] A = color index (0-3)
    rrca                          ;; [1] Carry = color bit 0 (LSB)
    sbc   a, a                    ;; [1] A = 0xFF if LSB set, 0x00 otherwise
    and   #0xF0                   ;; [2] A = LSB bits of the 4 pixels
    bit   1, b                    ;; [2] Test color bit 1 (MSB)
    jr    z, .+4                  ;; [2/3] IF MSB not set THEN skip next instruction
    or    #0x0F                   ;; [2] A |= MSB bits of the 4 pixels
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
color_pen:      .db 0          ;; Pre-multiplied color index (color * 4)
y0_val:         .db 0          ;; Current Y coordinate (RAM storage)
x0_val:         .dw 0          ;; Current X0 coordinate (RAM storage)
solid_val:      .db 0          ;; Solid color byte (4 pixels of the line color)

;;-------------------------------------------------------------------------------
;; CODE SECTION
;;-------------------------------------------------------------------------------
.area _CODE
jp    normal_draw             ;; [3] Jump to main entry and dispatch

;; ============================================================================
;; SINGLE POINT FAST-PATH (DX = 0, DY = 0)
;; ============================================================================
single_draw:
    SOLID_FROM_B                  ;; [11] A = solid color byte
    ld    (solid_val), a          ;; [4] Store solid color byte
    call  get_ptr_mask            ;; [5] HL = VRAM address, B = pixel mask
    ld    a, (solid_val)          ;; [4] A = solid color byte
    ld    c, a                    ;; [1] C = solid color byte
    ld    a, (hl)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (hl), a                 ;; [2] Write byte to VRAM
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
    ld    (y0_val), a             ;; [4] Y_start = min(Y0, Y1) used by get_ptr_mask
    sub   c                       ;; [1] A = Y_start - Y_end
    neg                           ;; [2] A = Y_end - Y_start
    inc   a                       ;; [1] A = height in pixels
    ld    (v_count_op + 1), a     ;; [4] Store loop count into SMC
    SOLID_FROM_B                  ;; [11] A = solid color byte
    ld    c, a                    ;; [1] C = solid color byte
    push  bc                      ;; [4] Preserve solid color byte
    call  get_ptr_mask            ;; [5] HL = VRAM start address, B = pixel mask
    pop   de                      ;; [3] E = solid color byte
    ld    a, b                    ;; [1] A = pixel mask
    ld    (v_mask_op + 1), a      ;; [4] Patch SMC mask byte
    cpl                           ;; [1] A = pixel selection bits
    and   e                       ;; [1] A = pixel color byte
    ld    (v_col_op + 1), a       ;; [4] Patch SMC color byte
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
    ld    a, l                    ;; [1] HL += 0xC050 (next character row)
    add   a, #0x50                ;; [2] |
    ld    l, a                    ;; [1] |
    ld    a, h                    ;; [1] |
    adc   a, #0xC0                ;; [2] |
    ld    h, a                    ;; [1] |
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

;; ----------------------------------------------------------------------------
;; Helper Routine: get_ptr_mask
;;    Input : (x0_val), (y0_val), (screen_start)
;;    Output: HL = VRAM address of pixel (X0, Y0), B = pixel background mask
;;    Destroyed: AF, BC, DE, HL
;; ----------------------------------------------------------------------------
get_ptr_mask:
    ld    hl, (x0_val)            ;; [5] HL = X0 coordinate
    ld    a, l                    ;; [1] A = X0 low byte
    and   #3                      ;; [2] A = pixel offset (0..3)
    push  af                      ;; [4] Save pixel offset
    DIV4_HL                       ;; [8] Convert X0 to byte column
    ld    c, l                    ;; [1] C = X_byte
    ld    a, (y0_val)             ;; [4] A = Y0
    ld    b, a                    ;; [1] B = Y0
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM address
    pop   af                      ;; [3] A = pixel offset (0..3)
    ld    b, #0x77                ;; [2] B = mask of pixel 0
    or    a                       ;; [1] IF pixel offset == 0
    ret   z                       ;; [2/4] THEN mask ready
gpm_rot:
    rrc   b                       ;; [2] Mask of next pixel
    dec   a                       ;; [1] |
    jr    nz, gpm_rot             ;; [2/3] Loop until pixel offset reached
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

    ;; ---- Save interrupt status and disable interrupts (alternate registers used) ----
    ld    a, i                    ;; [3] P/V flag set to current interrupt status (IFF2 flip-flop)
    ld    a, #opc_EI              ;; [2] A = Opcode for Enable Interrupts instruction (EI = 0xFB)
    jp    pe, int_enabled         ;; [3] IF interrupts are enabled THEN EI is the appropriate instruction
    ld    a, #opc_DI              ;; [2] Otherwise, A = Opcode for Disable Interrupts instruction (DI = 0xF3)
int_enabled:
    ld    (restore_int), a        ;; [4] Patch interrupt status restoration at end of routine
    di                            ;; [1] Disable interruptions

    SOLID_FROM_B                  ;; [11] A = solid color byte
    ld    (solid_val), a          ;; [4] Store solid color byte

    ;; ---- |DY| and SY (B = direction flags: bit0 = Up, bit1 = Left, bit2 = Steep) ----
    ld    b, #0                   ;; [2] B = direction flags (Right, Down, Gentle)
    ld    a, e                    ;; [1] A = Y0
    sub   c                       ;; [1] A = Y0 - Y1
    jr    nc, sy_up               ;; [2/3] IF Y0 > Y1 THEN SY = Up
    neg                           ;; [2] A = |DY| = Y1 - Y0
    jr    sy_done                 ;; [3]
sy_up:
    inc   b                       ;; [1] Flag Up
sy_done:
    ld    e, a                    ;; [1] E = |DY|
    ld    d, #0                   ;; [2] DE = |DY| (16-bit)

    ;; ---- |DX| and SX ----
    bit   7, h                    ;; [2] Check sign of DX
    jr    z, sx_done              ;; [2/3] IF DX >= 0 THEN SX = Right
    set   1, b                    ;; [2] Flag Left
    xor   a                       ;; [1] HL = -DX
    sub   l                       ;; [1] |
    ld    l, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   h                       ;; [1] |
    ld    h, a                    ;; [1] HL = |DX|
sx_done:

    ;; ---- Major / minor axis: HL = major, E = minor (minor always < 256) ----
    ld    a, h                    ;; [1] IF |DX| >= 256
    or    a                       ;; [1] |
    jr    nz, axis_done           ;; [2/3] THEN gentle slope
    ld    a, l                    ;; [1] A = |DX|
    cp    e                       ;; [1] Compare |DX| and |DY|
    jr    nc, axis_done           ;; [2/3] IF |DX| >= |DY| THEN gentle slope
    set   2, b                    ;; [2] Flag Steep
    ex    de, hl                  ;; [1] HL = major = |DY|, E = minor = |DX|
axis_done:

    ;; ---- IX = major + 1 = pixel count (IXL = low byte, IXH = high byte adjusted) ----
    inc   hl                      ;; [2] HL = major + 1
    ld    a, l                    ;; [1] IXL = low byte of count
    ld__ixl_a                     ;; [2] |
    or    a                       ;; [1] Z = (low byte == 0)
    ld    a, h                    ;; [1] A = high byte of count
    jr    z, count_ok             ;; [2/3] IF low byte != 0
    inc   a                       ;; [1] THEN one more IXH round for the first partial round
count_ok:
    ld__ixh_a                     ;; [2] IXH = high byte of count (adjusted)
    dec   hl                      ;; [2] HL = major

    ;; ---- Alternate registers: HL' = major - 1, BC' = 2*major, DE' = -2*minor ----
    push  hl                      ;; [4] Transfer major
    push  de                      ;; [4] Transfer minor
    exx                           ;; [1] Switch to alternate register set
    pop   de                      ;; [3] E' = minor
    pop   hl                      ;; [3] HL' = major
    ld    b, h                    ;; [1] BC' = major
    ld    c, l                    ;; [1] |
    sla   c                       ;; [2] BC' = 2*major
    rl    b                       ;; [2] |
    dec   hl                      ;; [2] HL' = major - 1 (initial error)
    ld    a, e                    ;; [1] A = minor (1..199)
    neg                           ;; [2] A = -minor (Carry = 1)
    ld    e, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    ld    d, a                    ;; [1] DE' = -minor
    sla   e                       ;; [2] DE' = -2*minor
    rl    d                       ;; [2] |
    exx                           ;; [1] Switch back to main register set

    ;; ---- Main registers: DE = VRAM pointer, B = pixel mask, C = solid color ----
    push  bc                      ;; [4] Save direction flags
    call  get_ptr_mask            ;; [5] HL = VRAM address, B = pixel mask
    ex    de, hl                  ;; [1] DE = VRAM address
    ld    a, (solid_val)          ;; [4] A = solid color byte
    ld    c, a                    ;; [1] C = solid color byte
    pop   af                      ;; [3] A = direction flags

    ;; ---- 8-Way Dispatcher (Gentle/Steep x Right/Left x Down/Up) ----
    bit   2, a                    ;; [2] IF Steep
    jr    nz, disp_steep          ;; [2/3] THEN steep dispatch
    bit   1, a                    ;; [2] IF Left
    jr    nz, disp_gentle_left    ;; [2/3] THEN gentle left dispatch
    rra                           ;; [1] Carry = Up
    jp    c, gru_loop             ;; [3] Gentle Right Up
    jp    grd_loop                ;; [3] Gentle Right Down
disp_gentle_left:
    rra                           ;; [1] Carry = Up
    jp    c, glu_loop             ;; [3] Gentle Left Up
    jp    gld_loop                ;; [3] Gentle Left Down
disp_steep:
    bit   1, a                    ;; [2] IF Left
    jr    nz, disp_steep_left     ;; [2/3] THEN steep left dispatch
    rra                           ;; [1] Carry = Up
    jp    c, sru_loop             ;; [3] Steep Right Up
    jp    srd_loop                ;; [3] Steep Right Down
disp_steep_left:
    rra                           ;; [1] Carry = Up
    jp    c, slu_loop             ;; [3] Steep Left Up
    jp    sld_loop                ;; [3] Steep Left Down

;; ============================================================================
;; GENTLE LOOPS (X driving axis, IX = DX + 1)
;;    Main: DE = VRAM pointer, B = pixel mask, C = solid color byte
;;    Alt : HL' = error, DE' = -2*DY, BC' = 2*DX
;; ============================================================================

;; ----------------------------------------------------------------------------
;; 1. GENTLE RIGHT DOWN (SX = +1, SY = +1)
;; ----------------------------------------------------------------------------
grd_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    rrc   b                       ;; [2] Next pixel mask (Carry = 0 on byte wrap)
    jr    c, grd_x_ok             ;; [2/3] IF no byte wrap THEN X step done
    inc   de                      ;; [2] Move DE to next byte column
grd_x_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DY (Carry = 0 if Y has to step)
    jr    nc, grd_y_step          ;; [2/3] IF Carry = 0 THEN step Y
    exx                           ;; [1] Switch back to main register set
grd_count:
    dec__ixl                      ;; [2] Decrement pixel counter low byte
    jp    nz, grd_loop            ;; [3] IF pixels remaining in round THEN loop
    dec__ixh                      ;; [2] Decrement pixel counter high byte
    jp    nz, grd_loop            ;; [3] IF rounds remaining THEN loop
    jp    restore_int             ;; [3] Line completed
grd_y_step:
    add   hl, bc                  ;; [3] Error += 2*DX
    exx                           ;; [1] Switch back to main register set
    ld    a, d                    ;; [1] Move DE 1 scanline down (+0x0800)
    add   a, #0x08                ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, grd_count           ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0xC050 (next character row)
    add   a, #0x50                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0xC0                ;; [2] |
    ld    d, a                    ;; [1] |
    jr    grd_count               ;; [3] Continue with counter

;; ----------------------------------------------------------------------------
;; 2. GENTLE LEFT DOWN (SX = -1, SY = +1)
;; ----------------------------------------------------------------------------
gld_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    rlc   b                       ;; [2] Previous pixel mask (Carry = 0 on byte wrap)
    jr    c, gld_x_ok             ;; [2/3] IF no byte wrap THEN X step done
    dec   de                      ;; [2] Move DE to previous byte column
gld_x_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DY (Carry = 0 if Y has to step)
    jr    nc, gld_y_step          ;; [2/3] IF Carry = 0 THEN step Y
    exx                           ;; [1] Switch back to main register set
gld_count:
    dec__ixl                      ;; [2] Decrement pixel counter low byte
    jp    nz, gld_loop            ;; [3] IF pixels remaining in round THEN loop
    dec__ixh                      ;; [2] Decrement pixel counter high byte
    jp    nz, gld_loop            ;; [3] IF rounds remaining THEN loop
    jp    restore_int             ;; [3] Line completed
gld_y_step:
    add   hl, bc                  ;; [3] Error += 2*DX
    exx                           ;; [1] Switch back to main register set
    ld    a, d                    ;; [1] Move DE 1 scanline down (+0x0800)
    add   a, #0x08                ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, gld_count           ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0xC050 (next character row)
    add   a, #0x50                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0xC0                ;; [2] |
    ld    d, a                    ;; [1] |
    jr    gld_count               ;; [3] Continue with counter

;; ----------------------------------------------------------------------------
;; 3. GENTLE RIGHT UP (SX = +1, SY = -1)
;; ----------------------------------------------------------------------------
gru_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    rrc   b                       ;; [2] Next pixel mask (Carry = 0 on byte wrap)
    jr    c, gru_x_ok             ;; [2/3] IF no byte wrap THEN X step done
    inc   de                      ;; [2] Move DE to next byte column
gru_x_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DY (Carry = 0 if Y has to step)
    jr    nc, gru_y_step          ;; [2/3] IF Carry = 0 THEN step Y
    exx                           ;; [1] Switch back to main register set
gru_count:
    dec__ixl                      ;; [2] Decrement pixel counter low byte
    jp    nz, gru_loop            ;; [3] IF pixels remaining in round THEN loop
    dec__ixh                      ;; [2] Decrement pixel counter high byte
    jp    nz, gru_loop            ;; [3] IF rounds remaining THEN loop
    jp    restore_int             ;; [3] Line completed
gru_y_step:
    add   hl, bc                  ;; [3] Error += 2*DX
    exx                           ;; [1] Switch back to main register set
    ld    a, d                    ;; [1] Move DE 1 scanline up (-0x0800)
    sub   #0x08                   ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check if we left line 0 of a character row
    cp    #0x38                   ;; [2] |
    jr    nz, gru_count           ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0x3FB0 (line 7 of previous character row)
    add   a, #0xB0                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0x3F                ;; [2] |
    ld    d, a                    ;; [1] |
    jr    gru_count               ;; [3] Continue with counter

;; ----------------------------------------------------------------------------
;; 4. GENTLE LEFT UP (SX = -1, SY = -1)
;; ----------------------------------------------------------------------------
glu_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    rlc   b                       ;; [2] Previous pixel mask (Carry = 0 on byte wrap)
    jr    c, glu_x_ok             ;; [2/3] IF no byte wrap THEN X step done
    dec   de                      ;; [2] Move DE to previous byte column
glu_x_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DY (Carry = 0 if Y has to step)
    jr    nc, glu_y_step          ;; [2/3] IF Carry = 0 THEN step Y
    exx                           ;; [1] Switch back to main register set
glu_count:
    dec__ixl                      ;; [2] Decrement pixel counter low byte
    jp    nz, glu_loop            ;; [3] IF pixels remaining in round THEN loop
    dec__ixh                      ;; [2] Decrement pixel counter high byte
    jp    nz, glu_loop            ;; [3] IF rounds remaining THEN loop
    jp    restore_int             ;; [3] Line completed
glu_y_step:
    add   hl, bc                  ;; [3] Error += 2*DX
    exx                           ;; [1] Switch back to main register set
    ld    a, d                    ;; [1] Move DE 1 scanline up (-0x0800)
    sub   #0x08                   ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check if we left line 0 of a character row
    cp    #0x38                   ;; [2] |
    jr    nz, glu_count           ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0x3FB0 (line 7 of previous character row)
    add   a, #0xB0                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0x3F                ;; [2] |
    ld    d, a                    ;; [1] |
    jr    glu_count               ;; [3] Continue with counter

;; ============================================================================
;; STEEP LOOPS (Y driving axis, IXL = DY + 1 <= 200)
;;    Main: DE = VRAM pointer, B = pixel mask, C = solid color byte
;;    Alt : HL' = error, DE' = -2*DX, BC' = 2*DY
;; ============================================================================

;; ----------------------------------------------------------------------------
;; 5. STEEP RIGHT DOWN (SX = +1, SY = +1)
;; ----------------------------------------------------------------------------
srd_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    ld    a, d                    ;; [1] Move DE 1 scanline down (+0x0800)
    add   a, #0x08                ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, srd_y_ok            ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0xC050 (next character row)
    add   a, #0x50                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0xC0                ;; [2] |
    ld    d, a                    ;; [1] |
srd_y_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DX (Carry = 0 if X has to step)
    jr    nc, srd_x_step          ;; [2/3] IF Carry = 0 THEN step X
    exx                           ;; [1] Switch back to main register set
srd_count:
    dec__ixl                      ;; [2] Decrement pixel counter
    jp    nz, srd_loop            ;; [3] IF pixels remaining THEN loop
    jp    restore_int             ;; [3] Line completed
srd_x_step:
    add   hl, bc                  ;; [3] Error += 2*DY
    exx                           ;; [1] Switch back to main register set
    rrc   b                       ;; [2] Next pixel mask (Carry = 0 on byte wrap)
    jr    c, srd_count            ;; [2/3] IF no byte wrap THEN X step done
    inc   de                      ;; [2] Move DE to next byte column
    jr    srd_count               ;; [3] Continue with counter

;; ----------------------------------------------------------------------------
;; 6. STEEP LEFT DOWN (SX = -1, SY = +1)
;; ----------------------------------------------------------------------------
sld_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    ld    a, d                    ;; [1] Move DE 1 scanline down (+0x0800)
    add   a, #0x08                ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check 8-line character block boundary
    jr    nz, sld_y_ok            ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0xC050 (next character row)
    add   a, #0x50                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0xC0                ;; [2] |
    ld    d, a                    ;; [1] |
sld_y_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DX (Carry = 0 if X has to step)
    jr    nc, sld_x_step          ;; [2/3] IF Carry = 0 THEN step X
    exx                           ;; [1] Switch back to main register set
sld_count:
    dec__ixl                      ;; [2] Decrement pixel counter
    jp    nz, sld_loop            ;; [3] IF pixels remaining THEN loop
    jp    restore_int             ;; [3] Line completed
sld_x_step:
    add   hl, bc                  ;; [3] Error += 2*DY
    exx                           ;; [1] Switch back to main register set
    rlc   b                       ;; [2] Previous pixel mask (Carry = 0 on byte wrap)
    jr    c, sld_count            ;; [2/3] IF no byte wrap THEN X step done
    dec   de                      ;; [2] Move DE to previous byte column
    jr    sld_count               ;; [3] Continue with counter

;; ----------------------------------------------------------------------------
;; 7. STEEP RIGHT UP (SX = +1, SY = -1)
;; ----------------------------------------------------------------------------
sru_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    ld    a, d                    ;; [1] Move DE 1 scanline up (-0x0800)
    sub   #0x08                   ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check if we left line 0 of a character row
    cp    #0x38                   ;; [2] |
    jr    nz, sru_y_ok            ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0x3FB0 (line 7 of previous character row)
    add   a, #0xB0                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0x3F                ;; [2] |
    ld    d, a                    ;; [1] |
sru_y_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DX (Carry = 0 if X has to step)
    jr    nc, sru_x_step          ;; [2/3] IF Carry = 0 THEN step X
    exx                           ;; [1] Switch back to main register set
sru_count:
    dec__ixl                      ;; [2] Decrement pixel counter
    jp    nz, sru_loop            ;; [3] IF pixels remaining THEN loop
    jp    restore_int             ;; [3] Line completed
sru_x_step:
    add   hl, bc                  ;; [3] Error += 2*DY
    exx                           ;; [1] Switch back to main register set
    rrc   b                       ;; [2] Next pixel mask (Carry = 0 on byte wrap)
    jr    c, sru_count            ;; [2/3] IF no byte wrap THEN X step done
    inc   de                      ;; [2] Move DE to next byte column
    jr    sru_count               ;; [3] Continue with counter

;; ----------------------------------------------------------------------------
;; 8. STEEP LEFT UP (SX = -1, SY = -1)
;; ----------------------------------------------------------------------------
slu_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
    ld    a, d                    ;; [1] Move DE 1 scanline up (-0x0800)
    sub   #0x08                   ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check if we left line 0 of a character row
    cp    #0x38                   ;; [2] |
    jr    nz, slu_y_ok            ;; [2/3] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0x3FB0 (line 7 of previous character row)
    add   a, #0xB0                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0x3F                ;; [2] |
    ld    d, a                    ;; [1] |
slu_y_ok:
    exx                           ;; [1] Switch to alternate register set
    add   hl, de                  ;; [3] Error -= 2*DX (Carry = 0 if X has to step)
    jr    nc, slu_x_step          ;; [2/3] IF Carry = 0 THEN step X
    exx                           ;; [1] Switch back to main register set
slu_count:
    dec__ixl                      ;; [2] Decrement pixel counter
    jp    nz, slu_loop            ;; [3] IF pixels remaining THEN loop
    jp    restore_int             ;; [3] Line completed
slu_x_step:
    add   hl, bc                  ;; [3] Error += 2*DY
    exx                           ;; [1] Switch back to main register set
    rlc   b                       ;; [2] Previous pixel mask (Carry = 0 on byte wrap)
    jr    c, slu_count            ;; [2/3] IF no byte wrap THEN X step done
    dec   de                      ;; [2] Move DE to previous byte column
    jr    slu_count               ;; [3] Continue with counter

;; ===============
;; END OF ROUTINE
;; ===============
restore_int:
    ei                            ;; [1] SMC: Restore previous interrupt status (EI / DI)
end_draw_line:
    ;; Return in binding
