;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128) 
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
;; C call binding for <cpct_asicColor>
;;
;;   13 us, 5 bytes
;;
_cpct_asicColor::   
   ;; Get parameters from A and L registers and stack ((8 + 8) + 8 bits) with __sdcccall(1) convention
   ;; A = Red
   ;; L = Green
   
   ;; Get next parameters from stack
   pop  bc                        ;; [3] BC = Return address  
   dec  sp                        ;; [2] Move SP to get 1-Byte parametere
   pop  de                        ;; [3] D (Nothing) / E (Blue)
   push bc                        ;; [4] BC = Returning back address in the stack because function uses __z88dk_callee convention  
   
   ld   h, d                      ;; [1] H = E = Blue
   
.include /cpct_asicColor.asm/