;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
.module cpct_video
  
;;
;; C bindings for <cpct_getScreenPtr>
;;
;;   17 microSecs, 7 bytes
;;
_cpct_getScreenPtr::
    ;; Get parameters from HL registers and stack (16 + (8 + 8) bits), with __sdcccall(1) convention   
    ld d, h   ;; [1] DE = HL = Pointer to start of screen memory
    ld e, l   ;; [1]
   
    pop  af   ;; [3] AF = Return Address
    pop  bc   ;; [3] B = y coordinate in bytes, C = x coordinate in bytes
    push af   ;; [4] Put returning address in the stack again
              ;;      as this function uses __z88dk_callee convention

.include /cpct_getScreenPtr.asm/

    ex   de, hl ;; [1] HL <-> DE -> return in DE with __sdcccall(1)
	ret         ;; [3] return HL = Pointer to the video buffer at (X,Y) byte coordinates