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
;; Function: cpct_checkCollisionBoxes
;;
;;   Checks for axis-aligned bounding box (AABB) collision between two 2D boxes.
;;   This function implements a standard AABB collision detection algorithm,
;;   testing both horizontal (X) and vertical (Y) axes independently.
;;
;; C Definition:
;;   u8 cpct_checkCollisionBoxes(u8 x1, u8 w1, u8 y1, u8 h1,
;;                               u8 x2, u8 w2, u8 y2, u8 h2) __z88dk_callee;
;;
;; Input Parameters (8 bytes):
;;  (2B HL) x1, w1      - First point  : position x / width
;;  (2B BC) y1, h1      - First point  : position y / height
;;  (2B DE) x2, w2      - Second point : position x / width
;;  (2B IX) y2, h2      - Second point : position y / height
;;
;;  Details :
;;   For each axis (X and Y), the function checks if the boxes are separated:
;;     - If (x1 + w1 - 1 < x2) → boxes are separated on X (no collision)
;;     - If (x2 + w2 - 1 < x1) → boxes are separated on X (no collision)
;;     - Same logic applies vertically with Y coordinates.
;;   If the boxes overlap on **both** axes, a collision is detected.
;;
;;     ;;------------------------
;;     ;; X1        X2
;;     ;; [--W1--]  [--W2--]
;;     ;;------------------------
;;     ;; if (X1 + W1 - 1 < X2)    then no_collision
;;     ;; 0 < (X2 + 1) - (X1 + W1) then colllision
;;     ;; 0 > (X1 + W1) - (X2 + 1) then collision
;;
;;     ;;------------------------    
;;     ;; X2        X1               
;;     ;; [--W2--]  [--W1--]        
;;     ;;------------------------
;;     ;;  if (X2 + W2 - 1 < X1)    then no_collision
;;     ;;  0 < (X1 + 1) - (X2 + W2) then colllision
;;     ;;  0 > (X2 + W2) - (X1 + 1) then colllision
;;   
;; Output:
;;   A = 0 → No collision
;;   A = 1 → Collision detected
;;
;; Assembly call (Input parameters on registers):
;;    > call asm_checkCollisionBoxes_asm
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL, IX
;;
;; Required memory:
;;     Code size  - 52 bytes
;;     C-bindings - 69 bytes
;;   ASM-bindings - 61 bytes
;;
;; Time Measures:
;; (start code)
;; |----------------------------------------------------------
;; |  Case       |    microSecs (us)  |      CPU Cycles      |
;; |----------------------------------------------------------
;; |  Best       |          7         |          28          |
;; |  Worst      |         35         |         140          |
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
      
     ;; --- X axis ---
     ld   a, l            ;; [1] A = x1
     add  h               ;; [1] A = x1 + w1
	 dec  a               ;; [1] A = x1 + w1 - 1
     cp   e               ;; [1] Compare with x2
     jp   c, no_collide   ;; [3/4] If (A) x1 + w1 - 1 < (E) x2 → no collision

     ld   a, e            ;; [1] A = x2
     add  d               ;; [1] A = x2 + w2
	 dec  a               ;; [1] A = x2 + w2 - 1
     cp   l               ;; [1] Compare with x1
     jp   c, no_collide   ;; [3/4] If (A) x2 + w2 - 1 < (L) x1 → no collision

     ;; --- Y axis ---
     ld   a, c            ;; [1] A = y1
     add  b               ;; [1] A = y1 + h1
	 dec  a               ;; [1] A = y1 + h1 - 1
     cp__ixl              ;; [1] Compare with y2
     jp   c, no_collide   ;; [3/4]If (A) y1 + h1 - 1 < (IXL) y2 → no collision

     ld__a_ixl            ;; [1] A = y2
     add__ixh             ;; [1] A = y2 + h2
	 dec  a               ;; [1] A = y2 + h2 - 1
     cp   c               ;; [1] Compare with y1
     jp   c, no_collide   ;; [3/4] If (A) y2 + h2 - 1 < (C) y1 → no collision

     ;; Collision detected		
     ld   a, #01          ;; [2] Return A = 1
     jp   exit_collide    ;; [3] Jump to exit

no_collide:
     xor  a               ;; [1] Return A = 0

exit_collide:
 ;; return is in binding