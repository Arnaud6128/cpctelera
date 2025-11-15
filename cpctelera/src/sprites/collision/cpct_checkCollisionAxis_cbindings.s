;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2025 CPCtelera - ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_sprites
;;
;; C bindings for <cpct_checkCollisionAxis>
;;
;;   15 us, 6 bytes
;;
_cpct_checkCollisionAxis::
    ;; Get parameters from HL and DE registers and stacks ((8 + 8) + (8 + 8) bits) with __sdcccall(1) convention
    ;; A = x1
    ;; L = width1  
    ld   h, l	      ;; [1] H = L = width1
    ld   l, a         ;; [1] L = A = x1
	;; HL = (H = width1, L = x1)
	
	;; GET next parameters from the stack 
    pop  af          ;; [3] AF = Return Address
	pop  de          ;; [3] DE = (D = width2, E = x2)
	push af          ;; [4] Restore Return Address at (SP) = AF because __z88dk_callee
	
.include /cpct_checkCollisionAxis.asm/

    ret	             ;; [3] Return to caller