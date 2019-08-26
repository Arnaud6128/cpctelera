;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2019 Arnaud Bouche (@Arnaud)
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
;; C call binding for <cpct_asicSetPalette>
;;
;;   13 us, 4 bytes
;;
_cpct_asicSetPalette::         
   ;; Getting parameters from stack
   pop  af                         ;; [3] AF = Return address
   pop  hl                         ;; [3] HL = Pointer to the start of the array with asic colour values to be set as palette
   pop  de                         ;; [3] DE = E = Size of the colour array
   push af                         ;; [4] Put returning address in the stack again as this function uses __z88dk_callee convention   

.include /cpct_asicSetPalette.asm/   