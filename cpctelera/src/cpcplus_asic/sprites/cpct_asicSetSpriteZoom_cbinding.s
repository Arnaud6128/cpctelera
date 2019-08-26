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
;;   14 us, 5 bytes
;;
_cpct_asicSetSpriteZoom::   
   ;; Getting parameters from stack
   pop  af      ;; [3] AF = Return address
   pop  bc      ;; [3] BC = B (useless) / C (HWSprite Id)
   pop  hl      ;; [3] H (ZoomY) / L (ZoomX)
   push af      ;; [4] Put returning address from AF in the stack again as this function uses __z88dk_callee convention      
   ld   a, c    ;; [1] A = C (HWSprite Id)   
 
.include /cpct_asicSetSpriteZoom.asm/