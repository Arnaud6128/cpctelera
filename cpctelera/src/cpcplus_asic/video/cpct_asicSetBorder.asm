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
;;   Change screen border colour with RGB value (0x0GRB)
;;  
;;  
;; C Definition:
;;    <void>cpct_asicSetBorder(<u16> *border_color*) __fast_call;
;;
;; Assembly call:
;;    > call cpct_asicSetBorder_asm
;;
;; Input Parameters (2 Bytes):
;;  (2B HL) border_color - Border Color in RGB (0x0GRB)
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
;;    HL, DE
;;
;; Required memory:
;;    C-binding   - 7 bytes
;;    ASM-binding - 5 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        |     13        |    52
;; Asm saving |     -2       |     -8
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld  hl,   #ASIC_BORDER_COLOUR ;; [3]	HL = Address of Asic Color Border
   ld  (hl), d                   ;; [2] (HL) = (DE)
   inc l                         ;; [1] |
   ld  (hl), e                   ;; [2] |
   ret                           ;; [3] Return