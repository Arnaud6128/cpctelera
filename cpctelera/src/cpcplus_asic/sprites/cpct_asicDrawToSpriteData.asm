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
;;  Draws an sprite inside hardware sprite's buffer.
;;    
;;
;; C Definition:
;;    <void> cpct_asicDrawToSpriteData(<u8> *hardware_sprite_id*, <u8> *pos_x*, <u8> *pos_y*, <const u8*> *sprite_array*, <u8> *width*, <u8> *height*) __z88dk_callee;
;;
;; Assembly call:
;;    > call cpct_asicDrawToSpriteData_asm
;;
;; Input Parameters (4 Bytes):
;;  (1B A)  hardware_sprite_id - Hardware sprite identifier (0..15)
;;  (1B C ) width  - Sprite Width (<16)
;;  (1B B ) height - Sprite Height (<16)
;;  (2B HL) sprite_array - Pointer to the start of the array of sprite data
;;  (1B E ) pos_x  - Start position x inside Sprite for copy (<15)
;;  (1B D ) pos_y  - Start location y inside Sprite for copy (<15)
;;
;; Parameter Restrictions:
;;  * *hardware_sprite_id* hardware sprites identifier from 0 to 15 (16 available)
;;  * *width* width of the source sprite must be <16
;;  * *height* height of the source sprite must be <16
;;  * *sprite_array* must be an array containing sprite's pixels data. 
;; 1-Bytes per pixel : 0b0000cccc (4-bits used for 16 colours indexed)
;; Sprite must be rectangular and all bytes in the array must be consecutive pixels, 
;; starting from top-left corner and going left-to-right, top-to-bottom down to the bottom-right corner.
;;  * *pos_x* starting position x inside destination sprite where copy data. Must be < 15
;;  * *pos_y* starting position y inside destination sprite where copy data. Must be < 15
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL, IX
;;
;; Required memory:
;;    C-binding   - 57 bytes
;;    ASM-binding - 44 bytes
;;
;; Time Measures:
;; (start code)
;; Case       |    microSecs(us)   |     CPU Cycles
;; --------------------------------------------------------
;; Any        | 59 + (12 + 6*W-1)H |  164 + (48 + 24*W-1)H 
;; --------------------------------------------------------
;; W=2,H=16   |        427         |       1708
;; W=16,H=8   |        915         |       3660
;; --------------------------------------------------------
;; Asm saving |        -33         |       -132
;; --------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
  add  a, #ASIC_HW_SPRITE_DATA ;; [2] A = A (HWSpriteId) + MSB HWSprite data location (0x40)
  ld__ixl_a         ;; [2] IXL = A (Save for later use)
  
  ;;                ;;  Compute Destination offset
  ld  a, #16        ;; [2] | A = 16
  sub c             ;; [1] | A -= C (Sprite Width)
  ld__ixh_a         ;; [2] | IHX = A
  
  ;;                ;; D = D (PosY offset) * SPRITE_HARDWARE_WIDTH (16)
  sla d             ;; [1] | D = D * 2
  sla d             ;; [1] | D = D * 4
  sla d             ;; [1] | D = D * 8
  sla d             ;; [1] | D = D * 16
  
  ld  a, d          ;; [1] A = D
  add a, e          ;; [1] A = A + E (PosX offset)
  ld  e, a          ;; [1] E = A
  
  ld__d_ixl         ;; [2] D = IXL
                    ;; -> DE = Pointer of start of sprite data to be replaced
  
  ld__ixl_c         ;; [2] IXL = C (Sprite Width)
  ld  a, b          ;; [1] A = B (Sprite Height)
  ld  b, #00        ;; [2] BC = B (0) / C (Sprite Width)
  
;; Perform the copy
copy_loop:
  ld__c_ixl         ;; [2] C = IXL (Sprite Width) (B is always 0)

  ;; Copy next sprite line to the sprite buffer
  ldir              ;; [6*C-1] Copy whole line of bytes from sprite to HWSprite data
  
  ;; Compute destination offset (DE += IXH)
  ld__c_ixh         ;; [2] C = Offset (HWSprite Width (16) - Sprite Width)
  ex  de, hl        ;; [1] Flip DE <-> HL for math purpose
  add hl, bc        ;; [3] Add the offset to the Destination Pointer (HWSprite data Pointer) 
  ex  de, hl        ;; [1] Restore the Destination Pointer to DE (HL <-> DE)  
  
  dec a             ;; [1] One less iteration to complete Sprite Height
  jr  nz, copy_loop ;; [2/3] Repeat copy_loop while A!=0

  ;; Return in binding
