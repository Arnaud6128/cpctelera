;:  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Bouche Arnaud
;;  Copyright (C) 2025 CPCtelera by ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; Function: cpct_drawSpriteClipToSpriteBuffer
;;
;;   Copies a clipped portion of a sprite into a sprite buffer (off-screen memory).
;;   This function allows drawing only a sub-rectangle of the source sprite,
;;   making it ideal for animation frames, HUD elements, or composite sprites.
;;
;; C Definition:
;;   void <cpct_drawSpriteClipToSpriteBuffer>(
;;       <u8 buffer_width, <void*> dst_buffer,
;;       <u8 sprite_width, <u8> width_to_draw, <u8> height, <void*> src_sprite)
;;
;; Input Parameters (11 Bytes):
;;    (1B  A) buffer_width     - Width of the destination buffer (in bytes)
;;    (2B DE) dst_buffer       - Pointer to destination sprite buffer
;;    (1B  B) sprite_width     - Full width of the source sprite (in bytes)
;;    (1B  C) width_to_draw    - Width to draw (<= sprite_width, in bytes)
;;    (1B  A) height           - Height of the sprite (in lines)
;;    (2B IX) sprite           - Pointer to source sprite data
;;    (2B HL) mask_table       - Pointer to 256-byte aligned mask table
;;
;; Details:
;;    - Uses a 256-byte aligned mask table for transparency (table address = 0x??00).
;;    - Only the rectangle (width_to_draw × height) is drawn.
;;    - REQUIRES CODE TO BE IN RAM — NOT EXECUTABLE FROM ROM.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL, IX
;;
;; Required memory:
;;    Code size: 32 bytes
;;    C-bindings: 20 bytes
;;    Asm-bindings: 32 bytes
;;
;; Time Measures:
;; (start code)
;; |-----------------------------------------------------------------
;; |  Case       |    microSecs (us)     |      CPU Cycles
;; |-----------------------------------------------------------------
;; |  Formula    |  22 * H * (W + 1)     |  88 * H * (W + 1)
;; |-----------------------------------------------------------------
;; |  W=4, H=16  |        1760           |        7040
;; |  W=8, H=32  |        6336           |       25344
;; |-----------------------------------------------------------------
;; |  Asm saving |         -4           |         -16
;; |-----------------------------------------------------------------
;; (end code)
;;    W = *width_to_draw* in bytes, H = *height* in lines
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
   
;; Draw Sprite Clipped  
spriteClipped_height_loop:
   
;; Placeholder for the Sprite Width to Draw   
spriteClipped_width = .+1     
   ld    c, #00      ;; [2] BC = Sprite Width to Draw 0 is default value

line_loop: 
   ld    a, (ix)     ;; [3] Get next byte from the sprite
   ld    l, a        ;; [1] Access mask table element (table must be 256-byte aligned)
   ld    a, (de)     ;; [2] Get the value of the byte of the screen where we are going to draw
   and  (hl)         ;; [2] Erase background part that is to be overwritten (Mask step 1)
   or    l           ;; [1] Add up background and sprite information in one byte (Mask step 2)
   ld   (de), a      ;; [2] Save modified background + sprite data information into memory
   inc   de          ;; [2] Next bytes from the buffer
   inc   ix          ;; [3] Next byte from the sprite 
   dec   c           ;; [1] C holds sprite width, we decrease it to count pixels in this line.
   jp    nz, line_loop  ;; [2/3] While not 0, we are still painting this sprite line 
   
   dec   b
   jp    z, end_draw ;; [3] Jump to end

   ld    a, b        ;; [1] Save B in A
   ld    b, c        ;; [1] B = C (0)
   
;; Placeholder for the Sprite Offset
spriteClipped_offset = .+1      
   ld    c, #00      ;; [2] BC = Sprite Offset 0 is default value
   add   ix, bc      ;; [4] Add offset Src Sprite  

;; Placeholder for the Sprite Buffer Offset    
spriteBuffer_offset = .+1      
   ld    c, #00      ;; [2] BC = Sprite Offset 0 is default value   
   ex    de, hl      ;; [1] HL and DE are exchanged : HL = Sprite buffer
   add   hl, bc      ;; [3] Add offset Src Sprite  
   ex    de, hl      ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE        

   ld    b, a        ;; [1] Restore B from A
   jp    spriteClipped_height_loop   ;; [3] Jump to continue with next pixel line

end_draw:
;; return is in binding