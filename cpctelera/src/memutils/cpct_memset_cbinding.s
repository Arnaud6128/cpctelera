;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128
;;  Copyright (C) 2014-2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_memutils

;;
;; C call binding for <cpct_memset>
;;
;;   15 us, 6 bytes
;;
_cpct_memset::
   ;; Get parameters from HL register and stack (16 + (8 + 16) bits), with __sdcccall(1) convention
   ex   de, hl ;; [1] DE <-> HL
   ;; DE = HL Pointer to the array to be set (1st parameter)
   
   ;; Get next parameters from the stack 
   pop  hl     ;; [3] HL = Return address
   dec  sp     ;; [2] 
   pop  af     ;; [3] A  = Value to be set (2nd parameter)
   pop  bc     ;; [3] BC = Size of the array (3rd parameter)
   push hl     ;; [4] Put returning address in the stack again
               ;;      as this function uses __z88dk_callee convention

.include /cpct_memset.asm/

