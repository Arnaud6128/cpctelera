;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_draw

;;
;; C bindings for <cpct_drawPlotM1>
;;
;;  11 microSecs, 4 bytes
;;
_cpct_drawPlotM1::

    ;; Parameters retrieval from registers
    ex    de, hl          ;; [1]  DE = Screen base, HL = X coordinate
	
	;; Parameters retrieval from stack 
    pop   af              ;; [3]  AF = Return address
    pop   bc              ;; [3]  B = Color, C = Y coordinate
    push  af              ;; [4]  Restore return address to stack because __z88dk_callee

.include  /cpct_drawPlotM1.asm/

 
   