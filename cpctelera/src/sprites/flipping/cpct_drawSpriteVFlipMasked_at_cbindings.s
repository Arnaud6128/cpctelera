;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
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
;; C bindings for <cpct_drawSpriteVFlipMasked_at>
;;
;;   28 us, 9 bytes
;;
_cpct_drawSpriteVFlipMasked_at::
   ld   (restoreIX), ix ;; [6] Save IX to restore it before returning

   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16) bits) with __sdcccall(1) convention
   ;; HL = Source Address (Sprite data array)
   ;; DE = Destination address (Video memory location)
   ld    b, h           ;; [1] BC = HL
   ld    c, l           ;; [1] |
   
   ;; GET nextParameters from the stack 
   pop   hl             ;; [3] HL = Return Addres
   pop   ix             ;; [4] IX = Height/Width (IXH = Height, IXL = Width)
   ex   (sp), hl        ;; [6] HL = Pointer to mask table <-> Return address to stack

.include /cpct_drawSpriteVFlipMasked_at.asm/

restoreIX = .+2
   ld ix, #0000         ;; [4] Restore IX before returning (0000 is a placeholder)
   ret                  ;; [3] Return to the caller