;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2017 Bouche Arnaud
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

.include "macros/cpct_maths.h.s"

;;
;; C bindings for <cpct_drawToSpriteBufferMasked>
;;
;;   13 us, 4 bytes
;;
_cpct_drawToSpriteBufferMasked::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16) bits) with __sdcccall(1) convention
   ;; HL = Back_Buffer_Width
   ;; DE = Pointer to Back Buffer 
   ld   a, l      ;; [1] A = L = Back_Buffer_Width

   ;; GET next parameters from the stack
   pop  hl        ;; [3] HL = Return Address
   pop  bc        ;; [3] BC = Height/Width (B = Height, C = Width)
   ex  (sp), hl   ;; [6] HL = Pointer to Sprite <-> (SP) = Return address because _z88dk_callee convention
				 
.include /cpct_drawToSpriteBufferMasked.asm/