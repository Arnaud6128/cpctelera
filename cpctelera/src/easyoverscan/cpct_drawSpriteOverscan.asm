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
;; Function: cpct_drawSpriteOverscan
;;
;;    Copies a sprite from an array to overscan video memory.
;;
;; C Definition:
;;    void <cpct_drawSpriteOverscan> (u8* *sprite*, u8* *memory*, <u8> *width*, <u8> *height*) __z88dk_callee;
;;
;; Input Parameters (6 bytes):
;;  (2B HL) sprite - Source Sprite Pointer (array with pixel data)
;;  (2B DE) memory - Destination video memory pointer
;;  (1B C ) width  - Sprite Width in *bytes* [1-63] (Beware, *not* in pixels!)
;;  (1B B ) height - Sprite Height in bytes (>0)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawSpriteOverscan_asm
;;
;; Remarks:
;;     * Memory layout must be configurated with fonction *cpct_configureOverscan*
;;
;; Parameter Restrictions:
;;  * *sprite* must be an array containing sprite's pixels data in screen pixel format.
;; Sprite must be rectangular and all bytes in the array must be consecutive pixels, 
;; starting from top-left corner and going left-to-right, top-to-bottom down to the
;; bottom-right corner. Total amount of bytes in pixel array should be *width* x *height*.
;; You may check screen pixel format for mode 0 (<cpct_px2byteM0>) and mode 1 
;; (<cpct_px2byteM1>) as for mode 2 is linear (1 bit = 1 pixel).
;;  * *memory* could be any place in memory, inside or outside current video memory. It
;; will be equally treated as video memory (taking into account CPC's video memory 
;; disposition). This lets you copy sprites to software or hardware backbuffers, and
;; not only video memory.
;;  * *width* must be the width of the sprite *in bytes*, and must be in the range [1-63].
;; A sprite width outside the range [1-63] will probably make the program hang or crash, 
;; due to the optimization technique used. Always remember that the width must be 
;; expressed in bytes and *not* in pixels. The correspondence is:
;;    mode 0      - 1 byte = 2 pixels
;;    modes 1 / 3 - 1 byte = 4 pixels
;;    mode 2      - 1 byte = 8 pixels
;;  * *height* must be the height of the sprite in bytes, and must be greater than 0. 
;; There is no practical upper limit to this value. Height of a sprite in
;; bytes and pixels is the same value, as bytes only group consecutive pixels in
;; the horizontal space.
;;
;; Known limitations:
;;     * This function does not do any kind of boundary check or clipping. If you 
;; try to draw sprites on the frontier of your video memory or screen buffer 
;; if might potentially overwrite memory locations beyond boundaries. This 
;; could cause your program to behave erratically, hang or crash. Always 
;; take the necessary steps to guarantee that you are drawing inside screen
;; or buffer boundaries.
;;     * As this function receives a byte-pointer to memory, it can only 
;; draw byte-sized and byte-aligned sprites. This means that the box cannot
;; start on non-byte aligned pixels (like odd-pixels, for instance) and 
;; their sizes must be a multiple of a byte (2 in mode 0, 4 in mode 1 and
;; 8 in mode 2).
;;     * This function *will not work from ROM*, as it uses self-modifying code.
;;     * Although this function can be used under hardware-scrolling conditions,
;; it does not take into account video memory wrap-around (0x?7FF or 0x?FFF 
;; addresses, the end of character pixel lines).It  will produce a "step" 
;; in the middle of sprites when drawing near wrap-around.
;;
;; Details:
;;    This function copies a generic WxH bytes sprite from memory to a 
;; video-memory location (either present video-memory or software / hardware  
;; backbuffer). The original sprite must be stored as an array (i.e. with 
;; all of its pixels stored as consecutive bytes in memory). It only works 
;; for solid, rectangular sprites, with 1-63 bytes width
;;
;;    This function will just copy bytes, not taking care of colours or 
;; transparencies. If you wanted to copy a sprite without erasing the background
;; just check for masked sprites and <cpct_drawMaskedSprite>.
;;
;;    First 96 bytes encode the first screen pixel line (line 0), next 96 bytes encode pixel line 8,  
;; next 96 encode pixel line 16, and so on. Pixel line 1 start right next to pixel
;; line 200 (the last one on screen), then goes pixel line 9, and so on. 
;; 
;;    This particular distribution was thought to be used in 'characters' when it 
;; was conceived. As a character has 8x8 pixels, pixel lines have a distribution
;; in jumps of 8. This means that the screen has 34 character lines, each one
;; with 8 pixel lines. This distribution is shown at table 1, depicting memory 
;; locations where every pixel line starts, related to their character lines. 
;; (start code)
;; | Character |  Pixel |  Pixel |  Pixel |  Pixel |  Pixel |  Pixel |  Pixel |  Pixel |
;; |   Line    | Line 0 | Line 1 | Line 2 | Line 3 | Line 4 | Line 5 | Line 6 | Line 7 |
;; ---------------------------------------------------------------------------------------
;; |      1    | 0x8200 | 0x8A00 | 0x9200 | 0x9A00 | 0xA200 | 0xAA00 | 0xB200 | 0xBA00 |
;; |      2    | 0x8260 | 0x8A60 | 0x9260 | 0x9A60 | 0xA260 | 0xAA60 | 0xB260 | 0xBA60 |
;; |      3    | 0x82C0 | 0x8AC0 | 0x92C0 | 0x9AC0 | 0xA2C0 | 0xAAC0 | 0xB2C0 | 0xBAC0 |
;; |      4    | 0x8320 | 0x8B20 | 0x9320 | 0x9B20 | 0xA320 | 0xAB20 | 0xB320 | 0xBB20 |
;; |      5    | 0x8380 | 0x8B80 | 0x9380 | 0x9B80 | 0xA380 | 0xAB80 | 0xB380 | 0xBB80 |
;; |      6    | 0x83E0 | 0x8BE0 | 0x93E0 | 0x9BE0 | 0xA3E0 | 0xABE0 | 0xB3E0 | 0xBBE0 |
;; |      7    | 0x8440 | 0x8C40 | 0x9440 | 0x9C40 | 0xA440 | 0xAC40 | 0xB440 | 0xBC40 |
;; |      8    | 0x84A0 | 0x8CA0 | 0x94A0 | 0x9CA0 | 0xA4A0 | 0xACA0 | 0xB4A0 | 0xBCA0 |
;; |      9    | 0x8500 | 0x8D00 | 0x9500 | 0x9D00 | 0xA500 | 0xAD00 | 0xB500 | 0xBD00 |
;; |     10    | 0x8560 | 0x8D60 | 0x9560 | 0x9D60 | 0xA560 | 0xAD60 | 0xB560 | 0xBD60 |
;; |     11    | 0x85C0 | 0x8DC0 | 0x95C0 | 0x9DC0 | 0xA5C0 | 0xADC0 | 0xB5C0 | 0xBDC0 |
;; |     12    | 0x8620 | 0x8E20 | 0x9620 | 0x9E20 | 0xA620 | 0xAE20 | 0xB620 | 0xBE20 |
;; |     13    | 0x8680 | 0x8E80 | 0x9680 | 0x9E80 | 0xA680 | 0xAE80 | 0xB680 | 0xBE80 |
;; |     14    | 0x86E0 | 0x8EE0 | 0x96E0 | 0x9EE0 | 0xA6E0 | 0xAEE0 | 0xB6E0 | 0xBEE0 |
;; |     15    | 0x8740 | 0x8F40 | 0x9740 | 0x9F40 | 0xA740 | 0xAF40 | 0xB740 | 0xBF40 |
;; |     16    | 0x87A0 | 0x8FA0 | 0x97A0 | 0x9FA0 | 0xA7A0 | 0xAFA0 | 0xB7A0 | 0xBFA0 |
;; |     17*   | 0xC000 | 0xC800 | 0xD000 | 0xD800 | 0xE000 | 0xE800 | 0xF000 | 0xF800 |
;; |     18    | 0xC060 | 0xC860 | 0xD060 | 0xD860 | 0xE060 | 0xE860 | 0xF060 | 0xF860 |
;; |     19    | 0xC0C0 | 0xC8C0 | 0xD0C0 | 0xD8C0 | 0xE0C0 | 0xE8C0 | 0xF0C0 | 0xF8C0 |
;; |     20    | 0xC120 | 0xC920 | 0xD120 | 0xD920 | 0xE120 | 0xE920 | 0xF120 | 0xF920 |
;; |     21    | 0xC180 | 0xC980 | 0xD180 | 0xD980 | 0xE180 | 0xE980 | 0xF180 | 0xF980 |
;; |     22    | 0xC1E0 | 0xC9E0 | 0xD1E0 | 0xD9E0 | 0xE1E0 | 0xE9E0 | 0xF1E0 | 0xF9E0 |
;; |     23    | 0xC240 | 0xCA40 | 0xD240 | 0xDA40 | 0xE240 | 0xEA40 | 0xF240 | 0xFA40 |
;; |     24    | 0xC2A0 | 0xCAA0 | 0xD2A0 | 0xDAA0 | 0xE2A0 | 0xAAA0 | 0xF2A0 | 0xFAA0 |
;; |     25    | 0xC300 | 0xCB00 | 0xD300 | 0xDB00 | 0xE300 | 0xEB00 | 0xF300 | 0xFB00 |
;; |     26    | 0xC360 | 0xCB60 | 0xD360 | 0xDB60 | 0xE360 | 0xEB60 | 0xF360 | 0xFB60 |
;; |     27    | 0xC3C0 | 0xCBC0 | 0xD3C0 | 0xDBC0 | 0xE3C0 | 0xEBC0 | 0xF3C0 | 0xFBC0 |
;; |     28    | 0xC420 | 0xCC20 | 0xD420 | 0xDC20 | 0xE420 | 0xEC20 | 0xF420 | 0xFC20 |
;; |     29    | 0xC480 | 0xCC80 | 0xD480 | 0xDC80 | 0xE480 | 0xEC80 | 0xF480 | 0xFC80 |
;; |     30    | 0xC4E0 | 0xCCE0 | 0xD4E0 | 0xDCE0 | 0xE4E0 | 0xECE0 | 0xF4E0 | 0xFCE0 |
;; |     31    | 0xC540 | 0xCD40 | 0xD540 | 0xDD40 | 0xE540 | 0xED40 | 0xF540 | 0xFD40 |
;; |     32    | 0xC5A0 | 0xCDA0 | 0xD5A0 | 0xDDA0 | 0xE5A0 | 0xEDA0 | 0xF5A0 | 0xFDA0 |
;; |     33    | 0xC600 | 0xCE00 | 0xD600 | 0xDE00 | 0xE600 | 0xEE00 | 0xF600 | 0xFE00 |
;; |     34    | 0xC660 | 0xCE60 | 0xD660 | 0xDE60 | 0xE660 | 0xEE60 | 0xF660 | 0xFE60 |
;; ---------------------------------------------------------------------------------------
;; (*) Transition : (16 * 96) = 1536. Base 0x8200 + 1536 = 0x8800. 
;;     The next character line would start at 0x8200 + (17 * 96) = 0x8860.
;;     However, due to CRTC address wrapping, the 16K bank jump is reached earlier.
;;           Table 1 - Video memory starting locations for all pixel lines 
;; (end)
;;    *Note on how to interpret Table 1*: Table 1 contains starting video memory locations 
;; for all 272 pixel lines on the screen (with overscan configuration). To know where does 
;; a particular pixel line start, please read Table 1 left-to-right, top-to-bottom. So, 
;; ROW 1 at Table 1 contains the memory start locations for the first 8 pixel lines on 
;; screen (0 to 7), ROW 2 refers to pixel lines 8 to 15, ROW 3 has pixel lines 16 to 23, 
;; and so on.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;     C-bindings - 165 bytes
;;   ASM-bindings - 175 bytes
;;
;; Time Measures:
;; (start code)
;; ----------------------------------------------------------------
;;  Case      |   microSecs (us)        |        CPU Cycles
;; ----------------------------------------------------------------
;;  Setup     |         18              |            72
;;  Per Line  |      24 + 5W            |         96 + 20W
;;  Bank Gap  |        +16              |           +64
;; ----------------------------------------------------------------
;;  W=4,H=16  |         725             |           2900
;; ----------------------------------------------------------------
;; (end code)
;;  W = width in bytes, H = height in lines.
;;
;; Details:
;;    This function is specifically designed for Overscan screens (typically 
;;    96 bytes wide). It manages the complex memory layout of the CPC, 
;;    including the 8-line interleaving and the critical transition between
;;    the two 16K banks at 0xBFFF/0xC000. It uses Self-Modifying Code (SMC) 
;;    to skip LDIs, ensuring maximum copy speed.
;;    See *cpct_drawSprite* for more informations.
;;
;;  Credits:
;;    www.chibiakumas.com : Lesson S38 - Bitmap movement with Overscan on the CPC!
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Modify code using width to jump in drawSpriteWidth
   ld    a, #126               ;; [2] Base jump value (63 LDIs * 2 bytes each)
   sub   c                     ;; [1] Subtract width once
   sub   c                     ;; [1] Subtract width twice
   ld (ds_drawSpriteWidth), a  ;; [4] Modify JR instruction displacement

   ld    a, b                  ;; [1] A = Height counter
   ex    de, hl                ;; [1] HL = Sprite Source, DE = Screen Destination

ds_drawSpriteWidth_next:
   ex    de, hl                ;; [1] Exchange HL/DE to prepare for LDI copy
   push  de                    ;; [3] Save DE (Source) before copying line
                           
ds_drawSpriteWidth = .+1
   jr__0                       ;; [3] SMC: Jump forward to execute exactly C LDIs
   
   .rept 63
   ldi                         ;; [5] Copy byte (HL)->(DE), INC HL, INC DE, DEC BC
   .endm

   dec   a                     ;; [1] Line finished: decrement height counter
   pop   de                    ;; [3] Restore DE (Source pointer)
   ret   z                     ;; [2/4] If height reaches 0, return safely

   ex    de, hl                ;; [1] DE has destination, exchange with HL for math
  
   ;; Bank Gap Management
   ld    b, a                  ;; [1] Save Height counter into B
   ld    a, h                  ;; [1] Get current High byte of destination
   cp    #0xBF                 ;; [2] Are we at the end of the first 16K bank?
   jr    nz, check_boundaries  ;; [2/3] No: perform standard boundary check
   ld    a, l                  ;; [1] Get current Low byte of destination
   cp    #0xA0                 ;; [2] Is L at the Overscan boundary (96 bytes limit)?
   jr    nc, next_bank_line    ;; [2/3] Yes: handle transition to Bank 2 (0xC000)
     
check_boundaries:
   ld    a, #0x08              ;; [3] Interlace offset (next pixel line)
   add   h                     ;; [1] | Add 0x800 to HL
   ld    h, a                  ;; [1] |     
   and   #0x38                 ;; [2] Mask bits 13, 12, 11
   ld    a, b                  ;; [1] Restore Height counter into A
   jp    nz, ds_drawSpriteWidth_next ;; [3] If not 0, still within same 8-line block

   ;; Handle crossing 16K video memory boundaries (every 8 lines)
   ld    bc, #0xC060           ;; [3] Offset to next character row (-0x3F00 + 0x60)
   add   hl, bc                ;; [3] Adjust destination pointer
   jp    ds_drawSpriteWidth_next ;; [3] Continue drawing next line

next_bank_line:    
   ld    a, #0x60              ;; [2] Horizontal correction for Bank 2
   add   l                     ;; [1] Adjust Low byte
   ld    l, a                  ;; [1] Update L
   ld    a, b                  ;; [1] Restore Height counter into A
   jp    nc, ds_drawSpriteWidth_next ;; [3] Continue if no carry to H
   inc   h                     ;; [1] Increment H to sync bank address
   jp    ds_drawSpriteWidth_next ;; [3] Continue drawing next line
