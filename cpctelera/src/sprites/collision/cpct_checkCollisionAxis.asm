;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128) 
;;  Copyright (C) 2025 CPCtelera by ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_checkCollisionAxis
;;
;;    Check collision between two segments on same axis
;;
;; C Definition:
;;     u8 <asm_checkCollisionAxis> (u8 x1, u8 w1, u8 x2, u8 w2) __z88dk_callee;
;;
;; Input Parameters (4 bytes):
;;  (2B HL) x1, w1      - First point  : position x / width
;;  (2B DE) x2, w2      - Second point : position x / width
;;
;;  Details :
;;   Works horizontally or vertically (x and Width or y and Height)
;;
;;   Here all cases :
;;	 ;;------------------------
;;	 ;; X1        X2
;;	 ;; [--W1--]  [--W2--]
;;	 ;;------------------------
;;	 ;; if (X1 + W1 < X2 + 1)    then no_collision
;;	 ;; 0 < (X2 + 1) - (X1 + W1) then colllision
;;	 ;; 0 > (X1 + W1) - (X2 + 1) then collision
;;
;;	 ;;------------------------    
;;	 ;; X2        X1               
;;	 ;; [--W2--]  [--W1--]        
;;	 ;;------------------------
;;	 ;;  if (X2 + W2 < X1 + 1)    then no_collision
;;	 ;;  0 < (X1 + 1) - (X2 + W2) then colllision
;;	 ;;  0 > (X2 + W2) - (X1 + 1) then colllision
;;	 
;; Assembly call (Input parameters on registers):
;;    > call asm_checkCollisionAxis_asm
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;     Code size  - 23 bytes
;;     C-bindings - 30 bytes
;;   ASM-bindings - 24 bytes
;;
;; Time Measures:
;; (start code)
;; |----------------------------------------------------------
;; |  Case       |    microSecs (us)  |      CPU Cycles      |
;; |----------------------------------------------------------
;; |  Best       |          9         |          36          |
;; |  Worst      |         20         |          80          |
;; |----------------------------------------------------------
;; | Asm saving  |        -11         |         -44          |
;; |----------------------------------------------------------
;; (end code)
;;
;; Credits:
;;    Original code by @ronaldo discussed in Amstrad.es : 
;; http://www.amstrad.es/forum/viewtopic.php?t=5190&p=71065
;;
;; Thanks to all who participated in the discussion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 ;;------------------------
	 ;; X1        X2
	 ;; [--W1--]  [--W2--]
	 ;;------------------------
	 ;; if (X1 + W1 < X2 + 1) then no_collision
	 ;;  0 < (X2 + 1) - (X1 + W1)
	 ;;  0 > (X1 + W1) - (X2 + 1)
	 ld     a, l         ;; [1]    A = X1
	 ld     c, a         ;; [1]    C = X1
	 add    h            ;; [1]    A = X1 + W1
	 ld     b, e         ;; [1]    B = X2
	 inc    b            ;; [1]    B = X2 + 1
	 sub    b            ;; [1]    A = (X2 + 1) - (X1 + W1)
	 jp     c, check_return_no_collide ;; [3/4]  If Carry, no_collision

	 ;;------------------------    
	 ;; X2        X1               
	 ;; [--W2--]  [--W1--]        
	 ;;------------------------
	 ;;  if (X2 + W2 < X1 + 1) then no_collision
	 ;;  0 < (X1 + 1) - (X2 + W2)
	 ;;  0 > (X2 + W2) - (X1 + 1)
	 inc    c            ;; [1]    C = X1 + 1
	 ld     a, b         ;; [1]    A = X2 + 1
	 add    d            ;; [1]    A = X2 + W2 + 1
	 dec    a            ;; [1]    A = X2 + W2
	 sub    c            ;; [1]    A = (X2 + W2) - (X1 + 1)
	 jp     c, check_return_no_collide ;; [3/4]  If Carry, no_collision

     ;; Collision detected
     ld    a, #01        ;; [2] Return A = 1
	 ret                 ;; [3] Return to caller
	 
check_return_no_collide:
     xor   a             ;; [1] Return A = 0
;; return is in binding