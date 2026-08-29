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


    ld a,e      ; a = low X
    and #0x03	; Keep only the 2 least significant bits of X0 : subPixel

    push af     ; save subpixel 

    srl d       ; d can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
    rr  e       ; rotate e once with carry from d
    srl e       ;; Now e is the byte offset in the line (0-79)

    ld b, c     ; b = Y
    ld c, e     ; c = X in bytes

    ex de,hl    ; de = SCREEN_ADRESS

    call cpct_getScreenPtr_asm    ; HL = Current adress

    pop af      ; retrieve subpixel in a
