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
.include "macros/cpct_reverseBits.h.s"
.include "macros/cpct_maths.h.s"

;;
;; ASM bindings for <cpct_drawMaskedToSpriteBufferHFlipM0>
;;
;;   13 us, 5 bytes
;;
_ccpct_drawMaskeToSpriteBufferHFlipM0_asm::
   push ix        ;; [5] Save IX
   
.include /cpct_drawMaskedToSpriteBufferHFlipM0.asm/

   pop ix         ;; [5] Restore IX
   ret            ;; [3] Return to caller