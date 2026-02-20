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
;; Input Parameters (7 Bytes):
;;    (1B  A) buffer_width   - Width of the destination sprite buffer (in bytes)
;;    (2B DE) dst_buffer     - Pointer to destination sprite buffer
;;    (2B HL) src_sprite     - Pointer to source sprite data
;;    (1B  B) sprite_width   - Full width of the source sprite (in bytes)
;;    (1B  C) width_to_draw  - Width to draw (<= sprite_width, in bytes)
;;    (1B  A) height         - Height of the sprite portion to draw (in lines)
;;    (Note: height is passed via A after stack setup)
;;
;; Details:
;;   - The function uses self-modifying (cannot be used in ROM) code to set clipping parameters.
;;   - Source sprite data is expected in plain pixel format (no mask).
;;   - The destination buffer must be wide enough to hold 'buffer_width' bytes per line.
;;   - Only the rectangle defined by (width_to_draw × height) is copied.
;;   - After each line, the routine skips unused bytes in both source and destination
;;     using precomputed offsets.
;;
;; Destroyed Registers:
;;   AF, BC, DE, HL
;;
;; Required Memory:
;;   Code size: 19 bytes
;;   C-bindings: 20 bytes
;;   Asm-bindings: 17 bytes
;;
;; Time Measures:
;; (start code)
;; |-----------------------------------------------------------------
;; |  Case       |    microSecs (us)     |      CPU Cycles
;; |-----------------------------------------------------------------
;; |  Formula    |  H * (22 + 6*W)       |  H * (88 + 24*W)
;; |-----------------------------------------------------------------
;; |  W=4, H=16  |         736           |        2944
;; |  W=8, H=32  |        2240           |        8960
;; |-----------------------------------------------------------------
;; |  Asm saving |         -7           |         -38
;; |-----------------------------------------------------------------
;; (end code)
;;    W = *width_to_draw* in bytes, H = *height* in lines
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ld   b, #00     ;; [1] B = 0   
   ex   de, hl     ;; [1] DE = Sprite buffer; HL = Source sprite  
   
;; Draw Sprite Clipped  
spriteClipped_height_loop:
   ex   de, hl     ;; [1] HL and DE are exchanged every line to do 16-bits maths with DE        
 
;; Placeholder for the Sprite Width to Draw   
spriteClipped_width = .+1     
   ld   c, #00     ;; [2] BC = Sprite Width to Draw 0 is default value
   ldir            ;; [5] Copy Sprite (DE++) = (HL++) -> BC--
   dec  a          ;; [1] Height--
   ret  z          ;; [2/3] If 0, we have finished the last sprite line.
   
;; Placeholder for the Sprite Offset
spriteClipped_offset = .+1      
   ld   c, #00      ;; [2] BC = Sprite Offset 0 is default value
   add  hl, bc      ;; [3] Add offset Dest Sprite    
   ex   de, hl      ;; [1] DE has destination, but we have to exchange it with HL to be able to do 16-bits maths
   
spriteBuffer_offset = .+1      
   ld   c, #00      ;; [2] BC = Sprite Offset 0 is default value   
   add  hl, bc      ;; [3] Add offset Src Sprite  
   jp   spriteClipped_height_loop   ;; [3] Jump to continue with next pixel line