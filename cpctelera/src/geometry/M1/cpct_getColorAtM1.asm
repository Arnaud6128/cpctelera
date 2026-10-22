;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Xavier Jollet (@SagaDS)
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
;; Function: cpct_getColorAtM1
;;
;;    Get INK color of one pixel in Mode 1 (320x200, 4 colors).
;;
;; C Definition:
;;      u8  cpct_getColorAtM1 (u8* vmem, u16 x, u16 y) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B HL) vmem       - Base VRAM memory address (typically 0xC000)
;;   (2B DE) x          - X coordinate (0-319 no checks)
;;   (2B BC) y          - Y coordinate (0-199 no checks)
;;
;; Return value:
;;   (1B A) outCol      - Ink color of pixel (0..3)
;;
;; Assembly call:
;;    > call cpct_getColorAtM1_asm 
;;
;; Destroyed Register values:
;;          AF, BC, DE, HL
;;
;; Comment
;;  Uses cpct_getScreenPtr_asm (30us - 18 octets)
;;  Uses self modifying code, cannot be used in ROM
;;
;; (start code)
;; Required memory:
;;    44 bytes (41 bytes core routine + 3 bytes binding wrapper)
;;
;; Time Measures (including cpct_getScreenPtr_asm 30us) (add +10 us for c binding wrapper):
;;    Case                               | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Get any color on a subPixel 0      | 80             | 320
;;    Get any color on a subPixel 3      | 83             | 332
;; (end code)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ld      a,e                     ;; [1] a = low X
    and     #0x03                   ;; [2] Keep only the 2 least significant bits of X0 : subPixel

    push    af                      ;; [4] save subpixel AND Z Flag for subpixel 0 if needed
    srl     d                       ;; [2] d can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
    rr      e                       ;; [2] rotate e once with carry from d
    srl     e                       ;; [2] Now e is the byte offset in the line (0-79)
    ld      b, c                    ;; [1] b = Y
    ld      c, e                    ;; [1] c = X in bytes
    ex      de,hl                   ;; [1] de = SCREEN_ADRESS
    call    cpct_getScreenPtr_asm   ;; [5] HL = Current adress
    pop     bc                      ;; [3] retrieve subpixel in b

    ld      a,#3                    ;; [2] Set a to max subpixel
    sub     b                       ;; [1] a = 3 - subpixel (0..3) = number of rlca to perform
    ld      (smc_jpoverrlca),a      ;; [4] Modifies the JR reaching
    ld      a,(hl)                  ;; [2] Get screen octet
smc_jpoverrlca=.+1
    jr      computeColor            ;; [3] Skip rotations for subpixel 0 (SMC)
    rlca                            ;; [1] Rotate octet left to align the selected pixel
    rlca                            ;; [1] Rotate octet left to align the selected pixel
    rlca                            ;; [1] Rotate octet left to align the selected pixel
computeColor:
    and     #0x88                   ;; [2] and 0b10001000 to mask subpixel 0

    ld      l,#0                    ;; [2] Future color
    rla                             ;; [1] Move octet bit 7 to carry and bit 3 to bit 4
    rl      l                       ;; [2] Transfer bit 7 to color bit 0 (LSB of color)
    rrca                            ;; [1] Move MSB of screen pixel from bit 4 to bit 1
    rrca                            ;; [1]
    rrca                            ;; [1]
    or      l                       ;; [1] Combine both color bits into A
    ret                             ;; [3] returns
