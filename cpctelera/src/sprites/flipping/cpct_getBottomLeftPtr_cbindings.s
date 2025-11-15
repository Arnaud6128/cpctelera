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

;;
;; C bindings for <cpct_getBottomLeftPtr>
;;
;;   2 us, 1 bytes
;;
_cpct_getBottomLeftPtr::
   ;; Get parameters from HL and DE registers(16 + 16 bits) with __sdcccall(1) convention
   ;; HL = Sprite start address pointer
   ;; DE = D = Ignored, E = height of the sprite
   
   ld  c, e       ;; [1] C = E = height of the sprite
   ex  de, hl     ;; [1] DE <-> HL
   ;; DE = Sprite start address pointer

.include /cpct_getBottomLeftPtr.asm/
