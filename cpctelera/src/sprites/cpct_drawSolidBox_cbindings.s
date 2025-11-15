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
.module cpct_sprites

;; Macros for easy use of undocumented opcodes
.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_drawSolidBox>
;;
;;   16 us, 5 bytes
;;
_cpct_drawSolidBox::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8) bits), with __sdcccall(1) convention
   ;; HL = Video Memory Address
   ;; DE = Colour Pattern
   
   ex de, hl        ;; [1] HL <-> DE
   ;; DE = Video Memory Address
   ;; L = Colour Pattern
   
   pop   af          ;; [3] AF = Return address
   pop   bc          ;; [3] B = Height, C = Width
   push  af          ;; [4] Leave return address in the stack to fullfill __z88dk_callee convention
  
.include /cpct_drawSolidBox.asm/
