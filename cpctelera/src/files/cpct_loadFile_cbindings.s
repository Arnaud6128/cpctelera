;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2019 Arnaud Bouche (@Arnaud6128)
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
.module cpct_dsk

;;
;; C bindings for <cpct_loadFile>
;;
;;   14 us, 3 bytes
;;
_cpct_loadFile::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) bits + 16 bits), with __sdcccall(1) convention
   ;; HL = File name
   ;; DE = Destination buffer size minimum of 512kb

   ;; Get next parameters from the Stack
   pop  af          ;; [3] AF = Return Address
   pop  bc          ;; [3] BC = Sector table buffer of 256Kb
   push af          ;; [4] AF = Returning back address in the stack because function uses __z88dk_callee convention	
  
.include /cpct_loadFile.asm/
