;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128
;;  Copyright (C) 2019 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_asic

;; Include Asic constants 
.include "../asic.s" 

;;
;; C call binding for <cpct_asicSetSpritePalette>
;;
;;   0 us, 0 bytes
;;
_cpct_asicSetSpritePalette:: 
   ;; Get parameters from HL and DE registers (16 + 16 bits) with __sdcccall(1) convention
   ;; HL = Pointer to the start of the array with asic colour values to be set as palette
   ;; DE = D (useless) / E (Size of the colour array)

.include /cpct_asicSetSpritePalette.asm/   