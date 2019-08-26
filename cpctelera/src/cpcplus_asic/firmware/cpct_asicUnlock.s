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
;;   Unlock ASIC by sending code sequence to CRTC
;;    
;; C Definition:
;;    <void> cpct_asicUnlock();
;;
;; Assembly call:
;;    > call cpct_asicUnlock_asm
;;
;; Destroyed Register values: 
;;    A, BC, HL, D
;;
;; Required memory:
;;    13 bytes
;;
;; Time Measures:
;; (start code)
;; Case |  microSecs(us)  | CPU Cycles
;; ------------------------------------
;; Any  |   13+11*17=200  |    800
;; ------------------------------------
;; (end code)
;;
;; Credits:
;;  Adapted for CPCTelera from http://www.cpctech.org.uk/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_asicUnlock::
cpct_asicUnlock_asm::
   di                  ;; [1] Disable interruptions
   ld   hl, #asic_code ;; [3] HL = Address of Asic unlock code
   ld   d,  #17        ;; [2] D = 17 Size of the Asic code
   ld   bc, #0xBC00    ;; [3] CRTC Port address
unlock:  
   ld   a,  (hl)       ;; [2] A = (HL) asic code sequence array
   out  (c), a         ;; [4] Send to port
   inc  hl             ;; [2] Next Byte of Array
   dec  d              ;; [1] D-- remaining data to read
   jp   nz, unlock     ;; [2/3] Test if all asic code is read
   ei                  ;; [1] Enable interruptions
   ret                 ;; [3] Return
 
asic_code:: .db 255,0,255,119,179,81,168,212,98,57,156,70,43,21,138,205,238