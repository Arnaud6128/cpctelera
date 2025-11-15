;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2017 Arnaud Bouche (Arnaud6128)
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

;;
;; C bindings for <cpct_drawSpriteMaskedAlignedColorizeM1>
;;
;;   41 us, 16 bytes
;;
_cpct_drawSpriteMaskedAlignedColorizeM1::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16 + 16) bits) with __sdcccall(1) convention
   ;; HL = Source Sprite Pointer
   ;; DE = Destination video memory pointer
   
   ld (colour_sprite_restore_ix), ix  ;; [6] Save IX to restore it before returning
   
   push hl           ;; [4] Flip HL <-> AF via stack
   pop  af           ;; [3] | AF = HL Source Sprite Pointer
   
   ;; GET next parameters from the stack 
   pop   hl          ;; [3] HL = Return Address
   pop   bc          ;; [3] BC = (B = Sprite Height, C = Width)
   pop   ix          ;; [4] IX = Pointer to an Aligned Mask Table for transparencies with palette index 0
   ex   (sp), hl     ;; [6] HL = Replace Pattern (H=Find Pattern [OldPen], L=Insert Pattern (NewPen))
   
   push  iy          ;; [5] Save IY to restore it before returning
  
.include /cpct_drawSpriteMaskedAlignedColorizeM1.asm/

colour_sprite_restore_ix = .+2
   ld   ix, #0000    ;; [4] Restore IX before returning  
   pop  iy           ;; [4] Restore IY before returning    
   ret               ;; [3] Return to caller