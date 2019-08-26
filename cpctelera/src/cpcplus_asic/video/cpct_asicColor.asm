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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   Convert RGB to asic colour
;;    
;;
;; C Definition:
;;    <void> cpct_asicColor(<u8> *red*, <u8> *green*, <u8> *blue*) __z88dk_callee
;;
;; Assembly call:
;;    > cpct_asicColor_asm
;;
;; Input Parameters (2 Bytes):
;;   (1B L) red   - 1-byte for red component 
;;   (1B C) green - 1-byte for green component
;;   (1B B) blue  - 1-byte for blue component
;;
;; Details:
;;  The conversion : colour = (G << 8) | (R << 4) | B = 0x0GRB
;;  Only the four less significant bit (LSB) of each component are used
;;	Use *cpctm_rgbColour* for RGB conversion with constants
;;
;; Destroyed Register values: 
;;    A, B, HL
;;
;; Required memory:
;;    C-binding   - 27 bytes
;;    ASM-binding - 22 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        |      31       |    124
;; Asm saving |     -15       |    -60
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   sla  a      ;; [1] A = A << 4 (0xR0)
   sla  a      ;; [1] |
   sla  a      ;; [1] |
   sla  a      ;; [1] |
   ld   b, a   ;; [1] B = A (0xR0)

   ld   a, h   ;; [1] A = H (0xBB)
   and  #0x0F  ;; [2] A (0xBB) & 0x0F = 0x0B
   or   b      ;; [1] A = A (0x0B) | B (0xR0)= 0xRB
   ld   b, a   ;; [1] B = A (0xRB)
   
   ld   a, l   ;; [1] A = L (0xGG)
   and  #0x0F  ;; [2] A (0xGG) & 0x0F = 0x0G
   ld   h, a   ;; [1] H = A (0x0G)
   
   ld   l, b   ;; [1] L = B (0xRB) 
   				 
   ret         ;; [3] Return : HL = 0x0GRB
   
  