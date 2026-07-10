;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
.module cpct_random

;;
;; C bindings for <cpct_setSeed_xsp40_u8>
;;
;;   13 us, 4 bytes
;;
_cpct_setSeed_xsp40_u8::
   ;; Get parameters from HL and DE registers and stack (16 + 32 bits), with __sdcccall(1) convention
   ;; HL = plusSeed (H = useless / L = plusSeed)
   ;; From stack
   ;; HL:DE = seed32

   ld   a, l     ;; [1] A = 8-bits seed for Weyl sequence
   pop  hl       ;; [3] HL = Return address
   pop  de       ;; [3] DE = First  16bits from the 32bits seed
   ex  (sp), hl  ;; [6] HL = Second 16bits from the 32bits seed (and Return address left on top of the stack)

.include /cpct_setSeed_xsp40_u8.asm/
