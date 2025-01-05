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

;; Include Asic constants 
.include "../asic.s" 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   Restore default CRTC interrupt at 300hz and remove raster line interrupt
;;    
;; C Definition:
;;    <u16> cpct_asicRemoveLinesInterruptHandler();
;;
;; Assembly call:
;;   > call cpct_asicRemoveLinesInterruptHandlert_asm
;;
;; Return value:
;;   (u16, HL) - Previous interrupt code pointer located at 0x0039.
;;
;; Details:
;;  * Disable Asic interrupt line raster and remove interrupt handler
;;  * Adapted from *cpct_removeInterruptHandler* see for more informations
;;
;; Destroyed Register values: 
;;   A, DE, HL
;;
;; Required memory:
;;    21 bytes
;;
;; Time Measures:
;; (start code)
;; Case | microSecs(us) | CPU Cycles
;; -----------------------------------
;; Any  |      28       |     112
;; -----------------------------------
;; (end code)

.equ firmware_RST_jp, 0x38   ;; Memory address were a jump (jp) to the firmware code is stored.
.equ GA_port_byte,    0x7F   ;; 8-bit Port of the Gate Array

_cpct_asicRemoveLinesInterruptHandler::
cpct_asicRemoveLinesInterruptHandler_asm::
   di                             ;; [1] Disable interrupts
   ld   hl, (firmware_RST_jp+1)   ;; [5] Obtain pointer to the present interrupt handler
   ex   de, hl                    ;; [1] DE = HL (DE saves present pointer to previous interrupt handler)

   im   1                         ;; [2] Set Interrupt Mode 1 (CPU will jump to 0x38 when a interrupt occurs)
   ld   hl, #0xC9FB               ;; [3] FB C9 (take into account little endian) => EI : RET

   ld  (firmware_RST_jp), hl      ;; [5] Setup new "null interrupt handler" and enable interrupts again
   ei                             ;; [1] Reenable interrupts
   ex   de, hl                    ;; [1] HL = Pointer to previous interrupt handler (return value)
   
   xor  a                         ;; [1] Reset CRTC default interrupt at 300hz
   ld  (#ASIC_RASTER_INT), a      ;; [4] | by setting asic raster interrupt to 0

   ret                            ;; [3] Return