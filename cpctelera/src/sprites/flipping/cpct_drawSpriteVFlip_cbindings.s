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

;;
;; C bindings for <cpct_drawSpriteVFlip>
;;
;;   12 us, 65 bytes
;;
_cpct_drawSpriteVFlip::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8) bits) with __sdcccall(1) convention
   ;; HL = Source Address (Sprite data array)
   ;; DE = Destination address (Video memory location)
   
   ex   de, hl    ;; [1] DE <-> HL
   ;; HL = Destination address (Video memory location)
   ;; DE = Source Address (Sprite data array)
   
   ;; GET next parameters from the stack
   pop  af        ;; [3] AF = Return Address
   pop  bc        ;; [3] BC = Height/Width (B = Height, C = Width)
   push af        ;; [4] Put returning address in the stack again as this function uses __z88dk_callee convention

   ld   a, c      ;; [1] A = C = width

.include /cpct_drawSpriteVFlip.asm/