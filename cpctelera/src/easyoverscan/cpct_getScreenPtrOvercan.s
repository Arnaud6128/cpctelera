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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_getScreenPtrOvercan
;;
;;     Calculates a video memory pointer for Amstrad CPC overscan modes.
;;     Uses a threshold check to switch between memory banks and computes
;;     the interlaced address based on y-coordinate.
;;
;; C Definition:
;;     u8* cpct_getScreenPtrOvercan(u8 x, u16 y) __z88dk_callee;
;;
;; Input Parameters (3 bytes):
;;   (1B A ) x - Byte-aligned column [0-96]
;;   (2B DE) y - Row coordinate [0-272]
;;
;; Assembly call (Input parameters on registers):
;;     > call cpct_getScreenPtrOvercan_asm
;;
;; Destroyed Register values: 
;;     AF, BC, DE, HL
;;
;; Required memory:
;;    64 bytes
;;
;; Details:
;;    Calculates screen address for Overscan 96x272.
;;    Base address: 0x8200 (Bank 1) or 0xC000 (Bank 2 if y >= 128).
;;    Formula: Base + (96 * (y/8)) + (2048 * (y%8)) + x
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Time Measures:
;; (start code)
;;   Case            | microSecs (us) | CPU Cycles (T-States)
;;  ---------------------------------------------------------
;;   x=0, y=10 (Min) |       46       |          184
;;   x=0, y=130(Max) |       48       |          192
;;  ---------------------------------------------------------
;; (end code)
;;  W = width in bytes, H = height in lines.
;;
;;  Credits:
;;    http://www.chibiakumas.com
;;    Lesson S38 : Bitmap movement with Overscan on the CPC!
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HIGH_VMEM_LOC = 0xC0
LOW_VMEM_LOC  = 0x82

_cpct_getScreenPtrOverscan:: 
cpct_getScreenPtrOverscan_asm:: 
    ld   c, a               ;; [1] Save A (x) in C
    
    ;; --- Check if y >= 128 ---
    ld   a, e               ;; [1] Get low byte of y
    sub  #0x80              ;; [2] Subtract 128 (immediate value)
    ld   a, d               ;; [1] Get high byte of y
    sbc  #0x00              ;; [2] Subtract carry to finish comparison
    jr    c, Low_bank_location ;; [2/3] Jump if y < 128

    ;; --- Case y >= 128: y -= 128 ---
    ex   de, hl             ;; [1] HL = y, DE = 128-y (garbage)
    ld   de, #-128          ;; [3]
    add  hl, de             ;; [3] HL = y - 128
    ex   de, hl             ;; [1] DE = y - 128
    ld   b, #HIGH_VMEM_LOC  ;; [2] Set bank 0xC0
    jr   Compute_address    ;; [3]
    
Low_bank_location:
    ;; --- Case y < 128 ---
    ld   b, #LOW_VMEM_LOC   ;; [2] Load low bank address (0x82) into B
    
Compute_address:
    ;; --- Calculate div = y / 8 (16-bit shift) ---
    ld   l, e               ;; [1] HL = DE (y)
    ld   h, d               ;; [1] |
    srl  h                  ;; [2] Logical Shift Right H
    rr   l                  ;; [2] Rotate Right L through carry
    srl  h                  ;; [2] Repeat shift (2/3)
    rr   l                  ;; [2] |
    srl  h                  ;; [2] Repeat shift (3/3)
    rr   l                  ;; [2] HL now contains y / 8

    ;; --- Calculate modulo = y % 8 ---
    ld   a, e               ;; [1] Get original y_low from E
    and  #0x07              ;; [2] Mask to get 3 lower bits (modulo 8)
    
    ;; --- Calculate offset = 2048 * modulo ---
    add  a, a               ;; [1] modulo * 2
    add  a, a               ;; [1] modulo * 4
    add  a, a               ;; [1] modulo * 8

    ;; --- Calculate offset1 = 96 * div ---
    ld   e, l               ;; [1] DE = div / 0
    ld   d, #0x00           ;; [2] |
    ld   h, d               ;; [1] Clear H
    add  hl, hl             ;; [3] div * 2
    add  hl, de             ;; [3] div * 3
    add  hl, hl             ;; [3] div * 6
    add  hl, hl             ;; [3] div * 12
    add  hl, hl             ;; [3] div * 24
    add  hl, hl             ;; [3] div * 48
    add  hl, hl             ;; [3] div * 96 (= offset1)

    ;; --- Final Result: vmem + 96 * ((u8)(y / 8)) + 2048 * (y % 8) + x ---
    add  b                  ;; [1] Add bank high byte (B) to (modulo * 8)
    ld   b, a               ;; [1] Store in B (B = high byte of base + t)
    add  hl, bc             ;; [3] HL = offset1 + (High_Adjusted | x)

    ex   de, hl             ;; [1] Set result in DE
    ret                     ;; [3] Return to caller