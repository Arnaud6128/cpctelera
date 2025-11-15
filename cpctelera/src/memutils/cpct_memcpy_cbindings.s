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
.module cpct_memutils

;;
;; C bindings for <cpct_memcpy>
;;
;;   13 us, 4 bytes
;;
_cpct_memcpy::
   ;; Get parameters from HL, DE register and stack ((16 + 16) + (16) bits) with __sdcccall(1) convention
   ;; HL = Destination address
   ;; DE = Source Address
   
   ex de, hl ;; [1] DE <-> HL
   ;; DE = Destination address
   ;; HL = Source Address

   pop  af   ;; [3] AF = Return Address
   pop  bc   ;; [3] BC = size - Number of bytes to be set (>= 1)
   push af   ;; [4] Put returning address in the stack again
             ;;      as this function uses __z88dk_callee convention

.include /cpct_memcpy.asm/
