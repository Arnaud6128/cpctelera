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

;; Macros for easy use of undocumented opcodes
.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_checkCollisionBoxes>
;;
;;   23 us, 17 bytes
;;
_cpct_checkCollisionBoxes::
    ;; Get parameters from HL and DE registers and stacks ((8 + 8) + (8 + 8 + 8 + 8 + 8 + 8 + 8 + 8) bits) with __sdcccall(1) convention
    ;; A = x1
    ;; L = width1  
    ld   h, l	        ;; [1] H = L = width1
    ld   l, a           ;; [1] L = A = x1

    ld  (save_ix), ix   ;; [5]
        
    ;; GET next parameters from the stack 
    pop  af             ;; [3] AF = Return Address    
	                    ;;     HL = (H = width1,  L = x1)
	pop  bc             ;; [3] BC = (B = height1, C = y1)
    pop  de             ;; [3] DE = (D = width2,  E = x2)   
    pop  ix             ;; [4] IX = (IXH = height2, iXL = y2)
    push af             ;; [4] Restore Return Address at (SP) = AF because __z88dk_callee convention
    
.include /cpct_checkCollisionBoxes.asm/

save_ix = .+2
    ld ix, #0000        ;; [4] Restore IX
    ret                 ;; [3] Return to caller