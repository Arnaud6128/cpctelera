;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

;;
;; ASM bindings for <cpct_getBottomLeftPtr>
;;
;;   4/11 us, 6 bytes
;;
cpct_getBottomLeftPtr_asm::

.include /cpct_getBottomLeftPtr.asm/

  ret    z          ;; [2/4] If result is Zero, HL is at the same memory bank, then we return.
   
  ;; If Ret Z failed, it means that HL points to a different 16K memory bank than 
  ;; the initial pointer we received into DE. Therefore, our calculations have made
  ;; our address jump to the next bank. That means we need to correct. Correction 
  ;; includes adding 0x50 (to jump one more 8-lines block ahead) and also jump
  ;; 3 16K memory banks ahead to perform a full cycle around the 4 16K banks of memory.
  ;; That will place our final pointer in the same memory bank as it started, but
  ;; correctly advanced 1 more 8-lines character ahead
  ld    bc, #0xC050 ;; [3] BC = 0xC000 + 0x50 (Size of 3 16K Banks + 0x50 for the 8-lines block)
  add   hl, bc      ;; [3] HL = HL + BC = HL + 0xC000 + 0x50
  ret               ;; [3] Final address is ready, return.
