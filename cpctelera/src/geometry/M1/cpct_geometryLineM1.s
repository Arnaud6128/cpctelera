;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
;; ASM / C bindings for <cpct_geometryLineM1>
;;
;;  34 microSecs, 26 bytes
;;
_cpct_geometryLineM1::
   ld   (restore_ix), ix       ;; [6] Save IX to restore it before returning
   ld   (restore_iy), iy       ;; [6] Save IY to restore it before returning
	
   pop   ix                    ;; [4] IX = Return address
   ld   (simulated_return), ix ;; [6] Save return address for simulated return

.include  /cpct_geometryLineM1.asm/

restore_iy=.+2
   ld   iy, #0000              ;; [4] Restore IY before returning  
    
restore_ix=.+2
   ld   ix, #0000              ;; [4] Restore IX before returning   
   
simulated_return=.+1
   ld   hl, #0000              ;; [3] HL = return address
   jp  (hl)                    ;; [1] Do a manual "ret"
   