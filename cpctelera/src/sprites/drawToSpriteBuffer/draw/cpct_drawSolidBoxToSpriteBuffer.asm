;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Bouche Arnaud (@Arnaud 6128)
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
;; Function: cpct_drawSolidBoxToSpriteBuffer
;;
;;    Fills up a rectangle inside another sprite's buffer with a given 
;; colour data byte. Could be used for drawing coloured rectangles as well as
;; erasing rectangles easily.
;;
;; C Definition:
;;    void <cpct_drawSolidBoxToSpriteBuffer> (<u16> *buffer_width*, void* *inbuffer_ptr*, 
;;                                            <u8> *width*, <u8> *height*, u16* *colour*) __z88dk_callee;
;;
;; Input Parameters (6 bytes):
;;    (1B A)  buffer_width - Width in bytes of the Sprite used as Buffer (>0, >=width)
;;    (2B DE) inbuffer_ptr - Destination pointer (pointing inside sprite buffer)
;;    (1B C)  width        - Sprite Width in bytes (>0)
;;    (1B B)  height       - Sprite Height in bytes (>0)
;;    (1B L)  colour       - 1-byte colour pattern (in screen pixel format) to fill the box with
;;
;; Assembly Call (Input parameters on Registers)
;;    > call cpct_drawSolidBoxToSpriteBuffer_asm
;;
;; Parameter Restrictions:
;;  * *buffer_width* must be greater or equal than *width*. Drawing a sprite into  
;; a buffer sprite that is shorter will probably cause sprite lines to be displaced,
;; and can potentially cause random memory outside buffer to be overwriten, leading
;; to unforeseen consequencies.
;;  * *inbuffer_ptr* must be a pointer to the place where *sprite* will be drawn 
;; inside the sprite buffer. It can point to any of the bytes in the array of
;; the destination sprite buffer. That will be the place where the first byte
;; of the *sprite* will be copied to (its top-left corner). It is important to
;; check that there is enough space for the sprite to be copied from that byte on.
;; Otherwise, the copy loop will continue outside the sprite buffer boundaries.
;;  * *width* must be the width of the sprite *in bytes*, the width must be 
;; expressed in bytes and *not* in pixels. The correspondence is:
;;    mode 0      - 1 byte = 2 pixels
;;    modes 1 / 3 - 1 byte = 4 pixels
;;    mode 2      - 1 byte = 8 pixels
;;  * *height* must be the height of the sprite in bytes, and must be greater than 0. 
;; There is no practical upper limit to this value. Height of a sprite in
;; bytes and pixels is the same value, as bytes only group consecutive pixels in
;; the horizontal space.
;;  * *colour_pattern* could be any 8-bit value, and should be in screen pixel format.
;; Functions <cpct_px2byteM0> and <cpct_px2byteM1> could be used to calculate 
;; screen pixel formatted bytes out of firmware colours for each pixel in the byte. 
;; If you wanted to know more about screen pixel formats, check <cpct_px2byteM0> or 
;; <cpct_px2byteM1>. Screen pixel format for Mode 2 is just a linear 1-pixel = 1-bit.
;;
;; Known limitations:
;;     * This function *will not work from ROM*, as it uses self-modifying code.
;;     * This function does not do any kind of boundary check or clipping. If you 
;; try to draw sprites on the frontier of the buffer or the sprite it might 
;; potentially overwrite memory locations beyond boundaries. In particular, pay 
;; attention to the heights of the sprites and the place where the sprite is 
;; going to be drawn, to ensure that last lines of the sprites are not "drawn" 
;; outside the buffer's memory. This could cause your program to behave erratically, 
;; hang or crash. Always take the necessary steps  to guarantee that you are 
;; drawing inside buffer boundaries.
;;     * As this function receives a byte-pointer to memory, it can only 
;; draw byte-sized and byte-aligned sprites. This means that the box cannot
;; start on non-byte aligned pixels (like odd-pixels, for instance) and 
;; their sizes must be a multiple of a byte (2 in mode 0, 4 in mode 1 and
;; 8 in mode 2).
;;
;; Details:
;;    This function draws a solid colour-patterned box (a rectangle full
;; of a given colour pattern) anywhere in sprite buffer.
;; It does so by copying the colour pattern byte to the top-left byte 
;; of the box and then cloning that byte to the next bytes of the box.
;; As it does so using a dynamic JR, the Rectangle Width is limited 
;; to 64 Bytes (64 bytes-wide at most). 
;;    See cpct_drawSolidBox for more informations
;;
;; Destroyed Register values:
;;       AF, BC, DE, HL
;;
;; Required memory:
;;    C-bindings   - 27 bytes
;;    ASM-bindings - 23 bytes
;;
;; Time Measures:
;; (start code)
;;   Case      |   microSecs (us)   |     CPU Cycles
;;  -----------------------------------------------------
;;   Any       |   14 + 10H + 8WH   |   56 + 40H + 32WH
;;  -----------------------------------------------------
;;   W=2,H=16  |         430        |        1720
;;   W=4,H=32  |        1358        |        5432
;;  -----------------------------------------------------
;;  Asm saving |        -13         |        -52
;;  -----------------------------------------------------
;; (end code)
;;  W = Sprite width in bytes
;;  H = Sprite height in bytes
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Calculate offset to be added to Destination pointer (DE, BackBuffer Pointer)
   ;; After copying each sprite line, to point to the start of the next line
   sub c                           ;; [1] A = Back_Buffer_Width - Sprite Width
   ld (offset_to_next_line), a     ;; [4] Modify the offset size inside the copy loop

   ;; Set the sprite with inside the loop to be restored
   ld  a, c                        ;; [1] A = Sprite Width
   ld (sprite_width_restore), a    ;; [4] Set the sprite width inside the copy loop

   ;; A Holds the Height of the sprite to be used as counter for the
   ;; copy loop. There will be as many iterations as Height lines
   ld  a, b                        ;; [1] A = Sprite Height
   
   ;; Flip HL <-> DE for math computation
   ex  de, hl                      ;; [1] Destination = HL / Color = E

   ;; Perform the box fill
   fill_loop:
       ;; Make B = sprite width to use it as counter for DJNZ which will copy next sprite line
       sprite_width_restore = .+1
       ld   b, #00                 ;; [2] B = Sprite Width (00 is a placeholder that gets modified)

   fill_line:
       ld  (hl), e                 ;; [3] Copy E into HL
       inc  hl                     ;; [2] Next destination address (HL++)
       djnz fill_line              ;; [4/3] Test if all line filled
      
       offset_to_next_line = .+1
       ld   c, #00                 ;; [2] BC = Offset = Backbuffer Width - Sprite Width (00 is a placeholder that gets modified)
       add  hl, bc                 ;; [3] Add the offset to the Destiny Pointer (BackBuffer Pointer)
       dec  a                      ;; [1]   One less iteration to complete Sprite Height
       jr   nz, fill_loop          ;; [2/3] Repeat fill_loop if A!=0 (Iterations pending)

   ret                             ;; [3] Return to the caller
