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
;;   Copy array of sprite data to location of hardware sprite data
;;    
;;
;; C Definition:
;;    <void> cpct_asicCopySpriteData(<u8> *hardware_sprite_id*, <const u8*> *sprite_array*) __z88dk_callee;
;;
;; Assembly call:
;;    > call cpct_asicCopySpriteData_asm
;;
;; Input Parameters (3 Bytes):
;;  (1B C)  hardware_sprite_id - Hardware sprite identifier (0..15)
;;  (2B HL) sprite_array - Pointer to the start of the array of sprite data
;;
;; Parameter Restrictions:
;;  * *hardware_sprite_id* hardware sprite identifier from 0 to 15
;;  * *sprite_array* must be an array containing sprite's pixels data. 
;; 1-Byte per pixel : 0b0000cccc (4-bits used for 16 colours indexed)
;; Sprite must be rectangular and all bytes in the array must be consecutive pixels, 
;; starting from top-left corner and going left-to-right, top-to-bottom down to the
;; bottom-right corner. Total amount of bytes is fixed (16x16) 256-Bytes.
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    C-binding   - 49 bytes
;;    ASM-binding - 45 bytes
;;
;; Time Measures:
;; (start code)
;; Case       |  microSecs(us)  | CPU Cycles
;; ------------------------------------------
;; Any        | 24+16*83 = 1352 |   5408‬
;; Asm saving |      -13        |   -52
;; ------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld   a, #ASIC_HW_SPRITE_DATA ;; [2] HWSprite Data address 0x40(XX)
   add  a, c                    ;; [1] A = A + 0x100*C (Sprite Data : 256-Bytes)
   ld   d, a                    ;; [1] DE = HWSprite data location (0x4X00)
   ld   e, #0x00                ;; [2] | E = 0x00
   
   ld   a, #16                  ;; [2] A = Sprite Hard Height (16)
   
loop_copy_sprite_hw:            ;; Copy 16-Bytes row
   ldi                          ;; | [5*16] (DE++) = (HL++)
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   ldi                          ;; | 
   
   dec a                        ;; [1] A--
   jp nz, loop_copy_sprite_hw   ;; [2/3] Test if All Sprites Bytes are copied
  
   ret                          ;; [3] Return     