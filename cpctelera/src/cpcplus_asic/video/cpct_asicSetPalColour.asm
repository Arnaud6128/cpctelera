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
;;   Change one colour in the Asic palette
;;    
;;
;; C Definition:
;;    <void> cpct_asicSetPalColour(<u8> *colour_index*, <u16> *rgb*) __z88dk_callee
;;
;; Assembly call:
;;    > cpct_asicSetPalColour_asm
;;
;; Input Parameters (2 Bytes):
;;;  (1B A)  colour_index - Colour index (<16)
;;   (2B BC) rgb - Value in RGB (0x0GRB)
;;
;; Details:
;;	See *cpctm_rgbColour* for RGB conversion
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Destroyed Register values: 
;;    A, BC, HL
;;
;; Required memory:
;;    C-binding   - 15 bytes
;;    ASM-binding - 10 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        |      27       |    108
;; Asm saving |     -14       |    -56
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld   hl, #ASIC_PALETTE_COLOUR  ;; [3] HL = Address of Asic palette
   add  a                         ;; [1] | A = A + A -> Color is on 2-Bytes
   add  l                         ;; [1] | Compute address of color index
   ld   l, a                      ;; [1] | HL = HL + A*2
   
   ld   (hl), c                   ;; [2] | (HL) = B (0xRB)
   inc  l                         ;; [1] | L++
   ld   (hl), b                   ;; [1] | (HL) = C (0x0G)
   
   ret                            ;; [3] Return
   
  