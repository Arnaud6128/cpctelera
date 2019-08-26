;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2014-2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_memutils

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function:
;;    Fills up a complete sprite hardware with a given 1-Byte value
;;
;;
;; C Definition:
;;    void <cpct_asicSetSpriteData> (<u8> *hardware_sprite_id*, <u8> *value*) __z88dk_callee;
;;
;; Input Parameters (2 Bytes):
;;  (1B L) hardware_sprite_id - Hardware sprite identifier (0..15)
;;  (1B H) value - 1-Byte value to be set
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_asicSetSpriteData
;;
;;  * *hardware_sprite_id* hardware sprite identifier from 0 to 15
;;  * *value* could be any 1-Byte value
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Details:
;;    Sets all the bytes of a hardware sprite with *value*. 
;;    Adapted from *cpct_memset* see for more information about filling memory
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    C-binding   - 20 bytes
;;    ASM-binding - 17 bytes
;;
;; Time Measures: 
;; (start code)
;;   Case     | microSecs (us)  | CPU Cycles 
;; ------------------------------------------
;;   Any      | 28 + 16*6 = 124 |    496    
;; ------------------------------------------
;; Asm saving |     -10         |    -40    
;; ------------------------------------------
;; (end code)
;;    S = *size* (Number of total bytes to set)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld   a,   #ASIC_HW_SPRITE_DATA ;; [2] HWSprite Data address 0x40XX
   add  a,   l                    ;; [1] A = A + 0x100*L (L = HWSprite Id)
   ld   d,   a                    ;; [1] D = A -> DE = HWSprite data location (0x4X00)
   ld   e,   #0x00                ;; [2] E = 0x00
   
   ld   a,   h                    ;; [1] A = H (value to set)
   ld  (de), a                    ;; [2] Copy the value (A) to the first byte in the array
   ld   bc,  #0x00FF              ;; [3] BC = Sprite data size(255-Bytes as 1 byte has alread been copied)
   
   ;; Set up HL and DE for a massive copy of the Value to be set
   ld   h, d                      ;; [1] HL = DE (Points to 1st byte of the memory array to be filled up,
   ld   l, e                      ;; [1]      ... which already contains the value to be set)
   inc  e                         ;; [1] E++ (Points to the 2nd byte of the memory array to be filled up,
                                  ;;          ... where fitst byte will be copied)
								  
   ldir                           ;; [5/6] Copy the reset of the bytes, cloning the first one

   ret                            ;; [3] Return  
