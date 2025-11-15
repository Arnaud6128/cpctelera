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
;;   Set hardware sprite zoom for width and height
;;
;; C Definition:
;;    <void> cpct_asicSetSpriteZoom(<u8> *hardware_sprite_id*, <u8> *zoom_x*, <u8> *zoom_y*) __z88dk_callee;  
;;
;; Assembly call:
;;   > call cpct_asicSetSpriteZoom_asm
;;
;; Input Parameters (3 Bytes):
;;   (1B A) hardware sprite id - Hardware sprite identifier (0..15)
;;   (1B L) zoom on X of sprite - sprite width magnification
;;   (1B H) zoom on Y of sprite - sprite height magnification
;;
;; Parameter Restrictions:
;;   * *hardware sprite id* hardware sprites identifier from 0 to 15
;;   * *zoom_x* set width magnification (0 to 3) 
;;   * *zoom_y* set height magnification (0 to 3) 
;;
;; Requirements and limitations:
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;
;; Details:
;;   If magnification of width or height are set to 0, the hardware sprite will *not* be visible
;;
;; Destroyed Register values: 
;;    AF, BC, HL
;;
;; Required memory:
;;     C-bindings - 21 bytes
;;   ASM-bindings - 16 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Any        |      17       |     68
;; Asm saving |      -5       |    -20
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   add a, a                      ;; [1] | A = A * 8 (offset for Sprite configuration)
   add a, a                      ;; [1] |
   add a, a                      ;; [1] |
   add a, #ASIC_OFFS_CONFIG_ZOOM ;; [2] A = A + 4 (offset for Zoom)
      
   ld  b, #ASIC_HW_SPRITE_CONFIG ;; [2] | BC = HWSprite configuration address 0x60XX
   ld  c, a                      ;; [1] |
   
   ld a, l                       ;; [1] A = L (ZoomY) : Zoom X and Y are on 2-Bits 0b0000XXYY
   sla a                         ;; [1] A << 1 : 0b00000XX0
   sla a                         ;; [1] A << 1 : 0b0000XX00
   or  h                         ;; [1] A |= H : 0b0000XXYY (H = ZoomY) 
   ld (bc), a                    ;; [2] (BC) = A (ZoomX and ZoomY)
   
   ret                           ;; [3] Return