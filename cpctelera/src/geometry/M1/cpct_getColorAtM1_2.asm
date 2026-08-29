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

    ld c,(hl)   ; Get screen octet

    sub #3              ; check if last subpixel on right
    neg                 ; a = 3 - b
    jr z,computeColor   ; if last, jump

    ld b,a              ; for loop
subpixel_loop:
    srl c               ; shift screen octet to the right
    djnz subpixel_loop  ; until last subpixel on right
computeColor:
    ld a,c        ; let's decode screen value
    and #0x11     ; and 0b00010001 to mask right subpixel

    ld l,#0     ; Future color
    rra         ; Get High bit of color from bit 0 in carry (after the AND #11 Carry=0 so bit 7 = 0)
    rl l        ; Set bit 0 of l with carry (carry = 0 after)
    rl l        ; Move it to bit 1 because it is high bit
check_low_bit:
    or a        ; Here a is either 4 or 0... So check if 0
    jr z,end_getColorAt ; skip if 0
    inc l      ; Put low bit of color in l 
end_getColorAt:     ; l = output color
    ld a,l          ; stdcall_1 convention so asm also...
    ret
