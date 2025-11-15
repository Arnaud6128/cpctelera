;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

;;
;; C bindings for <cpct_drawSpriteMaskedColorizeM1>
;;
;;   33 us, 13 bytes
;;
_cpct_drawSpriteMaskedColorizeM1::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16) bits) with __sdcccall(1) convention
   ;; HL = Source Sprite Pointer
   ;; DE = Destination video memory pointer

   ld   (restore_ix), ix ;; [6] Save IX

   ;; GET next parameters from the stack 
   pop   af              ;; [3] AF = Return Address
   pop   bc              ;; [3] BC = (B = Sprite Height, C = Width)
   pop   ix              ;; [4] Replace Pattern (IXH=Find Pattern [OldPen], IXL=Insert Pattern (NewPen))
   push  af              ;; [4] Restore Return Address at (SP) = AF because __z88dk_callee
   
   push  iy              ;; [5] Save IY  

.include /cpct_drawSpriteMaskedColorizeM1.asm/

restore_ix =.+2
   ld   ix, #0000        ;; [4] Restore IX
   pop  iy               ;; [4] Restore IY
   ret                   ;; [3] Return to caller