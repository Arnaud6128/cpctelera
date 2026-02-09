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
;; Function: cpct_configureOverscan
;;
;;    Configure CRTC in order to have 96 x 272 video resolution.
;;    Sets an active area of 48 characters wide and 34 characters high.
;;
;; C Definition:
;;    void <cpct_configureOverscan> (void);
;;
;; Assembly call:
;;    > call cpct_configureOverscan_asm
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    Code - 43 bytes
;;
;; Known limitations:
;;    The video memory area is configure from 0x8200 to 0xFFFF
;;    YOU HAVE TO CHANGE stack location (with cpct_setStackLocation)
;;    because stack is overwrite by video data.
;;  
;; Details:
;;    Configures the 6845 CRTC registers to extend the display area.
;;    R1 = 48 (96 bytes wide), R6 = 34 (272 lines high).
;;    Screen memory starts at 0x8200, causing a bank wrap-around
;;    at character line 17.
;;
;;    See *cpct_setStackLocation*, *cpct_setCRTCReg*, *cpct_setVideoMemoryPage*
;;    for informations.
;;
;;  Credits:
;;    www.chibiakumas.com : Lesson S38 - Bitmap movement with Overscan on the CPC!
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_cpct_configureOverscan::
cpct_configureOverscan_asm:

   ;; --- Vertical Sync Setup ---
   ld c, #7                    ;; [2] CRTC Register 7 (Vertical Sync Position)
   ld b, #35                   ;; [2] Set V-Sync to 35 to center 272 lines
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Vertical Height Setup ---
   ld c, #6                    ;; [2] CRTC Register 6 (Vertical Displayed)
   ld b, #34                   ;; [2] 34 characters * 8 lines = 272 pixel lines
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Horizontal Position Setup ---
   ld c, #2                    ;; [2] CRTC Register 2 (Horizontal Sync Position)
   ld b, #50                   ;; [2] Position 50 for centering 48-char width
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Horizontal Width Setup ---
   ld c, #1                    ;; [2] CRTC Register 1 (Horizontal Displayed)
   ld b, #48                   ;; [2] 48 chars = 96 bytes wide
   call cpct_setCRTCReg_asm    ;; [P] Apply setting

   ;; --- Sync Pulse Width ---
   ld c, #3                    ;; [2] CRTC Register 3 (Horizontal and Vertical Sync Widths)
   ld b, #0x8C                 ;; [2] Standard values for stable overscan display
   call cpct_setCRTCReg_asm    ;; [P] Apply setting
   
   ld   l, #0x2D               ;; [2] Configure page80 | pageSize32Kb | Offset memory
   call cpct_setVideoMemoryPage_asm ;; [P] Set video memory start = 0x8200

   ret                         ;; [3] Return to caller