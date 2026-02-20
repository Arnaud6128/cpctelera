;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2017 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

.include "macros/cpct_undocumentedOpcodes.h.s"	
.include "macros/cpct_maths.h.s" 

;;
;; C bindings for <cpct_drawToSpriteBufferMaskedAlignedTable>
;;
;;   31 us, 10 bytes
;;
_cpct_drawToSpriteBufferMaskedAlignedTable::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16 + 16) bits) with __sdcccall(1) convention
   ;; HL = Back_Buffer_Width
   ;; DE = Pointer to Back Buffer 
   ld   a, l            ;; [1] A = L = Back_Buffer_Width

   ld  (restore_ix), ix ;; [6] Save IX to restore it before returning

   ;; GET next parameters from the stack
   pop  hl              ;; [3] HL = Return Address
   pop  ix              ;; [5] IXH = Sprite Height, IXL = Sprite Width
   pop  bc              ;; [3] BC  = Pointer to the Sprite to be drawn
   ex  (sp), hl         ;; [6] HL = Pointer to the Mask Table (must be 256-byte aligned) <-> (SP) = Return address because _z88dk_callee convention
				 
.include /cpct_drawToSpriteBufferMaskedAlignedTable.asm/

restore_ix = .+2
   ld   ix, #0000       ;; [4] Restore IX before returning
   ret                  ;; [3] Return to caller
