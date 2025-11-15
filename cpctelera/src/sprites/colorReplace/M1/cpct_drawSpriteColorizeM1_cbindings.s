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
;; C bindings for <cpct_drawSpriteColorizeM1>
;;
;;   40 us, 10 bytes
;;
_cpct_drawSpriteColorizeM1::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16) bits) with __sdcccall(1) convention
   ;; HL = Source Sprite Pointer
   ;; DE = Destination video memory pointer
   
   push  hl          ;; [3] Flip HL <->AF
   pop   af          ;; [4] | AF = Source Sprite Pointer
   
   ;; GET next parameters from the stack 
   pop   hl          ;; [3] HL = Return Address
   pop   bc          ;; [3] BC = (B = Sprite Height, C = Width)
   ex   (sp), hl     ;; [6] HL = Replace Pattern (H=Find Pattern [OldPen], L=Insert Pattern (NewPen))and leave Return Address at (SP)

   push  ix          ;; [5] Save IX and IY to let this function...
   push  iy          ;; [5] ...use and restore them before returning                                                           				                    
								
.include /cpct_drawSpriteColorizeM1.asm/
   
   pop  iy            ;; [4] Restore IY
   pop  ix            ;; [4] Restore IX
   ret                ;; [3] Return to caller