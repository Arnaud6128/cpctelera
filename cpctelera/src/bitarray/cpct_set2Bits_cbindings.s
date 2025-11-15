;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
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
.module cpct_bitarray

;;
;; C-bindings for calling function <cpct_set2Bits>
;;
;;  11 microSecs, 4 bytes
;;
_cpct_set2Bits::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (16) bits), with __sdcccall(1) convention
   ;; HL = Pointer to the array in memory
   ;; DE = Value to be set (Only E is used)
   
   ex de, hl  ;; [1] DE <-> HL : 
   ;; DE = Pointer to the array in memory
   ;; HL = Value to be set (Only L is used)
   ld c, l    ;; [1] C = Value to be set = L

   ;; Recover parameters from the stack
   pop hl           ;; [3] HL = Return Address
   ex (sp), hl      ;; [6] HL = Index of the group of 2 bits we want to set
                    ;; ... also putting again Return Address where SP is located now
                    ;; ... as this function is using __z88dk_callee convention

.include /cpct_set2Bits.asm/