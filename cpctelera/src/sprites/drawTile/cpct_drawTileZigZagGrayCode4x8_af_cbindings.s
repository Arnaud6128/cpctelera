
;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2019 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.module cpct_sprites

;;
;; C bindings for <cpct_drawTileZigZagGrayCode4x8_af>
;;
;;   1 us, 1 bytes
;;
_cpct_drawTileZigZagGrayCode4x8_af::
   ;; Get parameters from HL and DE registers (16 + 16 bits) with __sdcccall(1) convention
   ;; HL = Pointer to video memory location where the sprite will be drawn
   ;; DE = Pointer to the end of the sprite array
  
   ex  de, hl  ;; [1] DE <-> HL
   ;; HL = Pointer to the end of the sprite array 
   ;; DE = Pointer to video memory location where the sprite will be drawn

.include /cpct_drawTileZigZagGrayCode4x8_af.asm/