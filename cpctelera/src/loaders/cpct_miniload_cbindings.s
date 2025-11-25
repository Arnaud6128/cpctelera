;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 César Nicolás González (CNGSoft)
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
.module cpct_loaders

;; Macros for easy use of undocumented opcodes
.include "macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_miniload>
;;
;;   19 us, 12 bytes
;;
_cpct_miniload::
   ld   (saveix), ix  ;; [6] Save IX before using it
   
   ;; Get parameters from HL and DE registers and stack (16 + 16 bits) with __sdcccall(1) convention
   ;; HL = Loading memory address
   ;; DE = Size in bytes of the block to read from Cassette
   ld   a, h          ;; [1] IX = HL = Loading memory address
   ld__ixh_a          ;; [2] |
   ld   a, l          ;; [1] |
   ld__ixl_a          ;; [2] |

.include /cpct_miniload.asm/

saveix = .+2
   ld   ix, #0000    ;; [4] Restore IX (0000 is a placeholder)
   ret               ;; [3] Return to caller