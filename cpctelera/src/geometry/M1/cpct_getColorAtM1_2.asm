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

;;          HL = Adress of octet to test
;;          A  = SubPixel to test in octet (0..3)
;;

    ld  c,(hl)          ;; Get screen octet

    or  a               ;;; Check if subpixel is 0, if so start the check
    jr  z,computeColor  ;; if last, jump

    ld  b,a             ;; for loop
subpixel_loop:
    sla c               ;; shift screen octet to the left
    djnz subpixel_loop  ;; until last subpixel on left
computeColor:
    ld  a,c             ;; let's decode screen value
    and #0x88           ;; and 0b10001000 to mask left subpixel

    ld  l,#0            ;; Future color
    rla                 ;; Get Low bit of color from bit 7 in carry 
                        ;; (after the AND #88 Carry=0 so bit 0 = 0)
    rl  l               ;; Set bit 0 of l using carry (carry = 0 after)
                        ;; l = low bit of color
;; Check high bit of color
    or  a               ;; Here a is either 0x10 or 0... So check if 0
    jr  z,end_getColorAt  
    inc l               ;; Add 2 to l to set high bit of color
    inc l               ;;  
end_getColorAt:         ;; l = output color
    ld  a,l             ;; stdcall_1 convention uses a, so asm also...
    ret
