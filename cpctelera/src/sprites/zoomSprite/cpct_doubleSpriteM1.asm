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
;; Function: cpct_doubleSpriteM1
;;
;;    Apply Mode 1 sprite, scale x2 horizontally and vertically, transforming each 
;; source pixel into a 2x2 block of identical pixels. The function processes 
;; sprites stored in CPC Mode 1 format (2bpp, 4 pixels per byte) and outputs 
;; the enlarged sprite to a destination memory buffer.
;;
;; C Definition:
;;    void <cpct_doubleSpriteM1> (const <u8>* spr, <u8>* mem, 
;;                                      <u8> width, <u8> height) __z88dk_callee;
;;
;; Input Parameters (5 bytes):
;;  (2B  HL) spr       - Pointer to source sprite data in Mode 1 format
;;  (2B  DE) mem       - Pointer to destination memory buffer for enlarged sprite
;;  (1B   C) width     - Sprite width in bytes (>0) (Beware, not in pixels!)
;;  (1B   B) height    - Sprite height in bytes (>0)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_doubleSpriteM1_asm
;;
;; Parameter Restrictions:
;;  * sprite must be an array containing sprite's pixels in CPC Mode 1 format 
;; (2 bits per pixel, 4 pixels per byte). Pixels must be stored consecutively 
;; starting from top-left corner, going left-to-right and top-to-bottom. Total 
;; amount of bytes in the array must be w × h.
;;  * memory may point to any RAM location (sprite buffer or temporary buffer).
;;  The function writes 2×w bytes per scanline and produces 
;; 2×h scanlines of output (total size = 4×w×h bytes).
;;  * w must be the sprite width in bytes (not pixels) and must be ≥1. 
;; In Mode 1: 1 byte = 4 pixels, therefore a 16-pixel wide sprite has w=4.
;; Using w=0 will cause undefined behaviour (IXL underflow).
;;  * h must be the sprite height in bytes (equal to pixel height) and ≥1. 
;; Using h=0 will cause undefined behaviour (IXH underflow).
;;  * Source and destination buffers must not overlap. Overlapping regions 
;; will cause corruption of source data during processing.
;;
;; Known limitations:
;;    * w or h values of 0 will cause infinite loops (IXL/IXH underflow to 255).
;;    * This function is Mode 1 specific (2bpp). Using it with Mode 0 or Mode 2 
;; sprites will produce corrupted output.
;;    * This function cannot be run from ROM as it uses self-modifying code 
;; (patching of LD BC,#0000 instruction at runtime).
;;    * No boundary checks are performed on destination buffer. Writing beyond 
;; allocated memory may corrupt adjacent data or crash the program.
;;    * Performance degrades linearly with sprite dimensions. Very large sprites 
;; (>64×64 bytes) may cause visible slowdown in real-time applications.
;;
;; Details:
;;    The function processes each source byte (containing 4 Mode 1 pixels) and 
;; expands it into 4 output bytes (representing a 2×2 pixel block per source pixel):
;;      Source byte format: [P3 P2 P1 P0 | P3 P2 P1 P0]  (two identical nybbles)
;;      Output for 1 byte:  4 bytes forming a 2 scanlines × 8 pixels block
;;
;;    Processing steps per source byte:
;;      1. Extract each of the 4 pixels using bitmasks
;;      2. Duplicate each pixel horizontally (bit replication within byte)
;;      3. Write 2 bytes for current scanline (pixels doubled horizontally)
;;      4. After finishing a scanline, duplicate it vertically using LDIR
;;
;; Register usage:
;;    Destroyed   : AF, BC, DE, HL
;;
;; Required memory:
;;     C-bindings   - 131 bytes 
;;     ASM-bindings - 128 bytes 
;;
;; Time Measures:
;; (start code)
;;  Case      |    microSecs (us)       |    CPU Cycles
;; ----------------------------------------------------------------
;;  Formula   |   19 + 31H + 62WH       |   76 + 123H + 246WH
;; ----------------------------------------------------------------
;;  W=4,H=8   |        2233             |      8932
;;  W=8,H=16  |        8383             |     33532
;;  W=16,H=32 |       32491             |    129964
;; ----------------------------------------------------------------
;; (end code)
;;    W = w (width in bytes), H = h (height in bytes)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   push ix                      ;; [5] Save IX
   
   ld__ixh_b                    ;; [2] IXH = B (Height)
   ld   a, c                    ;; [1] Save sprite width
   ld  (sprite_width), a        ;; [4] |
   
   add  a                       ;; [1] Save sprite width double
   ld  (sprite_width_double), a ;; [4] |

;; Sprite Height Loop
Loop_height:

sprite_width = .+2
    ld__ixl #00                ;; [3] IXL = Sprite width

;; Sprite Width Loop
Loop_width:
	;; Pixel A
	ld   a, (hl)               ;; [2] A = Current Byte  [AB12AB12]
	and  #0b10001000           ;; [2] Get first pixel   [AXXXAXXX]
	ld   c, a                  ;; [1] Double first pixel on first Byte
	srl	 a                     ;; [1] | A |= (C >> 1) : [XAXXAXXX]
	or	 c                     ;; [1] | [AAXXAAXX]
	ld   b, a                  ;; [1] | B = [AAXXAAXX]
	
	;; Pixel B
	ld   a, (hl)               ;; [2] A = Current Byte  [AB12AB12]
	and  #0b01000100           ;; [2] Get second pixel  [XBXXXBXX]
	srl	 a                     ;; [1] | A |= (C >> 1) : [XXBXXBXX]
	ld   c, a                  ;; [1] Double first pixel on first Byte
	srl	 a                     ;; [1] | A |= (C >> 1) : [XXXBXXBX]
	or	 c                     ;; [1] | [XXBBXXBB]
	or   b                     ;; [1] | [AABBAABB]
	
	ld  (de), a                ;; [2] Save Byte with pixel doubled
	inc  de                    ;; [2] Next Byte destination 

    ;; Pixel 1
	ld   a, (hl)               ;; [2] A = Current Byte [AB12AB12]
	and  #0b00100010           ;; [2] Get second pixel [XX1XXX1X]
	sla	 a                     ;; [1] | A |= (C << 1)  [X1XXX1XX]
	ld	 c, a                  ;; [1] Double second pixel on second Byte
	sla	 a                     ;; [1] | A |= (C << 1)  [1XXX1XXX]
	or	 c                     ;; [1] | [11XX11XX]
	ld   b, a                  ;; [1] | Save B = [11XX11XX]

    ;; Pixel 2	
	ld   a, (hl)               ;; [2] A = Current Byte [AB12AB12]
	and  #0b00010001           ;; [2] Get second pixel [XXX2XXX2]
	ld	 c, a                  ;; [1] Double second pixel on second Byte
	sla	 a                     ;; [1] | A |= (C << 1)  [XX2XXX2X]
	or	 c                     ;; [1] | [XX22XX22]
	or   b                     ;; [1] | [11221122]

	ld	(de), a                ;; [2] Save Byte with pixel doubled
	inc  de                    ;; [2] Next Byte destination 
	inc	 hl                    ;; [2] Next Byte Sprite 
	
	dec__ixl                   ;; [2] IXL-- Decrement width
	jr nz, Loop_width          ;; [3/4] Continue if (IXL != 0)

;; Double line by copy current line
	push de                    ;; [3] Save DE
	push hl                    ;; [3] Save HL
	
	ld   h, d                  ;; [1] HL = DE (Destination memory)
	ld   l, e                  ;; [1] |

sprite_width_double = .+1
	ld   bc, #0000             ;; [3] HL -= Width * 2
	ld   a, c                  ;; [1] | Save A = Width * 2
	sbc  hl, bc                ;; [2] | 
	
	ldir                       ;; [4/5] Copy data
	
	pop  hl                    ;; [3] Restore HL
	pop  de                    ;; [3] Restore DE
	
	ex   de, hl                ;; [1] Destination : HL += Width * 2
	ld   c, a                  ;; [1] |
	add  hl, bc                ;; [2] |
	ex   de, hl                ;; [1] | DE = Destination
	
	dec__ixh                   ;; [2] IXH-- (Height)
	jr   nz, Loop_height       ;; [2/3] Loop Height if (IXH != 0)
	
	pop  ix                    ;; [4] Restore IX
	ret                        ;; [3] Return to caller