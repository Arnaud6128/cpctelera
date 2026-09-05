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

.globl cpct_getColorAtM1_asm

;;
;; C bindings for <cpct_geometryPlotM1>
;; extern u8   cpct_getColorAtM1         (u8* vmem, u16 x, u8 y) __z88dk_callee;
;;   vmem        - Base VRAM memory address (typically 0xC000)
;;   x           - X coordinate (0-319)
;;   y           - Y coordinate (0-199)
;;
;; return value:  Ink color of pixel (0..3)
;;
;;  16 microSecs, 7 bytes
;;
_cpct_getColorAtM1::
   pop  af                     ;; [3] af = Return addressc
   pop  bc                     ;; [3] c = y  
   dec  sp                     ;; [6] b unused
   push af                     ;; [4] Restore return address to stack because __z88dk_callee

   jp cpct_getColorAtM1_asm    ;; Goto main entry point and use official ret
