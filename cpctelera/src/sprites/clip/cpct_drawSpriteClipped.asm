;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) Arnaud BOUCHE
;;  Copyright (C) 2017 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; Function: cpct_drawSpriteClipped
;;
;;    Copies partially a sprite from an array to video memory (or to a screen buffer).
;;
;; C Definition:
;;    void <cpct_drawSpriteClipped> (u8 width_to_draw, void *sprite, void* memory, u8 width, u8 height) __z88dk_callee;
;;
;; Input Parameters (7 bytes):
;;  (1B A ) width_to_draw - Sprite Width to Draw in *bytes* (>0 && <= width) (Beware, *not* in pixels!)
;;  (2B HL) sprite - Source Sprite Pointer (array with pixel and mask data)
;;  (2B DE) memory - Destination video memory pointer
;;  (1B C ) width  - Sprite Width in *bytes* (>0) (Beware, *not* in pixels!)
;;  (1B B ) height - Sprite Height in bytes (>0)
;;
;; Assembly call (Input parameters on registers):
;;    > call cpct_drawSpriteClipped_asm
;;
;; Parameter Restrictions:
;;  * *width_to_draw* must be the width *in bytes* to draw partially the sprite  
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
;;    * See <cpct_drawSprite>
;;
;; Details:
;;    * See <cpct_drawSprite>
;;
;; Destroyed Register values: 
;;   AF', AF, BC, DE, HL
;;
;; Required memory:
;;    C-bindings - 47 bytes
;;  ASM-bindints - 42 bytes
;;
;; Time Measures:
;; (start code)
;;  Case      |    microSecs (us)        |    CPU Cycles
;; ----------------------------------------------------------------
;;  Best      |  20 + (33 + 11W)H        | 80 + (132 + 44W)H
;;  Worst     |       Best + 10          |     Best + 40
;; ----------------------------------------------------------------
;;  W=2,H=16  |          900             |       3600
;;  W=4,H=32  |         2484             |       9936
;; ----------------------------------------------------------------
;; Asm saving |          -16             |       -64
;; ----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   sub  c                        ;; [1] A = Negative Sprite Offset (Sprite Width_to_draw (A) - Sprite Width (C))
   neg                           ;; [1] A = -A (Positive)
   ld  (offset_sprite), a        ;; [4] Store Sprite offset at placeholder  

   ld   a, b                     ;; [1] A = B (Sprite height)
   ex  de, hl                    ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE 
   
;; Draw partial Sprite loop
draw_loop:
   ex  de, hl         ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE        
 
;; Placeholder for the Sprite width_to_draw   
width_to_draw = .+1     
   ld   bc, #0000     ;; [3] BC = Sprite Width to draw (#0000 is a placeholder to be modified)
   ldir               ;; [6*C-1] Copy one whole line of bytes from sprite to video memory
   dec  a             ;; [1] A-- One less iteration to complete Sprite Height
   ret  z             ;; [2/3] If 0 we have finished the last sprite line and return to caller

;; Placeholder for the Sprite offset
offset_sprite = .+1      
   ld   c, #00        ;; [3] BC = Sprite Offset (#0000 is a placeholder to be modified)
   add  hl, bc        ;; [3] Add offset sprite    
   ex   de, hl        ;; [1] DE has destination, but we have to exchange it with HL to be able to do 16-bits maths

;; Placeholder for the Video next line
offset_to_next_line = .+1
   ld   bc, #0x0700   ;; [3] 0x07LL (LL is a placeholder) = 0x800 bytes is the distance in memory from one pixel line to the next within every 8 pixel lines   
   add  hl, bc        ;; [3] | And we add 0x800 minus the width of the sprite (BC) to destination pointer  

   ld   b, a          ;; [1] Save A (Sprite Height to draw) into B before using it
   ld   a, h          ;; [1] We check if we have crossed video memory boundaries (which will happen every 8 lines). 
   and  #0x38         ;; [2] leave out only bits 13,12 and 11 from new memory address (00xxx000 00000000)
   ld   a, b          ;; [1] Recover A from B
   jp   nz, draw_loop ;; [2/3]  and checking the 4 bits that identify present memory line. 

   ld   bc, #0xC050   ;; [3] We advance destination pointer to next line
   add  hl, bc        ;; [3] HL += BC (0xC050)
   jp   draw_loop     ;; [3] Jump to continue with next pixel line
