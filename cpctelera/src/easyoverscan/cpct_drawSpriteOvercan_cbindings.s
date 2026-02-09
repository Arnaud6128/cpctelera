;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
 
;; Macros for easy use of undocumented opcodes
.include "macros/cpct_undocumentedOpcodes.h.s"
 
;;
;; C bindings for <cpct_drawSpriteOverscan>
;;
;;   10 microSecs, 3 bytes
;;
_cpct_drawSpriteOverscan::
   ;; Get parameters from HL and DE registers and stack ((16 + 16) + (8 + 8) bits), with __sdcccall(1) convention
   ;; HL = Source Address (Sprite data array)
   ;; DE = Destination address (Video memory location)

   ;; Get next parameters from the stack 
   pop   af                    ;; [3] Get Return Address
   pop   bc                    ;; [3] BC = Height/Width (B = Height, C = Width)
   push  af                    ;; [4] Restore returning address (__z88dk_callee convention)
   
.include /cpct_drawSpriteOverscan.asm/

   