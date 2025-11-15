;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2022 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2022 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_spriteColourizeM0>
;;
;;   12 us, 5 bytes
;;
_cpct_spriteColourizeM0::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + 16 bits) with __sdcccall(1) convention
   ;; HL = Replace Pattern (D=Find Pattern [OldPen], E=Insert Pattern (NewPen))
   ;; DE = Size of the array/sprite (width*height)

   ex    de, hl                  ;; [1] DE <-> HL
   ;; DE = Replace Pattern (D=Find Pattern [OldPen], E=Insert Pattern (NewPen))
   ;; HL = Size of the array/sprite (width*height)
   ld    b, h                    ;; [1] BC = HL = Size of the array/sprite (width*height)
   ld    c, l                    ;; [1] |
   
   ;; GET next parameters from the stack 
   pop   hl                      ;; [3] HL = Return Address  
   ex   (sp), hl                 ;; [6] HL = Pointer to the sprite
                                 ;; ... and leave Return Address at (SP) as we don't need to restore
                                 ;; ... stack status because callin convention is __z88dk_callee
   
   push  ix                      ;; [5] Save IX to let this function use and restore them before returning
   
   ;; Include Common code
   .include /cpct_spriteColourizeM0.asm/
   
   ;; Generate the code with just 1 increment of HL at the end of every loop pass
   ;; as the array/sprite is to be composed of consecutive bytes 
   cpctm_generate_spriteColourizeM0 1
   
   pop  ix                       ;; [4] Restore IX before returning
   ret                           ;; [3] Return to caller