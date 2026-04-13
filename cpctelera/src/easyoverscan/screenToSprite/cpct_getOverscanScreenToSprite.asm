;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud BOUCHE
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
.module cpct_easy_overscan

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_getOverscanScreenToSprite
;;
;;    Copies sprite data from overscan screen video memory to a linear array (a sprite)
;;
;; C Definition:
;;    void <cpct_getOverscanScreenToSprite> (void* *memory*, void* *sprite*, <u8> *width*, <u8> *height*) __z88dk_callee;
;;
;; Input Parameters (6 bytes):
;;  (2B HL) memory - Source Screen Address (Video memory location)
;;  (2B DE) sprite - Destination Sprite Address (Sprite data array)
;;  (1B C ) width  - Sprite Width in *bytes* (>0) (Beware, *not* in pixels!)
;;  (1B B ) height - Sprite Height in bytes (>0)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_getOverscanScreenToSprite_asm
;;
;; Remarks:
;;     * Memory layout must be configurated with fonction *cpct_configureOverscan*
;;
;; Parameter Restrictions:
;;  * *memory* could be any place in memory, inside or outside current video memory. It
;; will be equally treated as video memory (taking into account CPC's video memory 
;; disposition). This lets you copy software or hardware backbuffers, and
;; not only video memory.
;;  * *sprite* must be a pointer to the start of a linear array that will be filled
;; up with sprite pixel data got from *memory*.
;;  * *width* must be the width of the screen to capture *in bytes*, and 
;; must be greater than 0. A 0 as *width* parameter will be considered as 65536,  
;; making this function overwrite the whole memory, making your program crash.
;;  * *height* must be the height of the sprite in bytes, and must be greater than 0. 
;; A 0 as *height* parameter will be considered as 256 (the maximum value). 
;; Height of a sprite in bytes and pixels is the same value, as bytes only group 
;; consecutive pixels in the horizontal space.
;;
;; Known limitations:
;;    * This function does not do any kind of boundary check or clipping. If you 
;; get data beyond your video memory or screen buffer the sprite will also contains 
;; not video data.
;;    * This function uses self-modifying code, so it cannot be used from ROM.
;;
;; Details:
;;    Reads screen video memory data at *memory* and copies it to a linear array (a *sprite*). 
;; The copy takes into account CPC's video memory disposition, which is comprised of character
;; lines made by 8-pixel lines each. The copy converts this disposition to linear, putting
;; each sprite line contiguous to the previous one in the resulting *sprite* array. After 
;; this copy, *sprite* can be used as any other normal sprite through sprite drawing functions
;; like <cpct_drawOverscanSprite>.
;;
;; See <cpct_getScreenToSprite> for further informations
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    C-bindings - 41 bytes
;;  ASM-bindings - 36 bytes
;;
;; Time Measures:
;; (start code)
;;  Case      |    microSecs (us)        |    CPU Cycles
;; ----------------------------------------------------------------
;;  Best      |  15 + 9HH + (24 + 6W)H   |  60 + 36HH + (96 + 24W)H
;;  Worst     |  19 + 9HH + (24 + 6W)H   |  76 + 36HH + (96 + 24W)H
;; ----------------------------------------------------------------
;;  W=2,H=16  |        609 / 613         |      2436 / 2452
;;  W=4,H=32  |       1587 / 1591        |      6348 / 6364
;; ----------------------------------------------------------------
;; Asm saving |           -16            |           -64
;; ----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes, HH = integer((*H*-1)/8)

   ld    a, c                  ;; [1] A = sprite width
   ld    (restore_width), a    ;; [4] Modify sprite with in the code for the loop
   ld    a, b                  ;; [1] A = sprite height

next_line:
   push  hl                    ;; [4] Save HL (vmem) before copying line

restore_width=.+1
   ld   bc, #0x0000            ;; [3] 0000 is a placeholder for the width of a sprite line
   ldir                        ;; [6*W-1] Copy one complete sprite line

   dec   a                     ;; [1]   Decrement sprite line to end
   pop   hl                    ;; [4]   Restore HL (vmem)
   ret   z                     ;; [2/4] If no lines left, return

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
   jp    nz, next_line         ;; [3] If not 0, still within same 8-line block

   ;; Handle crossing 16K video memory boundaries (every 8 lines)
   ld    bc, #0xC060           ;; [3] Offset to next character row (-0x3F00 + 0x60)
   add   hl, bc                ;; [3] Adjust destination pointer
   jp    next_line             ;; [3] Continue drawing next line

next_bank_line:    
   ld    a, #0x60              ;; [2] Horizontal correction for Bank 2
   add   l                     ;; [1] Adjust Low byte
   ld    l, a                  ;; [1] Update L
   ld    a, b                  ;; [1] Restore Height counter into A
   jp    nc, next_line         ;; [3] Continue if no carry to H
   inc   h                     ;; [1] Increment H to sync bank address
   jp    next_line             ;; [3] Continue drawing next line

