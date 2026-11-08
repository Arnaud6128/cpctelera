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
;; C bindings for <cpct_etm_drawTileColumn2x4>
;;
;;   52 microSecs, 31 bytes
;;
_cpct_etm_drawTileColumn2x4::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (16 + 16) bits), with __sdcccall(1) convention
   ;; HL = ptilemap, DE = pvideomem. Stack = map_width (2B), nrows (2B)
   ld  (restore_ix), ix          ;; [6] Save IX and IY to restore them before returning
   ld  (restore_iy), iy          ;; [6] |
   pop  bc                       ;; [3] BC = return address
   pop  ix                       ;; [5] IX = map_width
   ld  (smc_mw1), ix             ;; [6] SMC it in the 2 expansions of DRAW_TILE
   ld  (smc_mw2), ix             ;; [6] |
   pop  iy                       ;; [5] IYL = nrows (character rows left, counter), IYH is free
   push bc                       ;; [4] Return address back on the stack, over the parameters

.include  /cpct_etm_drawTileColumn2x4.asm/

restore_ix = .+2
   ld   ix, #0000                ;; [4] Restore IX (placeholder, self-modified)
restore_iy = .+2
   ld   iy, #0000                ;; [4] Restore IY (placeholder, self-modified)
   ret                           ;; [3] Return to the caller
