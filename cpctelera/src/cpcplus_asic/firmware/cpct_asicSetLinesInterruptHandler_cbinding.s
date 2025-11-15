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
;; C call binding for <cpct_asicSetLinesInterruptHandler>
;;
;;   13 us, 7 bytes
;;
_cpct_asicSetLinesInterruptHandler::   
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + 16 bits) with __sdcccall(1) convention
   ;; HL = Interrupt Handler function
   ;; DE = Array of lines interrupt
   ex de, hl  ;; [1] DE <-> HL
   
   ;; HL = Array of lines interrupt
   ;; DE = Interrupt Handler function
   ld b, d    ;; [1] BC = DE = Interrupt Handler function
   ld c, e    ;; [1] |
   
   ;; Getting next parameters from stack
   pop  af                       ;; [3] AF = Return address
   pop  de                       ;; [3] DE = Size of array (<=255)
   push af                       ;; [4] Put returning address from AF in the stack as this function uses __z88dk_callee convention 
   ld   a, e                     ;; [1] A = E (Size of array) 
   
   ;; Getting parameters from stack
 ;  pop  af                       ;; [3] AF = Return address
 ;  pop  bc                       ;; [3] BC = Interrupt Handler function
 ;  pop  hl                       ;; [3] HL = Array of lines interrupt
 ;  pop  de                       ;; [3] DE = Size of array (<=255)
 ;  push af                       ;; [4] Put returning address from AF in the stack as this function uses __z88dk_callee convention 
 ;  ld   a, e                     ;; [1] A = E (Size of array)   

.include /cpct_asicSetLinesInterruptHandler.asm/ 
