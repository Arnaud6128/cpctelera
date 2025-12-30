;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128) 
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
;; C call binding for <cpct_asicSetSpritePosition>
;;
;;   13 us, 6 bytes
;;
_cpct_asicSetSpritePosition::   
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + 16 bits) with __sdcccall(1) convention
   ;; HL = H (Nothing) / L (HWSprite Id)
   ;; DE = Pos_x
   ld  b, d                      ;; [1] BC = DE = Pos_x
   ld  c, e                      ;; [1] | 
   
   ;; Getting next parameters from stack
   pop  af                       ;; [3] AF = Return address
   pop  de                       ;; [3] DE = PosY
   push af                       ;; [4] Put returning address from AF in the stack as this function uses __z88dk_callee convention 
   
   ld   a, l                     ;; [1] A = L (HWSprite Id)   
   
   ;; Getting parameters from stack
  ; pop  af                       ;; [3] AF = Return address
 ;  pop  hl                       ;; [3] HL = H (useless) / L (HWSprite Id)
  ; pop  bc                       ;; [3] BC = PosX
  ; pop  de                       ;; [3] DE = PosY
 ;  push af                       ;; [4] Put returning address from AF in the stack as this function uses __z88dk_callee convention 
 ;  ld   a, l                     ;; [1] A = L (HWSprite Id)   

.include /cpct_asicSetSpritePosition.asm/ 
