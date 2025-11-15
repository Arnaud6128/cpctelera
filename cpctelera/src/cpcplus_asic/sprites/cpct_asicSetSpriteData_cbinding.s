;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2019 Arnaud Bouche (@Arnaud)
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

;; Include Asic constants 
.include "../asic.s" 

;;
;; C call binding for <cpct_asicSetSpriteData>
;;
;;   2 us, 2 bytes
;;
_cpct_asicSetSpriteData::   
   ;; Get parameters from A and L registers (8 + 8 bits) with __sdcccall(1) convention
   ;; A = HWSprite Id
   ;; L = Value
   ld h, l      ;; [1] H = L = Value
   ld l, a      ;; [1] L = A = HWSprite Id

   ;; Getting parameters from stack
  ;; pop  af      ;; [3] AF = Return address
  ;; pop  hl      ;; [3] H (Value) / L (HWSprite Id)
  ;; push af      ;; [4] Put returning address in the stack again as this function uses __z88dk_callee convention      
   
.include /cpct_asicSetSpriteData.asm/      