;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
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
;; C bindings for <cpct_etm_redrawTileBox>
;;
;;  23 microSecs, 12 bytes
;;
_cpct_etm_drawTileBox2x4::
   ;; Get parameters from HL and DE registers and stack ((8 + 8) + (16 + 16) bits), with __sdcccall(1) convention
   ;; A = x coordinate
   ;; L = y coordinate  
   ld   b, l                   ;; [1] BC = L:y coordinate, A:x coordinate
   ld   c, a                   ;; [1] |
  
   pop  hl                     ;; [3] HL = Return address
   ld (simulated_return+1), hl ;; [5] Save return address for simulated return
   pop  hl                     ;; [3] H = height in tiles, L = width in tiles
   dec  sp                     ;; [2] Move SP 1 byte as next parameter (map_width is 1-byte length)
   pop  af                     ;; [3] A = map_width (width in tiles of a complete row of the tilemap)

   ;; Leave pvideomem and ptilemap in the stack as they will be recovered later
   ;; during function operation

.include  /cpct_etm_drawTileBox2x4.asm/

simulated_return:
   ld   hl, #0000              ;; [3] HL = return address
   jp   (hl)                   ;; [1] Do a manual "ret"
