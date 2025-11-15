;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2021 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; C bindings for <cpct_pens2pixelPatternPairM1>
;;
;;    5 microSecs, 3 bytes
;;
_cpct_pens2pixelPatternPairM1_real::    ;; C-Entry Point
   ;; Get parameters from A and L registers (8 + 8 bits) with __sdcccall(1) convention
   ;; A = NewPen
   ;; L = OldPen
   ld e, a        ;; [1] E = A = NewPen
   ld d, l        ;; [1] D = L = OldPen
   
   ;; Include common code
   .include /cpct_pens2pixelPatternPairM1.asm/
   
   ret            ;; [3] Return value in C (D=Pattern for Pen 1, E=Pattern for Pen 2)
