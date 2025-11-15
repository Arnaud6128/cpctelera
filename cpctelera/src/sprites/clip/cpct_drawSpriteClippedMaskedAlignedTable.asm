;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud)
;;  Copyright (C) 2014-2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; Function: cpct_drawSpriteClippedMaskedAlignedTable
;;
;;    Copies partially a sprite from an array to video memory (or to a screen buffer).
;;
;; C Definition:
;;    void <cpct_drawSpriteClippedMaskedAlignedTable> (u8 width_to_draw, void *sprite, void* memory, 
;;                                                        u8 width, u8 height, void *mask_table) __z88dk_callee;
;;
;; Input Parameters (9 bytes):
;;  (1B  A)  width_to_draw  - Sprite Width to Draw in *bytes* (>0 && <= Sprite Width) (Beware, *not* in pixels!)
;;  (2B  HL) sprite         - Source Sprite Pointer
;;  (2B  DE) videomem       - Destination video memory pointer
;;  (1B  B) width           - Sprite Width in *bytes* (>0) (Beware, *not* in pixels!)
;;  (1B  C) height          - Sprite Height in bytes (>0)
;;  (2B  IX) pmasktable     - Pointer to the aligned mask table used to create transparency
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawSpriteClippedMaskedAlignedTable_asm
;;
;; Parameter Restrictions:
;;  * *width_to_draw* must be the width *in bytes* to draw partially the sprite  
;;  * *sprite* must be an array containing sprite's pixels data in screen pixel format
;; Sprite must be rectangular and all bytes in the array must be consecutive pixels, 
;; starting from top-left corner and going left-to-right, top-to-bottom down to the 
;; bottom-right corner. Total amount of bytes in pixel array should be *width* x *height*. 
;; You may check screen pixel format for mode 0 (<cpct_px2byteM0>) and mode 1 
;; (<cpct_px2byteM1>) as for mode 2 is linear (1 bit = 1 pixel). 
;;  * *pvideomem* could be any place in memory, inside or outside current video memory. It
;; will be equally treated as video memory (taking into account CPC's video memory 
;; disposition). This lets you copy sprites to software or hardware backbuffers, and
;; not only video memory.
;;  * *width* must be the width of the sprite *in bytes* and must be 1 or more. 
;; Using 0 as *width* parameter for this function could potentially make the program hang 
;; or crash. Always remember that the *width* must be expressed in bytes and *not* in pixels. 
;; The correspondence is:
;;    mode 0      - 1 byte = 2 pixels
;;    modes 1 / 3 - 1 byte = 4 pixels
;;    mode 2      - 1 byte = 8 pixels
;;  * *height* must be the height of the sprite in bytes, and must be greater than 0. 
;; There is no practical upper limit to this value. Height of a sprite in
;; bytes and pixels is the same value, as bytes only group consecutive pixels in
;; the horizontal space.
;;  * *pmasktable* must be a pointer to the mask table that will be used for calculating
;; transparency. A mask table is expected to be 256-sized containing all the possible
;; masks for each possible byte colour value. Also, the mask is required to be
;; 256-byte aligned, which means it has to start at a 0x??00 address in memory to
;; fit in a complete 256-byte memory page. <cpct_transparentMaskTable00M0> is an 
;; example table you might want to use.
;;
;; Known limitations:
;;    * See <cpct_drawSpriteMaskedAlignedTable>
;;
;; Details:
;;    * See <cpct_drawSpriteMaskedAlignedTable>
;;
;; Destroyed Register values: 
;;   IX, IY, AF, BC, DE, HL
;;
;; Required memory:
;;    Code size  - 72
;;    C-bindings - 53 bytes
;;  ASM-bindints - 42 bytes
;;
;; Time Measures:
;; (start code)
;;  Case      |    microSecs (us)        |    CPU Cycles
;; ----------------------------------------------------------------
;;  Best      |  10 + (27 + 21W)H        |  40 + (108 + 84W)H
;;  Worst     |       Best + 10          |     Best + 40
;; ----------------------------------------------------------------
;;  W=2,H=16  |          1114            |      4456 
;;  W=4,H=32  |          3562             |     14248 
;; ----------------------------------------------------------------
;; Asm saving |          -16             |       -64
;; ----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   sub  c                        ;; [1] A = Negative Sprite Offset (Sprite Width_to_draw (A) - Sprite Width (C))
   neg                           ;; [2] A = -A (Positive)
   ld  (offset_sprite), a        ;; [4] Store Sprite offset at placeholder  

   ld__iyh_b                     ;; [2] IYH = B = Height
   ex  de, hl                    ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE 
   
;; Draw partial Sprite loop
draw_loop:
   ex  de, hl                    ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE        
 
;; Placeholder for the Sprite width_to_draw   
width_to_draw = .+1     
   ld   b, #00              ;; [2] B = Sprite Width to draw (#00 is a placeholder to be modified)

draw_loop_width :
   ld   a, (hl)             ;; [2] Get next byte from the sprite
   ld__ixl_a                ;; [2] Access mask table element (table must be 256-byte aligned)
   ld   a, (de)             ;; [2] Get the value of the byte of the screen where we are going to draw
   and (ix)                 ;; [5] Erase background part that is to be overwritten (Mask step 1)
   or__ixl                  ;; [2] Add up background and sprite information in one byte (Mask step 2)
   ld  (de), a              ;; [2] Save modified background + sprite data information into memory
   inc  de                  ;; [2] Next byte memory
   inc  hl                  ;; [2] Next byte the sprite
   djnz  draw_loop_width    ;; [2/3] If B != 0 continue to copy 
   
   dec__iyh                 ;; [2] IYH-- One less iteration to complete Sprite Height 
   jp   z, end_copy         ;; [2/3] Return if end of sprite copy

;; Placeholder for the Sprite offset
offset_sprite = .+1      
   ld   c, #00              ;; [2] C = Sprite Offset (#00 is a placeholder to be modified)
   add  hl, bc              ;; [3] Add offset sprite color + mask  
   ex   de, hl              ;; [1] DE has destination, but we have to exchange it with HL to be able to do 16-bits maths

;; Placeholder for the Video next line
offset_to_next_line = .+1
   ld   bc, #0x0700         ;; [3] 0x07LL (LL is a placeholder) = 0x800 bytes is the distance in memory from one pixel line to the next within every 8 pixel lines   
   add  hl, bc              ;; [3] | And we add 0x800 minus the width to draw of the sprite (BC) to destination pointer  

   ld   a, h                ;; [1] We check if we have crossed video memory boundaries (which will happen every 8 lines). 
   and  #0x38               ;; [2] leave out only bits 13,12 and 11 from new memory address (00xxx000 00000000)
   jp   nz, draw_loop       ;; [2/3]  and checking the 4 bits that identify present memory line. 

   ld   bc, #0xC050         ;; [3] We advance destination pointer to next line
   add  hl, bc              ;; [3] HL += BC (0xC050)
   jp   draw_loop           ;; [3] Jump to continue with next pixel line
   
 end_copy:
 ;; return is in binding
