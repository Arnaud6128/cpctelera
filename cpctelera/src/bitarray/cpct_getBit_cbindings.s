;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128) 
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
;; C-bindings for calling function <cpct_getBit>
;;
;;  1 microSec, 1 byte
;;
_cpct_getBit::
   ;; Get parameters from HL and DE registers (16 + 16 bits), with __sdcccall(1) convention
   ;; HL = Pointer to the array in memory
   ;; DE = Index of the bit we want to get
   ex de, hl      ;;[1] DE<->HL =>
   ;; DE = Pointer to the array in memory
   ;; HL = Index of the bit we want to get

.include /cpct_getBit.asm/
