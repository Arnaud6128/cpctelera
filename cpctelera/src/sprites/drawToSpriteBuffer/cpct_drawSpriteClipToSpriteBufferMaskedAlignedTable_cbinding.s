;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
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

;; C bindings for <cpct_drawSpriteClipToSpriteBufferMaskedAlignedTable>
;;
;;   40 us, 31 bytes
;;
_cpct_drawSpriteClipToSpriteBufferMaskedAlignedTable::
   ;; Get parameters from A and DE registers ((8 + 16 bits) + (8 + 8 + 16 + 16 + 16 bits), with __sdcccall(1) convention
   ;; A = Sprite Buffer Width
   ;; DE = Destination sprite buffer

   ld  (restore_ix), ix            ;; [5] Save IX to restore it before returning
                     
   ;; Get next parameters from the stack 
   pop  hl                         ;; [3] HL = Return address   
   pop  bc                         ;; [3] B = Sprite Width / C = Sprite Width to draw  
   sub  c                          ;; [1] A = Negative Sprite Offset (Sprite Buffer Width (A) - Sprite Width to Draw (C))
   ld  (spriteBuffer_offset), a    ;; [4] Set Sprite Buffer Width at placeholder 
   
   ld   a, c                       ;; [1] A = Sprite width to Drawn
   ld  (spriteClipped_width), a    ;; [4] Set Sprite Width to Draw at placeholder  
   sub  b                          ;; [1] A = Negative Sprite Offset (Sprite Width to Draw (A) - Sprite Width (B))
   neg                             ;; [1] A = -A
   ld  (spriteClipped_offset), a   ;; [4] Set Sprite Offset at placeholder  
   
   pop  bc                         ;; [3] B = Useles / C = Height 
   ld   b, c                       ;; [1] A = C (Height)
   pop  ix                         ;; [4] IX = Source Sprite  
   ex  (sp), hl                    ;; [5] HL = Pointer to the Mask Table (must be 256-byte aligned) <-> (SP) = Return address because _z88dk_callee convention
      
.include /cpct_drawSpriteClipToSpriteBufferMaskedAlignedTable.asm/    

restore_ix = .+2
   ld   ix, #0000                  ;; [4] Restore IX before returning
   ret                             ;; [3] Return to caller  
 