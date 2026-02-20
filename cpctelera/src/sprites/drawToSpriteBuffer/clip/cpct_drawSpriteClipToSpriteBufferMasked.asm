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
;; Function: cpct_drawSpriteClipToSpriteBufferMasked
;;
;;    Draws a clipped, masked sprite into a sprite buffer.
;;
;; C Definition:
;;    void <cpct_drawSpriteClipToSpriteBufferMasked> (<u8> *buffer_width*, void* *dst_buffer*,
;;                                                     <u8> *sprite_width*, <u8> *width_to_draw*,
;;                                                     <u8> *height*, void* *sprite*) __z88dk_callee;
;;
;; Input Parameters (9 Bytes):
;;    (1B  A) buffer_width     - Width of the destination buffer (in bytes)
;;    (2B DE) dst_buffer       - Pointer to destination sprite buffer
;;  From stack :
;;    (1B  B) sprite_width     - Full width of the source sprite (in bytes)
;;    (1B  C) width_to_draw    - Width to draw (<= sprite_width, in bytes)
;;    (1B  C) height           - Height of the sprite (in lines)
;;    (2B HL) sprite           - Pointer to source sprite data (mask + pixel interleaved)
;;
;; Details:
;;    - Sprite data format: [mask_byte, pixel_byte, mask_byte, pixel_byte, ...].
;;    - Only the rectangle (width_to_draw × height) is drawn.
;;    - REQUIRES CODE TO BE IN RAM — NOT EXECUTABLE FROM ROM.
;;
;; Destroyed Register values: 
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    Code size: 35 bytes
;;    C-bindings: 20 bytes
;;    Asm-bindings: 18 bytes
;;
;; Time Measures:
;; (start code)
;; |-----------------------------------------------------------------
;; |  Case       |    microSecs (us)     |      CPU Cycles
;; |-----------------------------------------------------------------
;; |  Formula    |  H * (25*W + 20)      |  H * (100*W + 80)
;; |-----------------------------------------------------------------
;; |  W=4, H=16  |        1920           |        7680
;; |  W=8, H=32  |        7040           |       28160
;; |-----------------------------------------------------------------
;; |  Asm saving |         -4            |         -32
;; |-----------------------------------------------------------------
;; (end code)
;;    W = *width_to_draw* in bytes, H = *height* in lines
   
   ex   de, hl         ;; [1] DE = Sprite buffer; HL = Source sprite  
   
;; Draw Sprite Clipped  
spriteClipped_height_loop:
   ex   de, hl         ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE        
 
;; Placeholder for the Sprite Width to Draw   
spriteClipped_width = .+1     
   ld   b, #00         ;; [2] BC = Sprite Width to Draw 0 is default value
   
line_loop :
   ld   a ,(de)        ;; [2] Get next background byte into A
   and (hl)            ;; [2] Erase background part that is to be overwritten (Mask step 1)
   inc  hl             ;; [2] HL += 1 => Point HL to Sprite Colour information
   or  (hl)            ;; [2] Add up background and sprite information in one byte (Mask step 2)
   ld  (de), a         ;; [2] Save modified background + sprite data information into memory
   inc  de             ;; [2] Next bytes (sprite and memory)
   inc  hl             ;; [2] |

   dec  b              ;; [1] One less iteration to complete Sprite Width
   jp   nz, line_loop  ;; [2/3] Repeat line_loop if C!=0 (Iterations pending)
   
   dec  c              ;; [1] One line less to draw
   ret  z              ;; [2/3] Jump to end if last line
   
   ld   a, c           ;; [1] Save B in A
   
;; Placeholder for the Sprite Offset
spriteClipped_offset = .+1      
   ld   c, #00         ;; [2] BC = Sprite Offset 0 is default value
   add  hl, bc         ;; [3] Add offset Dest Sprite    
   ex   de, hl         ;; [1] DE has destination, but we have to exchange it with HL to be able to do 16-bits maths
   
spriteBuffer_offset = .+1      
   ld   c, #00         ;; [2] BC = Sprite Offset 0 is default value   
   add  hl, bc         ;; [3] Add offset Src Sprite  
   
   ld    c, a          ;; [1] Restore B from A
   jp   spriteClipped_height_loop  ;; [3] Jump to continue with next pixel line
