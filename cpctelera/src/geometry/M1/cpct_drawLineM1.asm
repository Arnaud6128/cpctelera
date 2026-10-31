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
.globl cpct_getScreenPtr_asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawLineM1
;;
;;    Draws a straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using a compact generic Bresenham algorithm.
;;    Size optimized version, intended for user interface drawing. Use
;;    <cpct_drawLineM1_f> when speed matters (3D, many lines per frame).
;;
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
;; Compact Bresenham Architecture:
;;    1. One single loop for all directions, driven by the major axis:
;;
;;       - Major / minor axis steps are small subroutines (X+1, X-1, Y+1, Y-1)
;;         called through 2 SMC patched CALL instructions.
;;       - Horizontal and vertical lines and single points are handled by the
;;         generic loop (no special case).
;;    2. Pixel write with a constant solid color byte: (VRAM ^ solid) & mask ^ solid,
;;       so that only the pixel mask is rotated when stepping in X.
;;    3. Pixel counter split in IXL / IXH (8-bit decrement in the loop).
;;
;; Known limitations:
;;
;;  * This function will not work from ROM, as it uses self-modifying code.
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    271 bytes (240 bytes routine + 5 bytes data + 26 bytes binding wrapper)
;;
;; Time Measures (Measured from C, including call and binding wrapper overhead):
;; (start code)
;;    Case / Coordinates                       | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Single Point  (50,50) to (50,50)         | 1      | ~450           | ~1800
;;    Horizontal    (0,0)   to (100,0)         | 101    | ~4690          | ~18760
;;    Vertical      (0,0)   to (0,100)         | 101    | ~5150          | ~20600
;;    Shallow Slope (0,0)   to (100,25)        | 101    | ~5410          | ~21640
;;    Diagonal 45°  (0,0)   to (100,100)       | 101    | ~7605          | ~30420
;;    Steep Slope   (0,0)   to (25,100)        | 101    | ~5760          | ~23040
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

;;-------------------------------------------------------------------------------
;; DATA SECTION
;;-------------------------------------------------------------------------------
.area _DATA
screen_start:   .ds 2          ;; Base VRAM address (16-bit)
x0_val:         .dw 0          ;; X0 coordinate (RAM storage)
y0_val:         .db 0          ;; Y0 coordinate (RAM storage)

;;-------------------------------------------------------------------------------
;; CODE SECTION
;;-------------------------------------------------------------------------------
.area _CODE
    ld    (screen_start), hl      ;; [5] Store base VRAM address into RAM
    ex    de, hl                  ;; [1] HL = X0 coordinate, DE = base VRAM address
    ld    (x0_val), hl            ;; [5] Save X0 coordinate into RAM
    pop   de                      ;; [3] E = Y0 coordinate
    ld    a, e                    ;; [1] A = Y0 coordinate
    ld    (y0_val), a             ;; [4] Store Y0 into RAM
    ex    de, hl                  ;; [1] DE = X0, HL = Y0
    pop   hl                      ;; [3] HL = X1 coordinate
    or    a                       ;; [1] Clear carry flag
    sbc   hl, de                  ;; [4] HL = signed DX = X1 - X0
    pop   bc                      ;; [3] B = color, C = Y1

    ;; ---- B = solid color byte (0 -> 0x00, 1 -> 0xF0, 2 -> 0x0F, 3 -> 0xFF) ----
    ld    a, b                    ;; [1] A = color index (0-3)
    rrca                          ;; [1] Carry = color bit 0 (LSB)
    sbc   a, a                    ;; [1] A = 0xFF if LSB set, 0x00 otherwise
    and   #0xF0                   ;; [2] A = LSB bits of the 4 pixels
    bit   1, b                    ;; [2] Test color bit 1 (MSB)
    jr    z, solid_ok             ;; [2/3] IF MSB not set THEN solid ready
    or    #0x0F                   ;; [2] A |= MSB bits of the 4 pixels
solid_ok:
    ld    b, a                    ;; [1] B = solid color byte

    ld    a, (y0_val)             ;; [4] A = Y0
    sub   c                       ;; [1] A = Y0 - Y1 (Carry = Y0 < Y1)

;; ============================================================================
;; GENERIC BRESENHAM (all directions, horizontal and vertical lines, single points)
;; ============================================================================
    ;; ---- SY step routine and |DY| ----
    ld    de, #step_up            ;; [3] DE = Y-1 step (Y0 >= Y1)
    jr    nc, dy_ok               ;; [2/3] IF Y0 >= Y1 THEN A = |DY|
    ld    de, #step_down          ;; [3] DE = Y+1 step
    neg                           ;; [2] A = |DY| = Y1 - Y0
dy_ok:
    ld    c, a                    ;; [1] C = |DY|
    push  de                      ;; [4] Save Y step routine

    ;; ---- SX step routine and |DX| ----
    ld    de, #step_right         ;; [3] DE = X+1 step (DX >= 0)
    bit   7, h                    ;; [2] Check sign of DX
    jr    z, dx_ok                ;; [2/3] IF DX >= 0 THEN HL = |DX|
    ld    de, #step_left          ;; [3] DE = X-1 step
    xor   a                       ;; [1] HL = -DX
    sub   l                       ;; [1] |
    ld    l, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   h                       ;; [1] |
    ld    h, a                    ;; [1] HL = |DX|
dx_ok:

    ;; ---- Major / minor axis: gentle if |DX| >= |DY| ----
    ld    a, h                    ;; [1] IF |DX| >= 256
    or    a                       ;; [1] |
    jr    nz, axis_ok             ;; [2/3] THEN gentle slope
    ld    a, l                    ;; [1] A = |DX|
    cp    c                       ;; [1] Compare |DX| and |DY|
    jr    nc, axis_ok             ;; [2/3] IF |DX| >= |DY| THEN gentle slope
    ld    l, c                    ;; [1] Steep: HL = major = |DY| (H = 0)
    ld    c, a                    ;; [1] C = minor = |DX|
    ex    de, hl                  ;; [1] Swap major / minor step routines
    ex    (sp), hl                ;; [6] |
    ex    de, hl                  ;; [1] |
axis_ok:
    ;; HL = major, C = minor, DE = major step routine, (SP) = minor step routine
    ld    (major_call + 1), de    ;; [6] Patch major axis step call
    pop   de                      ;; [3] DE = minor step routine
    ld    (minor_call + 1), de    ;; [6] Patch minor axis step call

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

    ;; ---- Error deltas: +2*minor always, -2*major on minor step, Err0 = 2*minor - major ----
    ex    de, hl                  ;; [1] DE = major
    ld    h, #0                   ;; [2] HL = minor
    ld    l, c                    ;; [1] |
    add   hl, hl                  ;; [3] HL = 2*minor (Carry = 0)
    ld    (nostep_delta + 1), hl  ;; [5] Patch 2*minor delta
    sbc   hl, de                  ;; [4] HL = Err0 = 2*minor - major
    push  hl                      ;; [4] Save initial error
    xor   a                       ;; [1] HL = -2*major
    ld    h, a                    ;; [1] |
    ld    l, a                    ;; [1] |
    sbc   hl, de                  ;; [4] |
    add   hl, hl                  ;; [3] |
    ld    (step_delta + 1), hl    ;; [5] Patch -2*major delta

    ;; ---- DE = VRAM address of (X0, Y0), B = pixel mask, C = solid color ----
    push  bc                      ;; [4] Save solid color byte (B)
    ld    hl, (x0_val)            ;; [5] HL = X0 coordinate
    ld    a, l                    ;; [1] A = pixel offset (0..3)
    and   #3                      ;; [2] |
    push  af                      ;; [4] Save pixel offset
    DIV4_HL                       ;; [8] Convert X0 to byte column
    ld    c, l                    ;; [1] C = X_byte
    ld    a, (y0_val)             ;; [4] B = Y0
    ld    b, a                    ;; [1] |
    ld    de, (screen_start)      ;; [6] DE = base VRAM address
    call  cpct_getScreenPtr_asm   ;; [5] HL = VRAM address
    ex    de, hl                  ;; [1] DE = VRAM address
    pop   af                      ;; [3] A = pixel offset
    pop   bc                      ;; [3] B = solid color byte
    ld    c, b                    ;; [1] C = solid color byte
    ld    b, #0x77                ;; [2] B = mask of pixel 0
    or    a                       ;; [1] IF pixel offset != 0
    jr    z, mask_ok              ;; [2/3] |
mask_rot:
    rrc   b                       ;; [2] THEN rotate mask to pixel offset
    dec   a                       ;; [1] |
    jr    nz, mask_rot            ;; [2/3] |
mask_ok:
    pop   hl                      ;; [3] HL = initial error

line_loop:
    ld    a, (de)                 ;; [2] Read current VRAM byte
    xor   c                       ;; [1] (VRAM ^ solid) & mask ^ solid
    and   b                       ;; [1] |
    xor   c                       ;; [1] |
    ld    (de), a                 ;; [2] Write updated byte back to VRAM
major_call:
    call  #0x0000                 ;; [5] SMC: step along major axis
    bit   7, h                    ;; [2] Test if Err < 0
    jr    nz, nostep              ;; [2/3] IF Err < 0 THEN no minor step
minor_call:
    call  #0x0000                 ;; [5] SMC: step along minor axis
    push  bc                      ;; [4] Err -= 2*major
step_delta:
    ld    bc, #0x0000             ;; [3] SMC: -2*major
    add   hl, bc                  ;; [3] |
    pop   bc                      ;; [3] |
nostep:
    push  bc                      ;; [4] Err += 2*minor
nostep_delta:
    ld    bc, #0x0000             ;; [3] SMC: 2*minor
    add   hl, bc                  ;; [3] |
    pop   bc                      ;; [3] |
    dec__ixl                      ;; [2] Decrement pixel counter low byte
    jr    nz, line_loop           ;; [2/3] IF pixels remaining in round THEN loop
    dec__ixh                      ;; [2] Decrement pixel counter high byte
    jr    nz, line_loop           ;; [2/3] IF rounds remaining THEN loop
    jr    end_draw_line           ;; [3] Line completed

;; ----------------------------------------------------------------------------
;; Axis step routines (DE = VRAM pointer, B = pixel mask, destroy A)
;; ----------------------------------------------------------------------------
step_right:
    rrc   b                       ;; [2] Next pixel mask (Carry = 0 on byte wrap)
    ret   c                       ;; [2/4] IF no byte wrap THEN done
    inc   de                      ;; [2] Move DE to next byte column
    ret                           ;; [3]
step_left:
    rlc   b                       ;; [2] Previous pixel mask (Carry = 0 on byte wrap)
    ret   c                       ;; [2/4] IF no byte wrap THEN done
    dec   de                      ;; [2] Move DE to previous byte column
    ret                           ;; [3]
step_down:
    ld    a, d                    ;; [1] Move DE 1 scanline down (+0x0800)
    add   a, #0x08                ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check 8-line character block boundary
    ret   nz                      ;; [2/4] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0xC050 (next character row)
    add   a, #0x50                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0xC0                ;; [2] |
    ld    d, a                    ;; [1] |
    ret                           ;; [3]
step_up:
    ld    a, d                    ;; [1] Move DE 1 scanline up (-0x0800)
    sub   #0x08                   ;; [2] |
    ld    d, a                    ;; [1] |
    and   #0x38                   ;; [2] Check if we left line 0 of a character row
    cp    #0x38                   ;; [2] |
    ret   nz                      ;; [2/4] IF inside block THEN done
    ld    a, e                    ;; [1] DE += 0x3FB0 (line 7 of previous character row)
    add   a, #0xB0                ;; [2] |
    ld    e, a                    ;; [1] |
    ld    a, d                    ;; [1] |
    adc   a, #0x3F                ;; [2] |
    ld    d, a                    ;; [1] |
    ret                           ;; [3]

;; ============================================================================
;; END OF ROUTINE (Falls through to restore_iy in binding wrapper .s)
;; ============================================================================
end_draw_line:
