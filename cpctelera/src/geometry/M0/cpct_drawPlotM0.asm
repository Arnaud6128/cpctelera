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
.module cpct_geometry

.globl cpct_pen2twoPixelM0_table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawPlotM0
;;
;;    Draws a single pixel on screen in Mode 0 (160x200, 16 colors) at specified
;;    coordinates.
;;
;; C Definition:
;;    void cpct_drawPlotM0(u8* screen_start, u16 x, u8 y, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B DE) screen_start - Base VRAM memory address (typically 0xC000)
;;   (2B HL) x            - X coordinate in pixels (0-159)
;;   (1B C)  y            - Y coordinate in pixels (0-199)
;;   (1B B)  color        - Pen color index (0-15)
;;
;; Assembly call:
;;    > call cpct_drawPlotM0_asm
;;
;; Requirements and limitations:
;;   * Coordinates must stay within Mode 0 screen bounds (X: 0-159, Y: 0-199).
;;   * Requires `cpct_pen2twoPixelM0_table` (16 bytes, PEN to 2 pixels byte).
;;
;; Details:
;;    In Mode 0, a byte holds 2 pixels: pixel 0 (left) uses bits 7, 5, 3, 1
;;    and pixel 1 (right) uses bits 6, 4, 2, 0. The pixel color bits are taken
;;    from the 2-pixels byte of the PEN, masked with the selected pixel bits.
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    ASM routine - 50 bytes
;;      C routine - 54 bytes
;;    (+16 bytes for cpct_pen2twoPixelM0_table)
;;
;; Time Measures:
;; (start code)
;;    Case      | microSecs (us) | CPU Cycles
;; ------------------------------------------
;;  ASM binding |      ~79       |   ~316
;; ------------------------------------------
;;   C binding  |      ~90       |   ~360
;; ------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; 1. Pixel selection bits from X parity
    ld    a, #0xAA        ;; [2] A = pixel 0 bits (7, 5, 3, 1)
    srl   l               ;; [2] L = X_byte coordinate (0-79), Carry = pixel index
    jr    nc, sel_ok      ;; [2/3] IF pixel 0 THEN selection ready
    rrca                  ;; [1] A = pixel 1 bits (6, 4, 2, 0) = 0x55
sel_ok:
    ld    h, a            ;; [1] H = pixel selection bits

    ;; 2. Pixel color bits = 2-pixels PEN byte & selection
    push  hl              ;; [4] Save selection (H) and X_byte (L)
    ld    a, b            ;; [1] A = PEN (0-15)
    add   a, #<cpct_pen2twoPixelM0_table ;; [2] HL = &cpct_pen2twoPixelM0_table[PEN]
    ld    l, a            ;; [1] |
    adc   a, #>cpct_pen2twoPixelM0_table ;; [2] |
    sub   l               ;; [1] |
    ld    h, a            ;; [1] |
    ld    b, (hl)         ;; [2] B = 2-pixels PEN byte
    pop   hl              ;; [3] H = selection, L = X_byte
    ld    a, h            ;; [1] B = pixel color bits
    and   b               ;; [1] |
    ld    b, a            ;; [1] |
    ld    a, h            ;; [1] A = background mask (other pixel bits)
    cpl                   ;; [1] |
    push  af              ;; [4] Save background mask

    ;; 3. Calculate VRAM pointer (C = Y, L = X_byte)
    push  de              ;; [4] Save screen_start to stack
    ld    e, l            ;; [1] E = X_byte
    ld    a, c            ;; [1] rA = Y-Coordinate
    and   #0x07           ;; [2] /
    ld    h, a            ;; [1] \ rH = Y % 8
    xor   c               ;; [1] / rA = Y and #0xF8
    ld    l, a            ;; [1] \ rL = 8*int(Y/8)
    rrca                  ;; [1] / rA' = 2*int(Y/8)
    rrca                  ;; [1] \
    add   a, l            ;; [1] / rL = 10*int(Y/8)
    ld    l, a            ;; [1] \
    add   hl, hl          ;; [3] / rHL' = 8*rHL = 2048*L + 80*R
    add   hl, hl          ;; [3] |
    add   hl, hl          ;; [3] \
    ld    d, #00          ;; [2] / rHL' = rHL + X_byte
    add   hl, de          ;; [3] \
    pop   de              ;; [3] DE = Screen start address
    add   hl, de          ;; [3] rHL' = rHL + screen_start

    ;; 4. Clear target pixel and inject its color bits
    pop   af              ;; [3] A = background mask
    and   (hl)            ;; [2] A = Screen byte with target pixel cleared
    or    b               ;; [1] Merge new pixel color bits
    ld    (hl), a         ;; [2] Write finalized byte back into VRAM

    ret                   ;; [3] Return to caller
