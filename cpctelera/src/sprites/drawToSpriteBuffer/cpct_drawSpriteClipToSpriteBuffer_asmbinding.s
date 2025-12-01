;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
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

;; C bindings for <cpct_drawSpriteClipToSpriteBuffer>
;;
;;   21 us, 17 bytes
;;
_cpct_drawSpriteClipToSpriteBuffer_asm::   
   ;; A = Sprite Buffer Width
   ;; DE = Destination sprite buffer
   ;; HL = Source sprite
                     
   ;; Get next parameters from the stack 
   pop  bc                         ;; [3] B = Sprite Width / C = Sprite Width to draw  
   sub  c                          ;; [1] A = Negative Sprite Offset (Sprite Buffer Width (A) - Sprite Width to Draw (C))
   ld  (spriteBuffer_offset), a    ;; [4] Set Sprite Buffer Width at placeholder 
   
   ld   a, c                       ;; [1] A = Sprite width to Drawn
   ld  (spriteClipped_width), a    ;; [4] Set Sprite Width to Draw at placeholder  
   sub  b                          ;; [1] A = Negative Sprite Offset (Sprite Width to Draw (A) - Sprite Width (B))
   neg                             ;; [1] A = -A
   ld  (spriteClipped_offset), a   ;; [4] Set Sprite Offset at placeholder  
   
   pop  bc                         ;; [3] B = Useles / C = Height 
   ld   a, c                       ;; [1] A = C (Height)
      
.include /cpct_drawSpriteClipToSpriteBuffer.asm/      
 