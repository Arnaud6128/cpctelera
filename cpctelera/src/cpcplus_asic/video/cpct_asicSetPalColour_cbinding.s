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
;; C call binding for <cpct_asicSetPalColour>
;;
;;   14 us, 5 bytes
;;
_cpct_asicSetPalColour::   
   ;; Get Parameters from the stack 
   pop  de                        ;; [3] DE = Return address  
   pop  hl                        ;; [3] H (useless) / L (color index)
   ld   a, l                      ;; [1] A = L (color index)
   pop  bc                        ;; [3] BC = RGB (0x00GGRRBB)
   push de                        ;; [4] DE = Returning back address in the stack because function uses __z88dk_callee convention  
   
.include /cpct_asicSetPalColour.asm/