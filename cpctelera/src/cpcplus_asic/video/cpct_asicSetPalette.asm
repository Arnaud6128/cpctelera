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
;;   Set the Asic Palette colour values
;;    
;;
;; C Definition:
;;   <void> cpct_asicSetPalette(<u16*> *rgb_array*, <u16> *size*) __z88dk_callee;
;;
;; Assembly call:
;;    > call cpct_asicSetPalette_asm
;;
;; Input Parameters (2 Bytes):
;;  (2B HL) rgb_array - Array of rgb colours (0x0GRB)
;;  (1B E)  size - Size of the array (<=16)
;;
;; Parameter Restrictions:
;;  * *rgb_array* array of rgb values (0x0GRB)
;;  * *size* number of rgb entries to set (<=16)  
;;
;; Details:
;;	See *cpctm_rgbColour* for macro RGB conversion
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Destroyed Register values: 
;;    A, BC, DE, HL
;;
;; Required memory:
;;    C-binding   - 21 bytes
;;    ASM-binding - 17 bytes
;;
;; Time Measures:
;; (start code)
;; Case       |  microSecs(us) |  CPU Cycles
;; -------------------------------------------
;; Any        |    19 + 8S     |   76 + 32S
;; Asm saving |      -13       |    -52
;; -------------------------------------------
;; (end code)
;;    S = *size* (Number of rgb entries to set)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
   ld   bc, #ASIC_PALETTE_COLOUR  ;; [3] HL = Address of Asic Palette

asicSetRgbLoop:   
   ld   a, (hl)                   ;; [2] D = Get Color value (rgb) from array
   inc  hl                        ;; [2] HL++, Point to the next RGB in the array
   ld   d, (hl)                   ;; [2] A = Get Color value (rgb) from array
   inc  hl                        ;; [2] HL++, Point to the next RGB in the array
   
   ld   (bc), a                   ;; [2] BC = A (0xR0)
   inc  c                         ;; [1] C++
   ld   a, d                      ;; [1] A = D (0xBG)
   ld   (bc), a                   ;; [2] BC = A (0xBG)
   inc  c                         ;; [1] C++
   
   dec  e                         ;; [1] E-- (Next Palette index to be set)
   jp   nz, asicSetRgbLoop        ;; [2/3] If more than 0 RGBs to be set then continue
   
   ret                            ;; [3] Return