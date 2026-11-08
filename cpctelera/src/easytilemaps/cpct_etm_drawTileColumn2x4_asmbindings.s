;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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

;; Macros for easy use of undocumented opcodes
.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; ASM bindings for <cpct_etm_drawTileColumn2x4>
;;
;;   17 microSecs, 11 bytes
;;
cpct_etm_drawTileColumn2x4_asm::
   ;; HL = ptilemap, DE = pvideomem, BC = map_width, A = nrows
   ;; IX and IY are used and not restored (the C bindings do it)
   ld  (smc_mw1), bc             ;; [6] SMC map_width in the 2 expansions of DRAW_TILE
   ld  (smc_mw2), bc             ;; [6] |
   ld__iyl_a                     ;; [2] IYL = nrows (character rows left, counter)

.include  /cpct_etm_drawTileColumn2x4.asm/

   ret                           ;; [3] Return to the caller
