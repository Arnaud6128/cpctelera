;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2016 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
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

;; Required macro definitions
.include "src/macros/cpct_reverseBits.h.s"

;;
;; C bindings for <cpct_hflipSpriteM1_r>
;;
;;   10 us, 3 bytes
;;
_cpct_hflipSpriteM1_r::
    ;; Get parameters from HL registers and stack ((16) + (8 + 8) bits), with __sdcccall(1) convention
   ;; HL = Sprite start address pointer
   ex  de, hl  ;; [1] DE <-> HL
   ;; DE = Sprite start address pointer
   
   ;; Parameter retrieval from stack
   pop  hl     ;; [3] HL = return address
   ex (sp), hl ;; [6] HL = height / width, while leaving return address in the
               ;; ... stack, as this function uses __z88dk_callee convention

.include /cpct_hflipSpriteM1_r.asm/
