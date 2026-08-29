;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Xavier Jollet (@SagaDS)
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
.module cpct_geometry

;;
;; C bindings for <cpct_geometryPlotM1>
;;
;;  16 microSecs, 4 bytes
;;
_cpct_getColorAtM1::
   pop af                      ;; [3] af = Return addressc
   pop bc                      ;; [3] c = y  
   dec sp                      ;; [6] b unused
   push af                     ;; [4] Restore return address to stack because __z88dk_callee

.include  /cpct_getColorAtM1_1.asm/
.include  /cpct_getColorAtM1_2.asm/
