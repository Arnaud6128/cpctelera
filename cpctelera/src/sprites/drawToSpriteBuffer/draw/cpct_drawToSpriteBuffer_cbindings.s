;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
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

.include "macros/cpct_maths.h.s"
.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_drawToSpriteBuffer>
;;
;;   13 us, 4 bytes
;;
_cpct_drawToSpriteBuffer::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16) bits) with __sdcccall(1) convention
   ;; HL = Back_Buffer_Width
   ;; DE = Pointer to Back Buffer 
   ld   a, l      ;; [1] A = L = Back_Buffer_Width

   ;; GET next parameters from the stack
   pop  hl        ;; [3] HL = Return Address
   pop  bc        ;; [3] BC = Height/Width (B = Height, C = Width)
   ex  (sp), hl   ;; [6] HL = Pointer to Sprite <-> (SP) = Return address because _z88dk_callee convention

  ;; Calculate offset to be added to Destiny pointer (DE, BackBuffer Pointer)
   ;; After copying each sprite line, to point to the start of the next line
   sub c                         ;; [1] A = Back_Buffer_Width - Sprite Width
   ld (_offset_to_next_line), a  ;; [4] Modify the offset size inside the copy loop
   
   ;; Modify code using width to jump in drawSpriteWidth
   ld    a, #126           ;; [2] We need to jump 126 bytes (63 LDIs*2 bytes) minus the width of the sprite * 2 (2B)
   sub   c                 ;; [1]    to do as much LDIs as bytes the Sprite is wide
   sub   c                 ;; [1]
   ld (_jr_offset), a      ;; [4] Modify JR data to create the jump we need

   ;; A Holds the Height of the sprite to be used as counter for the
   ;; copy loop. There will be as many iterations as Height lines
   ld  a, b                ;; [1] A = Sprite Height
   
   ;; Perform the copy
copy_loop:
_jr_offset = .+1
   jr__0                   ;; [3] Self modifying instruction: the '00' will be substituted by the required jump forward. 
                           ;; ... (Note: Writting JR 0 compiles but later it gives odd linking errors)
.rept 63                   ;; [63*5] 63 LDIs, which are able to copy up to 63 bytes each time.
   ldi                     ;;  | That means that each Sprite line should be 63 bytes width at most.
.endm                      ;;  | The JR instruction at the start makes us ignore the LDIs we don't need 
				           ;;  | (jumping over them) That ensures we will be doing only as much LDIs 
      
   dec  a                  ;; [1]   One less iteration to complete Sprite Height
   ret  z                  ;; [2/3] Repeat copy_loop if A!=0 (Iterations pending)
  
_offset_to_next_line = .+1
   ld   bc, #0000          ;; [3] BC = Offset = Backbuffer Width - Sprite Width (00 is a placeholder that gets modified)
   ex   de, hl             ;; [1] HL holds temporarily the destination Pointer (points to backbuffer) only for math purposes
   add  hl, bc             ;; [3] Add the offset to the Destiny Pointer (BackBuffer Pointer)
   ex   de, hl             ;; [1] Restore the Destiny Pointer to DE (and HL to what it was)
   jp   copy_loop          ;; [3] Continue copying