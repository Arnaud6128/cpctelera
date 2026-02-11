;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; Function: cpct_doubleSpriteM0
;;
;;    Apply on Mode 0 sprite, scale x2 horizontally and vertically, transforming each 
;; source pixel into a 2x2 block of identical pixels. The function processes 
;; sprites stored in CPC Mode 0 format (2bpp, 2 pixels per byte) and outputs 
;; the enlarged sprite to a destination memory buffer.
;;
;; C Definition:
;;    void <cpct_doubleSpriteM0> (const <u8>* spr, <u8>* mem, 
;;                                      <u8> width, <u8> height) __z88dk_callee;
;;
;; Input Parameters (6 bytes):
;;  (2B  HL) spr     - Pointer to source sprite data in Mode 0 format
;;  (2B  DE) mem     - Pointer to destination buffer for enlarged sprite
;;  (1B   C) width   - Sprite width in bytes (>0) (Beware, not in pixels!)
;;  (1B   B) height  - Sprite height in pixels (= scanlines, >0)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_doubleSpriteM0_asm
;;
;; Parameter Restrictions:
;;  * spr must be an array containing sprite's pixels in CPC Mode 0 format 
;; (2 bits per pixel, 2 pixels per byte, 4 bits per pixel index). Pixels must 
;; be stored consecutively starting from top-left corner, going left-to-right 
;; and top-to-bottom. Total amount of bytes in the array must be width × height.
;;  * mem must point to a RAM buffer with at least 4×width×height free bytes.
;;  * width must be the sprite width in bytes (not pixels) and must be ≥1. 
;; In Mode 0: 1 byte = 2 pixels, therefore a 16-pixel wide sprite has width=8.
;; Using width=0 will cause undefined behaviour (DJNZ underflow).
;;  * height must be the sprite height in pixels (scanlines) and ≥1.
;; Using height=0 will cause undefined behaviour (IXH underflow).
;;  * Source and destination buffers must not overlap. Overlapping regions 
;; will cause corruption of source data during processing.
;;  * Source sprite must be stored in linear RAM format. Sprites directly 
;; extracted from CPC screen memory (with its split pixel layout) are NOT 
;; compatible and will produce corrupted output.
;;
;; Known limitations:
;;    * width or height values of 0 will cause infinite loops or erratic behaviour.
;;    * This function is Mode 0 specific (2bpp, 2px/byte). Using it with Mode 1 
;; or Mode 2 sprites will produce corrupted output.
;;    * This function cannot be run from ROM as it uses self-modifying code.
;;    * No boundary checks are performed on destination buffer. Writing beyond 
;; allocated memory may corrupt adjacent data or crash the program.
;;
;; Details:
;;    Mode 0 CPC format stores 2 pixels per byte (4 bits per pixel index):
;;      Source byte: [Pixel1: bits 7-4] [Pixel0: bits 3-0]
;;
;;    Processing steps per source byte:
;;      1. Extract left pixel (bits 7-4) using AND #0xF0, duplicate into full byte
;;      2. Extract right pixel (bits 3-0) using AND #0x0F, duplicate into full byte
;;      3. Write 2 bytes for current scanline (pixels doubled horizontally)
;;      4. After finishing a scanline, duplicate it vertically using LDIR
;;
;;    Output size: 1 source byte (2 pixels) → 4 output bytes (4 pixels wide × 
;;    2 scanlines high = 2×2 pixel block per source pixel).
;;
;; Register usage:
;;    Destroyed   : AF, BC, DE, HL, IX
;;
;; Required memory:
;;     C-bindings   - 98 bytes 
;;     ASM-bindings - 95 bytes 
;;
;; Time Measures:
;; (start code)
;;  Case      |    microSecs (us)       |    CPU Cycles
;; ----------------------------------------------------------------
;;  Formula   |   28 + 24S              |   112 + 96S
;; ----------------------------------------------------------------
;;  W=4,H=8   |        1084             |      4336
;;  W=8,H=16  |        3172             |     12688
;;  W=16,H=32 |       12484             |     49936
;; ----------------------------------------------------------------
;; (end code)
;;    S = size = width × height (total source bytes)
;;    Note: µs = cycles ÷ 4 (rounded to nearest integer)
;;    Output size = 4·S bytes (2× width, 2× height)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   push ix                      ;; [5] Save IX

   ld   a, c                   ;; [1] Save sprite width
   ld  (sprite_width), a       ;; [4] |
   
   add  a                      ;; [1] Sprite width double
   ld__ixl_a                   ;; [2] IXL = A (Width double)
   ld__ixh_b                   ;; [2] IXH = B (Height)

;; Sprite Height Loop
Loop_height:

sprite_width = .+1
    ld   b, #00                ;; [2] B = Sprite width

;; Sprite Width Loop
Loop_width:
	ld   a, (hl)               ;; [2] A = Current Byte
	and  #0b10101010           ;; [2] Get first pixel [AXCXBXDX]
	ld   c, a                  ;; [1] Double first pixel on first Byte
	srl	 a                     ;; [1] | A |= (C >> 1)
	or	 a, c                  ;; [1] | [AABBCCDD]

	ld  (de), a                ;; [2] Save Byte with pixel doubled
	inc  de                    ;; [2] Next Byte destination 

	ld   a, (hl)               ;; [2] A = Current Byte
	and  #0b01010101           ;; [2] Get second pixel [X1X2X3X4]
	ld	 c, a                  ;; [1] Double second pixel on second Byte
	add	 a, a                  ;; [1] | A |= (C << 1)
	or	 a, c                  ;; [1] | [11223344]

	ld	(de), a                ;; [2] Save Byte with pixel doubled
	inc  de                    ;; [2] Next Byte destination 

	inc	 hl                    ;; [2] Next Byte Sprite 
	djnz Loop_width            ;; [3/4] Decrement width continue if (B != 0)

;; Double line by copy current line	
	push de                    ;; [3] Save DE
	push hl                    ;; [3] Save HL
	
	ld   h, d                  ;; [1] HL = DE (Destination memory)
	ld   l, e                  ;; [1] |

	ld__c_ixl                  ;; [2] C = IXL (Width * 2)
	sbc  hl, bc                ;; [2] | 
	
	ldir                       ;; [4/5] Copy data
	
	pop  hl                    ;; [3] Restore HL
	pop  de                    ;; [3] Restore DE
	
	ex   de, hl                ;; [1] Destination : HL += Width * 2
	ld__c_ixl                  ;; [2] C = IXL (Width * 2)
	add  hl, bc                ;; [2] |
	ex   de, hl                ;; [1] | DE = Destination
	
	dec__ixh                   ;; [2] IXH-- (Height)
	jr   nz, Loop_height       ;; [2/3] Loop Height if (IXH != 0)
	
	pop  ix                    ;; [4] Restore IX
	ret                        ;; [3] Return to caller