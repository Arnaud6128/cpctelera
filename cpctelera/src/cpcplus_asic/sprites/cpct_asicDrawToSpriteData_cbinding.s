;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128
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
.module cpct_asic

;; Includes
.include "../../macros/cpct_undocumentedOpcodes.h.s"

;; Include Asic constants 
.include "../asic.s"  

;;
;; C call binding for <cpct_asicDrawToSpriteData>
;;
;;   32 us, 11 bytes
;;
_cpct_asicDrawToSpriteData::   
   ;; Get parameters from HL registers and stack (16 + (8 + 8 + 16 + 8 + 8) bits) with __sdcccall(1) convention
   ;; HL = H (Nothing) / L (HWSprite Id)
   ld a, l            ;; [1] A = L = HWSprite Id

   ld   (save_ix), ix ;; [6] Save IX before using it

   ;; Get next parameters from stack
   pop  ix            ;; [4] IX = Return address
   pop  de            ;; [3] DE = D (Pos_x) / E (Pos_y)
   pop  hl            ;; [3] HL = Pointer to source Sprite data
   pop  bc            ;; [3] BC = (B = Height, C = Width)
   push ix            ;; [5] Return Address from IX in stack because __z88dk_callee convention
   
.include /cpct_asicDrawToSpriteData.asm/   

save_ix = .+2
   ld   ix, #0000    ;; [4] Restore IX (0000 is a placeholder)
   ret               ;; [3] Return to caller