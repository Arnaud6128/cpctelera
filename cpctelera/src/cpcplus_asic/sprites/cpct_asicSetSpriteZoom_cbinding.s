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
;; C call binding for <cpct_asicSetSpriteZoom>
;;
;;   11 us, 4 bytes
;;
_cpct_asicSetSpriteZoom::   
   ;; Get parameters from HL and stack (16 + (8 + 8) bits) with __sdcccall(1) convention
   ;; HL = H (Nothing) / L (HWSprite Id
   ld   a, l    ;; [1] A = L (HWSprite Id) 
   
   ;; Getting parameters from stack
   pop  de      ;; [3] DE = Return address
   pop  hl      ;; [3] H (ZoomY) / L (ZoomX)
   push de      ;; [4] Put returning address from DE in the stack again as this function uses __z88dk_callee convention      
     
 
.include /cpct_asicSetSpriteZoom.asm/