;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128)
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
.module cpct_strings

;;
;; Include constants and general values
;;
.include "strings.s"
.include "./macros/cpct_undocumentedOpcodes.h.s"

;;
;; C bindings for <cpct_drawStringM0>
;;
;;   33 us, 12 bytes
;;
_cpct_drawStringM0::
   ;; Get parameters from HL and DE registers (16 + 16 bits) with __sdcccall(1) convention
   ;; HL = Pointer to the null terminated string 
   ;; DE = Destination address (Video memory location where character will be printed)
   ex de, hl         ;; [1] HL <-> DE : HL = Destination address
   
   ld (saveix), ix   ;; [6] Save IX and IY before modifying them
   ld (saveiy), iy   ;; [6] |
   
   ld__iyh_d         ;; [2] IY = DE = Pointer to the null terminated string 
   ld__iyl_e         ;; [2] |

.include /cpct_drawStringM0.asm/

saveix = .+2
saveiy = .+6
   ld    ix, #0000   ;; [6] Restore IX before returning (0000 is a placeholder)
   ld    iy, #0000   ;; [6] Restore IY before returning (0000 is a placeholder)
   ret               ;; [3] Return
