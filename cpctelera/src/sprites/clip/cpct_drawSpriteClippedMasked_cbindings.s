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

;; Macros for easy use of undocumented opcodes
.include "../../macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_drawSpriteClippedMasked>
;;
;;   34 us, 22 bytes
;;
_cpct_drawSpriteClippedMasked::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8 + 16) bits) with __sdcccall(1) convention
   ;; HL = Width sprite to draw
   ;; DE = Destination memory

   ld  (save_ix), ix             ;; [5] Save IX

   ;; Compute next pixel line Lsb (0x0800 - width_to_draw = 0x07LL)
   xor  a                        ;; [1] A = 0
   sub  l                        ;; [1] A = A - L
   ld  (offset_to_next_line), a  ;; [4] Store A to Lsb offset for next line placeholder

   ld   a, l                     ;; [1] A = L (width_to_draw)
   ld  (width_to_draw), a        ;; [4] Store A Sprite width_to_draw at placeholder     
   
   ;; Get next parameters from stack
   pop  hl                       ;; [3] HL = Return Address
   pop  bc                       ;; [3] BC = Height/Width (B = Height, C = Width)
   ex  (sp), hl                  ;; [6] HL = Sprite pointer <-> (SP) = Returning back address because __z88dk_callee convention         
  
.include /cpct_drawSpriteClippedMasked.asm/
save_ix = .+2
   ld  ix, #0000                 ;; [6] restore IX value
   ret                           ;; [3] return to caller