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
;; Function: cpct_asicSetScrollVert
;;   Scroll vertically screen per pixel
;;  
;;  
;; C Definition:
;;    void cpct_asicSetScrollVert(<u8> *scroll_vert*) __z88dk_fastcall;
;;
;; Assembly call:
;;    > call cpct_asicSetScrollVert_asm
;;
;; Input Parameters (1 Bytes):
;;  (1B A) scroll_vert - in pixels (max 7 because 3-Bits value)
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Destroyed Register values: 
;;    A, D, L
;;
;; Required memory:
;;    C-binding   - 0 bytes
;;    ASM-binding - 0 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        |     16        |    64
;; Asm saving |     0         |    0
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld   d, l                   ;; [1] D = L (Save vertical offset)
   ld   hl, #ASIC_SSCR         ;; [3] HL = Address of Asic Soft Scroll Control Register
   rla                         ;; [1] Shift value left 4-Bits
   rla                         ;; [1] |
   rla                         ;; [1] |
   rla                         ;; [1] |
  
   ld   a, #0b10001111         ;; [2] Mask horizontal offset bits and set 3-Bits value
   and (hl)                    ;; [1] | X000 XXXX
   or   d                      ;; [1] | XVVV XXXX
   ld  (hl), a                 ;; [1] Save in SSCR
   
   ret                         ;; [3] Return