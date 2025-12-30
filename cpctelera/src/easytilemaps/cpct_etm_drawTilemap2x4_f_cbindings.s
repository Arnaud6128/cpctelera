;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128) 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_easytilemaps

;;
;; C bindings for <cpct_etm_drawTileMap2x4_f>
;;
;;  13 microSecs, 4 bytes
;;
_cpct_etm_drawTilemap2x4_f::
   ;; Get parameters from HL and DE registers and stack ((8 + 8) + (16 + 16) bits), with __sdcccall(1) convention
   ;; A = map_width
   ;; L = map_height 
   ld   c, l        ;; [1] C = L = map_height
   
   ;; Recover next parameters from the stack
   pop hl           ;; [3] HL = Return Address
   pop de           ;; [3] DE = Pointer to video memory where to draw the tilemap
   ex (sp), hl      ;; [6] HL = Pointer to the start of the tilemap

.include /cpct_etm_drawTilemap2x4_f.asm/
