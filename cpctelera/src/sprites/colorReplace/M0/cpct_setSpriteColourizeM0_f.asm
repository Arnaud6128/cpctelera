;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_sprites

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_setSpriteColourizeM0
;;
;;    Sets colours to be used when <cpct_spriteColourizeM0> gets called. It sets
;; both colour to be replaced (*oldColour*) and replacement colour (*newColour*).
;;
;; C Definition:
;;    void <cpct_setSpriteColourizeM0> (<u8> *oldColour*, <u8> *newColour*) __z88dk_callee;
;;
;; Input Parameters (6 bytes):
;;  (1B L )  oldColour    - Colour to be replaced (Palette Index, 0-15)
;;  (1B H )  newColour    - New colour (Palette Index, 0-15)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_setSpriteColourizeM0_asm
;;
;; Parameter Restrictions:
;;  * *oldColour* must be the palette index of the colour to be replaced (0 to 15).
;;  * *newColour* must be the palette index of the new colour (0 to 15).
;;
;; Known limitations:
;;     * This function works from ROM, but <cpct_spriteColourizeM0> must 
;; be in RAM, as it gets modified by this function.
;;
;; Details:
;;    This function sets the colours that <cpct_spriteColourizeM0> will use 
;; internally when called. Concretely, it has to set two colours: and *oldColour*
;; that will be searched and replaced, and a *newColour* that will be inserted
;; where *oldColours* are found. The function has to be called at least once 
;; before using <cpct_spriteColourizeM0> in order for it to actually perform 
;; any colour replacement. 
;; 	It works by modifying <cpct_spriteColourizeM0>'s machine code, changing
;; values of *oldColour* and *newColour*. Therefore, the change is permanent
;; until a new change is performed. So you may call this function once and 
;; then perform many sprite colour changes by calling many times to
;; <cpct_spriteColourizeM0>. You may see an use example by consulting 
;; <cpct_spriteColourizeM0>'s documentation.
;;
;; Destroyed Register values: 
;;    A, BC, HL
;;
;; Required memory:
;;     C-bindings - 37 bytes
;;   ASM-bindings - 35 bytes
;;
;; Time Measures:
;; (start code)
;;  Case      |   microSecs (us)       |        CPU Cycles
;; ----------------------------------------------------------------
;;   Any      |          52            |        208
;; ----------------------------------------------------------------
;; Asm saving |          -9            |        -36
;; ----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes
;;
;; Credits:
;;    Original routine optimized by @Docent and discussed in CPCWiki :
;; http://www.cpcwiki.eu/forum/programming/cpctelera-colorize-sprite/
;;
;; Thanks to all of them for their help and support.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.globl dc_mode0_ct                ;; Look-Up-Table to convert Palette Indexes to 4-bits pixel 1 screen format patterns
.include "macros/cpct_luts.h.s"   ;; Macros to easily access the Look-Up-Table
;; Symbols for placeholders inside the Colourize function
.globl cpct_spriteColourizeM0_px1_newval
.globl cpct_spriteColourizeM0_px0_newval
.globl cpct_spriteColourizeM0_px1_oldval
.globl cpct_spriteColourizeM0_px0_oldval

 ;; Use Look-Up-Table to convert palette index colour to screen pixel format
 ;; This conversion is for the Pixel 1 into the two pixels each byte has in mode 0 [0,1]
 ;; Therefore, only bits x0x2x1x3 will be produced.

 ;; Convert newColour to pixel format 
 ld a, h                                   ;; [1]  A = H new colour index
 cpctm_lutget8 dc_mode0_ct, b, c           ;; [10] Get from Look-Up-Table dc_mode0_ct[BC + A]
 ld (cpct_spriteColourizeM0_px1_newval), a ;; [4]  Write Pixel 1 format (x0x2x1x3) into Colourize function code
 rlca                                      ;; [1]  Convert Pixel 1 format to Pixel 0, shifting bits to the left
 ld (cpct_spriteColourizeM0_px0_newval), a ;; [4]  Write Pixel 0 format (0x2x1x3x) into Colourize function code

 ;; Convert oldColour to pixel format 
 ld a, l                                   ;; [1]  A = L old colour index
 cpctm_lutget8 dc_mode0_ct, b, c           ;; [10] Get from Look-Up-Table dc_mode0_ct[BC + A]
 ld (cpct_spriteColourizeM0_px1_oldval), a ;; [4]  Write Pixel 1 format (x0x2x1x3) into Colourize function code
 rlca                                      ;; [1]  Convert Pixel 1 format to Pixel 0, shifting bits to the left
 ld (cpct_spriteColourizeM0_px0_oldval), a ;; [4]  Write Pixel 0 format (0x2x1x3x) into Colourize function code

ret         ;; [3] Return to the caller
