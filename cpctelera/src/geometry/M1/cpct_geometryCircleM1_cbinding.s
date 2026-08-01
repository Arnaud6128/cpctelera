;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_geometry

;; Macros for easy use of undocumented opcodes
.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_geometryCircleM1>
;;
;;  37 microSecs, 18 bytes
;;
_cpct_geometryCircleM1::
    ;; In registers : 
    ;; HL = Base VRAM memory address
    ;; DE = Center X

    ld   (restore_ix), ix ;; [6] Save IX to restore it before returning

    ;; Parameters retrieval from stack 
    pop   af              ;; [3]  AF = Return address
    pop   ix              ;; [4]  IX = Center Y
    pop   bc              ;; [3]  B = Color, C = Radius
    push  af              ;; [4]  Restore return address to stack because __z88dk_callee
    push  iy              ;; [5]  Save IY to restore it before returning

.include  /cpct_geometryCircleM1.asm/

ret_draw_circle:

restore_ix = .+2
   ld     ix, #0000      ;; [4] Restore IX before returning
   pop    iy             ;; [5] Restore IY before returning
   ret                   ;; [3] Return to caller
