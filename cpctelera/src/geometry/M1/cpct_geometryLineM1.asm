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
;; Function: cpct_geometryLineM1
;;
;;    Draws an arbitrary straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using Bresenham's line algorithm. Includes
;;    dedicated fast-path handlers for Single Point, Horizontal, and Vertical lines.
;;
;; C Definition:
;;    void cpct_geometryLineM1(void* screen_base, u16 x0, u16 y0, u16 x1, u8 y1, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B DE) screen_base - Base VRAM memory address
;;    (2B HL) x0          - Starting X coordinate (0-319)
;;    (Stack) y0          - Starting Y coordinate (0-199, 16-bit integer)
;;    (Stack) x1          - Ending X coordinate (0-319, 16-bit integer)
;;    (Stack) color / y1  - Color index (B: 0-3) and Ending Y coordinate (C: 0-199)
;;
;; Assembly call:
;;    > call cpct_geometryLineM1
;;
;; Fast-Path Special Cases:
;;    - Single Point  (DX = 0, DY = 0) : Direct pixel plot using h_plot_one helper.
;;    - Horizontal    (DY = 0, DX != 0): Accelerated byte-aligned memory fill.
;;    - Vertical      (DX = 0, DY != 0): SMC-optimized 8-line scanline stepping.
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
;; Destroyed Register values:
;;    AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;    448 bytes (422 bytes routine + 26 bytes binding wrapper)
;;
;; Time Measures (Includes +34 us / +136 CPU cycles binding wrapper overhead):
;; (start code)
;;    Case / Coordinates                       | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Setup Overhead (routine + binding)       | -      | 218            | 872
;;    Single Point  (50,50) to (50,50) [Fast]  | 1      | 196            | 784
;;    Horizontal    (0,0)   to (100,0) [Fast]  | 101    | 810            | 3240
;;    Vertical      (0,0)   to (0,100) [Fast]  | 101    | 1730           | 6920
;;    Shallow Slope (0,0)   to (100,25)        | 101    | 11200          | 44800
;;    Diagonal 45°  (0,0)   to (100,100)       | 101    | 12800          | 51200
;;   ---------------------------------------------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;-------------------------------------------------------------------------------
;; MACROS
;;-------------------------------------------------------------------------------
;; DIV4_HL: HL = HL / 4 (Converts X pixel coordinate to X byte column 0..79)
;;   Execution time: [8 NOPs / 32 CPU cycles]
.macro DIV4_HL
    srl   h                       ;; [2] Shift H right
    rr    l                       ;; [2] Rotate L right through carry
    srl   h                       ;; [2] Shift H right second time
    rr    l                       ;; [2] Rotate L right second time (HL = HL / 4)
.endm

;; COLOR_PEN_FROM_B: color_pen = B * 4 (Pre-multiplied offset for color table)
;;   Execution time: [7 NOPs / 28 CPU cycles]
.macro COLOR_PEN_FROM_B
    ld    a, b                    ;; [1] A = color index (0-3)
    add   a, a                    ;; [1] A = color * 2
    add   a, a                    ;; [1] A = color * 4
    ld    (color_pen), a          ;; [4] Store pre-multiplied color index into SMC
.endm

;; FULL_COLOR: Generate solid byte with all 4 pixels set to color in D
;;   Execution time: [41 NOPs / 164 CPU cycles]
;;   Preserves: HL                    Destroys: A, B, C, DE
.macro FULL_COLOR
    push  hl                      ;; [4] Save VRAM address
    ld    a, (color_pen)          ;; [4] A = color * 4
    ld    c, a                    ;; [1] C = color * 4
    ld    h, #0                   ;; [2] H = 0
    ld    l, c                    ;; [1] L = color offset
    ld    de, #cpct_plotColorTable_M1 ;; [3] DE = color table base
    add   hl, de                  ;; [3] HL = &color[offset]
    ld    a, (hl)                 ;; [2] A = color byte for pixel 0
    ld    b, a                    ;; [1] B = pixel 0 color
    inc   hl                      ;; [2] Move to pixel 1
    ld    a, (hl)                 ;; [2] A = color byte for pixel 1
    or    b                       ;; [1] Combine pixel 0 and 1
    ld    b, a                    ;; [1] B = combined color
    inc   hl                      ;; [2] Move to pixel 2
    ld    a, (hl)                 ;; [2] A = color byte for pixel 2
    or    b                       ;; [1] Combine pixel 0, 1 and 2
    ld    b, a                    ;; [1] B = combined color
    inc   hl                      ;; [2] Move to pixel 3
    ld    a, (hl)                 ;; [2] A = color byte for pixel 3
    or    b                       ;; [1] Combine all 4 pixels into solid byte
    ld    d, a                    ;; [1] D = solid color byte
    pop   hl                      ;; [3] Restore VRAM address
.endm

;;-------------------------------------------------------------------------------
;; ENTRY POINT
;;-------------------------------------------------------------------------------
jp  normal_draw                      ;; [3] Jump to main entry and dispatch

;;-------------------------------------------------------------------------------
;; DATA SECTION
;;-------------------------------------------------------------------------------
.area _DATA

;; -- horizontal_draw workspace --
rb_off_start:  .db 0                  ;; Start pixel offset (0..3)
rb_off_end:    .db 0                  ;; End pixel offset (0..3)
rb_byte_start: .db 0                  ;; Start byte column (0..79)
rb_byte_end:   .db 0                  ;; End byte column (0..79)
rb_mid_count:  .db 0                  ;; Number of full intermediate bytes

;; -- common workspace --
screen_start:  .ds 2                  ;; VRAM start address (16-bit)

;; ============================================================================
;; SINGLE POINT FAST-PATH (X0 == X1 and Y0 == Y1)
;; ============================================================================
single_draw:
    COLOR_PEN_FROM_B              ;; [7] color_pen = color * 4

    ld    hl, (x0)                ;; [5] HL = X0 coordinate
    ld    a, l                    ;; [1] A = X0 low byte
    and   #3                      ;; [2] A = pixel index (0..3)
    ld    c, a                    ;; [1] C = pixel index for h_plot_one helper
    DIV4_HL                       ;; [8] HL = X0 / 4 (byte column)
    ld    c, l                    ;; [1] C = byte_offset
    ld    a, (y0_val)             ;; [4] A = Y0
    ld    b, a                    ;; [1] B = Y0
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM byte address
    call  h_plot_one              ;; [5] Plot pixel using unified helper
    jp    end_draw_line           ;; [3] Jump to binding end

;; ============================================================================
;; HORIZONTAL LINE FAST-PATH (Y0 == Y1)
;;      Input: HL = signed DX, B = color, (x0) = X0, (y0_val) = Y0
;; ============================================================================
horizontal_draw:
    COLOR_PEN_FROM_B              ;; [7] color_pen = color * 4

    ld    de, (x0)                ;; [5] DE = X0 coordinate
    add   hl, de                  ;; [3] HL = X1 = X0 + DX

    push  hl                      ;; [4] Save X1 on stack
    push  de                      ;; [4] Save X0 on stack
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [3] Compare X1 - X0
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
    DIV4_HL                       ;; [8] HL = start_byte
    ld    a, l                    ;; [1] A = start_byte
    ld    (rb_byte_start), a      ;; [4] Store start_byte

    ld    a, e                    ;; [1] A = end_x low byte
    and   #3                      ;; [2] A = end pixel offset (0..3)
    ld    (rb_off_end), a         ;; [4] Store end offset
    ex    de, hl                  ;; [1] HL = end_x
    DIV4_HL                       ;; [8] HL = end_byte
    ld    a, l                    ;; [1] A = end_byte
    ld    (rb_byte_end), a        ;; [4] Store end_byte

    ld    a, (rb_byte_start)      ;; [4] A = start_byte
    ld    c, a                    ;; [1] C = start_byte
    ld    a, (rb_byte_end)        ;; [4] A = end_byte
    sub   c                       ;; [1] A = end_byte - start_byte
    dec   a                       ;; [1] A = middle full bytes count
    ld    (rb_mid_count), a       ;; [4] Store middle count

    ld    a, (rb_byte_start)      ;; [4] A = start_byte
    ld    c, a                    ;; [1] C = start_byte
    ld    a, (y0_val)             ;; [4] A = Y0
    ld    b, a                    ;; [1] B = Y0
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM starting byte address

    ld    a, (rb_byte_start)      ;; [4] A = start_byte
    ld    c, a                    ;; [1] C = start_byte
    ld    a, (rb_byte_end)        ;; [4] A = end_byte
    cp    c                       ;; [1] Compare start_byte and end_byte
    jp    nz, h_multi             ;; [3] IF start_byte != end_byte THEN jump multi-byte

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
    FULL_COLOR                    ;; [41] D = solid color byte (HL preserved)

    ;; --- MIDDLE BYTES: Fast solid fill loop ---
    ld    a, (rb_mid_count)       ;; [4] A = middle bytes count
    or    a                       ;; [1] Check if 0
    jr    z, h_no_mid             ;; [2/3] IF 0 middle bytes THEN skip loop
    ld    b, a                    ;; [1] B = middle bytes counter
h_mid_loop:
    ld    (hl), d                 ;; [2] Write solid color byte directly to VRAM
    inc   hl                      ;; [2] Move to next byte column
    dec   b                       ;; [1] Decrement counter
    jr    nz, h_mid_loop          ;; [2/3] Loop until middle bytes filled
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
;; VERTICAL LINE FAST-PATH (X0 == X1) -- Fixed SMC & Single Loop
;;      Input: A = Y0, B = color, C = Y1, (x0) = X, (y0_val) = Y0
;; ============================================================================
vertical_draw:
    ;; 1. Order Y coordinates (Y0 <= Y1)
    cp    c                       ;; [1] Compare Y0 and Y1
    jr    c, v_order_ok           ;; [2/3] IF Y0 < Y1 THEN ordered
    jp    z, single_draw          ;; [3] IF Y0 == Y1 THEN single point
    ld    e, a                    ;; [1] Swap Y0 and Y1
    ld    a, c                    ;; [1] |
    ld    c, e                    ;; [1] |

v_order_ok:
    ;; 2. Calculate line height (pixels count = Y_end - Y_start + 1)
    ld    (v_ystart_op + 1), a    ;; [4] Store Y_start into SMC
    sub   c                       ;; [1] A = Y_start - Y_end
    neg                           ;; [1] A = Y_end - Y_start
    inc   a                       ;; [1] A = height in pixels
    ld    (v_count_op + 1), a     ;; [4] Store loop count into SMC

    COLOR_PEN_FROM_B              ;; [7] color_pen = color * 4

    ;; 3. Compute Mask and Color ONCE for X
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

    ;; 4. Compute initial VRAM start pointer
    ld    hl, (x0)                ;; [5] HL = X coordinate
    DIV4_HL                       ;; [8] HL = X / 4 (byte offset)
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

;; ============================================================================
;; HELPERS
;; ============================================================================

;; ----------------------------------------------------------------------------
;; h_plot_one: Plot single pixel (offset C) at VRAM address HL
;;   Input: HL = VRAM address, C = pixel index (0..3)
;;   Preserves: HL, C                 Destroys: A, B, DE
;; ----------------------------------------------------------------------------
h_plot_one:
    ld    e, c                    ;; [1] E = pixel index
    push  hl                      ;; [4] Save VRAM address
    ld    h, #0                   ;; [2] H = 0
    ld    l, c                    ;; [1] L = pixel index
    ld    de, #cpct_plotMasksTable_M1 ;; [3] DE = masks table base
    add   hl, de                  ;; [3] HL = &masks[pixel_index]
    ld    a, (hl)                 ;; [2] A = mask byte
    ld    b, a                    ;; [1] B = mask byte
    pop   hl                      ;; [3] Restore VRAM address
    ld    a, (hl)                 ;; [2] A = current VRAM byte
    and   b                       ;; [1] Apply mask to preserve background
    ld    b, a                    ;; [1] B = preserved background
    ld    a, (color_pen)          ;; [4] A = color * 4
    or    c                       ;; [1] A = color * 4 + pixel_index
    push  hl                      ;; [4] Save VRAM address
    ld    h, #0                   ;; [2] H = 0
    ld    l, a                    ;; [1] L = color offset
    ld    de, #cpct_plotColorTable_M1 ;; [3] DE = color table base
    add   hl, de                  ;; [3] HL = &color[offset]
    ld    a, (hl)                 ;; [2] A = pixel color byte
    pop   hl                      ;; [3] Restore VRAM address
    or    b                       ;; [1] Merge background + foreground pixel
    ld    (hl), a                 ;; [2] Write merged byte back to VRAM
    ret                           ;; [3] Return

;; ----------------------------------------------------------------------------
;; v_inner: Plot B vertical pixels downwards starting from HL (step DE = +0x0800)
;;   Background mask and color byte are constant (SMC patched).
;;   Input: HL = address, B = count, DE = #0x0800
;;   Preserves: DE                    Destroys: A, HL, BC
;; ----------------------------------------------------------------------------
v_inner:
    ld    a, (hl)                 ;; [2] A = current VRAM byte
v_mask=.+1
    and   #0x00                   ;; [2] Mask out background pixel (SMC patched)
v_col =.+1
    or    #0x00                   ;; [2] Insert foreground pixel color (SMC patched)
    ld    (hl), a                 ;; [2] Write updated byte back to VRAM
    add   hl, de                  ;; [3] Move HL to next scanline within row (+0x0800)
    dec   b                       ;; [1] Decrement pixel count
    jr    nz, v_inner             ;; [2/3] Loop if pixels remaining
    ret                           ;; [3] Return

;; ============================================================================
;; GENERIC BRESENHAM 
;; ============================================================================
normal_draw:
    ld    (screen_start), hl      ;; [5] Store VRAM base into SMC (screen_start)

    ex    de, hl                  ;; [1] HL = X0, DE = screen_base
    ld    (x0), hl                ;; [5] Save X0 coordinate into RAM
    pop   de                      ;; [3] DE = Y0 coordinate
    ld    a, e                    ;; [1] A = Y0 coordinate
    ld    (y0_val), a             ;; [4] Store initial Y0 into RAM
    ex    de, hl                  ;; [1] DE = X0, HL = Y0
    pop   hl                      ;; [3] HL = X1 coordinate
    sbc   hl, de                  ;; [3] HL = DX = X1 - X0 (Sets Z flag if DX == 0)
    ld    e, a                    ;; [1] E = Y0
    pop   bc                      ;; [3] B = color, C = Y1 (Z flag from sbc)
    jr    nz, .dx_nonzero         ;; [2/3] IF DX != 0 THEN jump .dx_nonzero

    ;; ---- DX == 0 case ----
    sub   c                       ;; [1] A = Y0 - Y1
    jp    z, single_draw          ;; [3] IF Y0 == Y1 (Single point DX=0, DY=0) THEN jump single_draw
    ld    a, e                    ;; [1] Restore A = Y0
    jp    vertical_draw           ;; [3] DX == 0 and DY != 0 -> Jump vertical_draw

.dx_nonzero:
    ;; ---- DX != 0 case ----
    sub   c                       ;; [1] A = Y0 - Y1
    jp    z, horizontal_draw      ;; [3] DY == 0 and DX != 0 -> Jump horizontal_draw
    COLOR_PEN_FROM_B              ;; [7] color_pen = color * 4

compute_dx:
    ld    b, #0x23                ;; [2] B = opcode 'inc iy' (+1 step X)
    ld    a, #0x0F                ;; [2] A = opcode 'rrca' (SX = +1)
    ld    (shift_bg_mask), a      ;; [4] Store shift opcode into SMC
    bit   7, h                    ;; [2] Check sign of DX
    jr    z, compute_dy           ;; [2/3] IF DX > 0 THEN jump compute_dy
    ld    b, #0x2B                ;; [2] B = opcode 'dec iy' (-1 step X)
    ld    a, #0x07                ;; [2] A = opcode 'rlca' (SX = -1)
    ld    (shift_bg_mask), a      ;; [4] Store shift opcode into SMC
    xor   a                       ;; [1] Clear A
    sub   l                       ;; [1] HL = -DX
    ld    l, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   h                       ;; [1] |
    ld    h, a                    ;; [1] |
compute_dy:
    ld    (dx), hl                ;; [4] Save absolute DX into SMC
    ld    a, b                    ;; [1] A = SX step opcode
    ld    (add_sx), a             ;; [4] Store SX opcode into SMC
    ld    a, c                    ;; [1] A = Y1
    sub   e                       ;; [1] A = DY = Y1 - Y0
compute_sy:
    ld    b, #0x3C                ;; [2] B = opcode 'inc a' (SY = +1)
    jr    nc, compute_err         ;; [2/3] IF Y1 >= Y0 THEN jump compute_err
    neg                           ;; [1] A = -DY
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
    ld    (pixel_num), hl         ;; [5] Store pixel count into SMC
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
    ld__ixh_b                     ;; [2] IX = ERR
    ld__ixl_c                     ;; [2] |
x0=.+1
    ld    hl, #0000               ;; [3] HL = X0 (SMC loaded)
    push  hl                      ;; [4] Save X0 on stack
    pop   iy                      ;; [4] IY = X0 (IY = current X)

compute_start_vmem:
    push  hl                      ;; [4] Save X0 on stack
    DIV4_HL                       ;; [8] HL = X0 / 4
    ld    c, l                    ;; [1] C = X_byte
    ld    a, c                    ;; [1] A = X_byte
    ld    (prev_x), a             ;; [4] Store initial prev_x
    ld    a, e                    ;; [1] A = Y0
    ld    (prev_y), a             ;; [4] Store initial prev_y
    ld    b, a                    ;; [1] B = Y0
    ld    de, (screen_start)      ;; [5] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM address of (X_byte, Y0)

    ld    (screen_ptr), hl        ;; [5] Store initial screen pointer
    pop   hl                      ;; [4] Restore X0 from stack
    ld    a, l                    ;; [1] A = X0 low byte
    and   #3                      ;; [2] A = pixel offset (0..3)
    ld    c, a                    ;; [1] C = pixel offset
    ld    hl, #cpct_plotMasksTable_M1 ;; [3] HL = masks table base
    ld    b, #00                  ;; [2] B = 0
    add   hl, bc                  ;; [3] HL = &masks[pixel_offset]
    ld    a, (hl)                 ;; [2] A = initial background mask
    ld    (saved_bg_mask), a      ;; [4] Store background mask into SMC

;; --- MAIN LOOP ---
loop_line_pixel:
    ld__a_iyl                     ;; [2] A = IYL (current X low byte)
    ld    l, a                    ;; [1] L = X low byte
    and   #3                      ;; [2] A = pixel offset (0..3)
    ld    e, a                    ;; [1] E = pixel offset
    ld__a_iyh                     ;; [2] A = IYH (current X high byte)
    ld    h, a                    ;; [1] H = X high byte (HL = current X)
    DIV4_HL                       ;; [8] L = X_byte
    ld    c, l                    ;; [1] C = X_byte
y0_val=.+1
    ld    b, #00                  ;; [2] B = current Y (SMC loaded)
screen_ptr=.+1
    ld    hl, #0000               ;; [3] HL = current VRAM pointer (SMC loaded)
test_x_coord:
prev_x=.+1
    ld    a, #0x00                ;; [2] A = prev_x (SMC loaded)
    cp    c                       ;; [1] Compare prev_x with current X_byte
    jr    z, test_y_coord         ;; [2/3] IF no change THEN jump test_y_coord
    ld    a, c                    ;; [1] Update prev_x
    ld    (prev_x), a             ;; [4] Store updated prev_x
    jr    nc, move_left           ;; [2/3] IF X_byte decreased THEN jump move_left
move_right:
    inc   hl                      ;; [2] Move VRAM pointer right 1 byte
    jp    test_y_coord            ;; [3] Jump test_y_coord
move_left:
    dec   hl                      ;; [2] Move VRAM pointer left 1 byte
test_y_coord:
prev_y=.+1
    ld    a, #0x00                ;; [2] A = prev_y (SMC loaded)
    cp    b                       ;; [1] Compare prev_y with current Y
    jr    z, save_screen_ptr      ;; [2/3] IF no change THEN skip VRAM update
    ld    a, b                    ;; [1] Update prev_y
    ld    (prev_y), a             ;; [4] Store updated prev_y
    jr    nc, move_up             ;; [2/3] IF Y decreased THEN jump move_up
move_down:
    ld    bc, #0x0800             ;; [3] BC = scanline offset (+0x0800)
    add   hl, bc                  ;; [3] HL += 0x0800
    ld    a, h                    ;; [1] A = H
    and   #0x38                   ;; [2] Check 8-line block boundary
    jr    nz, save_screen_ptr     ;; [2/3] IF not boundary THEN jump save_screen_ptr
    ld    bc, #0xC050             ;; [3] BC = character row correction (+0xC050)
    add   hl, bc                  ;; [3] HL += 0xC050
    jp    save_screen_ptr         ;; [3] Jump save_screen_ptr
move_up:
    ld    a, h                    ;; [1] A = H
    and   #0x38                   ;; [2] Check if line 0 of character row
    jr    z, move_up_row          ;; [2/3] IF line 0 THEN jump move_up_row
    ld    bc, #0xF800             ;; [3] BC = previous scanline offset (-0x0800)
    add   hl, bc                  ;; [3] HL += 0xF800
    jp    save_screen_ptr         ;; [3] Jump save_screen_ptr
move_up_row:
    ld    bc, #0x37B0             ;; [3] BC = previous character row correction (-0xC050)
    add   hl, bc                  ;; [3] HL += 0x37B0
save_screen_ptr:
    ld    (screen_ptr), hl        ;; [5] Save updated screen pointer into SMC
plot_pixel:
    ld    c, e                    ;; [1] C = pixel offset
    ld    a, (hl)                 ;; [2] A = current VRAM byte
saved_bg_mask=.+1
    and   #0x00                   ;; [2] Apply background mask (SMC patched)
    ld    b, a                    ;; [1] B = preserved background
color_pen=.+1
    ld    a, #00                  ;; [2] A = color * 4 (SMC patched)
    or    c                       ;; [1] A = color * 4 + pixel offset
    ld    de, #cpct_plotColorTable_M1 ;; [3] DE = color table base
    add   a, e                    ;; [1] A = E + offset
    ld    e, a                    ;; [1] DE = &color[offset]
    ld    a, (de)                 ;; [2] A = pixel color byte
    or    b                       ;; [1] Merge background + foreground
    ld    (hl), a                 ;; [2] Write byte to VRAM
err_2_compute:
    ld__d_ixh                     ;; [2] D = IXH
    ld__e_ixl                     ;; [2] E = IXL (DE = ERR)
    sla   e                       ;; [2] Shift E left
    rl    d                       ;; [2] Rotate D left through carry (DE = e2 = 2 * ERR)
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
    ld    a, (saved_bg_mask)      ;; [4] A = saved_bg_mask
shift_bg_mask:
    .db   #0x00                   ;; [1] SMC: 'rrca' or 'rlca'
    ld    (saved_bg_mask), a      ;; [4] Save updated rotated mask
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
    ld    a, (y0_val)             ;; [4] A = Y0
add_sy_op:
    .db   #0x00                   ;; [1] SMC: 'inc a' or 'dec a'
    ld    (y0_val), a             ;; [4] Save updated Y0
last_pixel:
pixel_num=.+1
    ld    hl, #0000               ;; [3] HL = pixel_num (SMC loaded)
    dec   hl                      ;; [2] Decrement pixel count
    ld    (pixel_num), hl         ;; [5] Update pixel_num
    ld    a, h                    ;; [1] Check if pixel_num == 0
    or    l                       ;; [1] |
    jp    nz, loop_line_pixel     ;; [2/3] IF pixels remaining THEN loop

end_draw_line:
    ;; Return in binding wrapper