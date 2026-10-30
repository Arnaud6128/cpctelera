;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine
;;  Copyright (C) 2026 Xavier Jollet (@SagaDS)
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_getColorAtM0
;;
;;    Get the pen color of one pixel in Mode 0 (160x200, 16 colors).
;;
;; C Definition:
;;      u8  cpct_getColorAtM0 (u8* vmem, u16 x, u16 y) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B HL)    vmem - Base VRAM memory address (typically 0xC000)
;;   (2B DE)    x    - E = X coordinate (0-159 no checks)
;;   (2B Stack) y    - Y coordinate (0-199 no checks)
;;
;; Return value:
;;   (1B L) outCol   - Pen color of pixel (0..15)
;;                     A contains also the pen color if needed
;;
;; Assembly call:
;;    > call cpct_getColorAtM0_asm
;;       HL = VMem , E = X, C = Y
;;
;; Destroyed Register values:
;;          AF, BC, DE, HL
;;
;; Comment
;;  Uses cpct_getScreenPtr_asm
;;
;; (start code)
;; Code size
;;   33 bytes + 3 bytes of c cbinding
;;
;; Total time (+10 c binding):
;;    Case                               | NOP
;;   -----------------------------------------------
;;    Subpixel 0 (taken JR)              | 73
;;    Subpixel 1 (JR + RLCA)             | 73
;; (end code)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.globl cpct_getScreenPtr_asm

   ;; As X < 160  Shift right to the byte offset; carry selects subpixel 1.
   srl      e                       ;; [2] E = X / 2 (0..79), carry = X % 2 = subpixel (0..1)
   push     af                      ;; [4] Save carry to select the pixel

   ld      b, c                     ;; [1] b = Y
   ld      c, e                     ;; [1] c = X in bytes
   ex      de,hl                    ;; [1] de = SCREEN_ADRESS
   call    cpct_getScreenPtr_asm    ;; [5] HL = Current adress

   pop     af                       ;; [3] retrieve C flag
   ld      a,(hl)                   ;; [2] Get screen octet
   jr      nc,computeColor          ;; [2/3] Subpixel 0 is already aligned
   rlca                             ;; [1] Align subpixel 1 with subpixel 0
computeColor:
   and     #0xAA                    ;; [2] A = b7 0  b5 0  b3 0  b1 0  CF = 0
   ;; Need to compute A = 0  0  0  0  b1 b5 b3 b7
   ld      l,#0                     ;; [2] L = 0  0  0  0  0  0  0  0  CF = 0    Need an empty register
   rla                              ;; [1] A = 0  b5 0  b3 0  b1 0  0  CF = b7   Rotate with carry
   rl      l                        ;; [2] L = 0  0  0  0  0  0  0  b7 CF = 0    Rotate with carry   L = 0 0 0 b7 nibble
   rla                              ;; [1] A = b5 0  b3 0  b1 0  0  0  CF = 0    Rotate with carry
   ld      c,a                      ;; [1] C = b5 0  b3 0  b1 0  0  0  CF = 0    Store b1 in C       C = b1 0 0 0 nibble
   rla                              ;; [1] A = 0  b3 0  b1 0  0  0  0  CF = b5   Rotate with carry   temporisation of b5 for b3
   rla                              ;; [1] A = b3 0  b1 0  0  0  0  b5 CF = 0    Rotate with carry   insert b5 before b3 rotate
   rlca                             ;; [1] A = 0  b1 0  0  0  0  b5 b3 CF = b3   Rotate copy carry   rotate b3 after b5
   rlca                             ;; [1] A = b1 0  0  0  0  b5 b3 0  CF = 0    Rotate copy carry   A = 0  b5 b3 0  nibble
   or      l                        ;; [1] A = b1 0  0  0  0  b5 b3 b7 CF = 0    Add b7 to A         A = 0  b5 b3 b7 nibble
   or      c                        ;; [1] A = 15 0  b3 0  b1 b5 b3 b7 CF = 0    Add b1 to A         A = b1 b5 b3 b7 nibble
   and     #0x0F                    ;; [2] A = 0  0  0  0  b1 b5 b3 b7 CF = 0    Clean other bits    A = b1 b5 b3 b7 = Pen color
   ld      l,a                      ;; [1] L = Pen color

   ret                              ;; [3] returns
