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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_asicSetScrollBorder
;;   Hide left border of screen for hardware scrolling
;;  
;;  
;; C Definition:
;;    void cpct_asicSetScrollBorder(<u8> *hide_border*) __z88dk_fastcall;
;;
;; Assembly call:
;;    > call cpct_asicSetScrollBorder
;;
;; Input Parameters (1 Bytes):
;;  (1B L) hide_border - (Hide = 1 / Show = 0)
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Destroyed Register values: 
;;    A, L
;;
;; Required memory:
;;    C-binding   - 0 bytes
;;    ASM-binding - 0 bytes
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

   ld   a,  l                  ;; [1]   A = L = hide_border
   ld   hl, #ASIC_SSCR         ;; [3]	HL = Address of Asic Soft Scroll Control Register
   set  7,  (hl)               ;; [2]   Hide border by default
   or   a                      ;; [1]   Return if hide_border != 0
   ret  nz                     ;; [2/3] |
   
   res  7,  (hl)               ;; [2]   Show border
   ret                         ;; [3]   Return