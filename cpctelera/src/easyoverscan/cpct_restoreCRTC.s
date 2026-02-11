;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
.module cpct_easy_overscan

;; Global symbols
;;
.globl cpct_setCRTCReg_asm
.globl cpct_setVideoMemoryPage_asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_restoreCRTC
;;
;;    Restore CRTC with default CPC settings. 
;;  Set video to 80 bytes x 200 lines and video memory at 0xC000 - 0xFFFF
;;
;; C Definition:
;;    void <cpct_restoreCRTC> (void);
;;
;; Assembly call:
;;    > call cpct_restoreCRTC_asm
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    Code - 43 bytes
;;
;;    See *cpct_setStackLocation*, *cpct_setCRTCReg*, *cpct_setVideoMemoryPage*
;;    for informations.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_restoreCRTC::
cpct_restoreCRTC_asm:

   ;; --- Vertical Sync Setup ---
   ld c, #7                    ;; [2] CRTC Register 7 (Vertical Sync Position)
   ld b, #30                   ;; [2] Set V-Sync to 30 to center 200 lines
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Vertical Height Setup ---
   ld c, #6                    ;; [2] CRTC Register 6 (Vertical Displayed)
   ld b, #25                   ;; [2] 25 characters * 8 lines = 200 pixel lines
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Horizontal Position Setup ---
   ld c, #2                    ;; [2] CRTC Register 2 (Horizontal Sync Position)
   ld b, #46                   ;; [2] Position 46 for centering 40-char width
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Horizontal Width Setup ---
   ld c, #1                    ;; [2] CRTC Register 1 (Horizontal Displayed)
   ld b, #40                   ;; [2] 40 chars = 80 bytes wide
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Sync Pulse Width ---
   ld c, #3                    ;; [2] CRTC Register 3 (Horizontal and Vertical Sync Widths)
   ld b, #0x8E                 ;; [2] Standard values for default display
   call cpct_setCRTCReg_asm    ;; [P] Apply setting
   
   ld   l, #0x30               ;; [2] Configure pageC0 (0x30) | pageSize16Kb (0x00)
   call cpct_setVideoMemoryPage_asm ;; [P] Set video memory start = 0x0C000

   ret                         ;; [3] Return to caller