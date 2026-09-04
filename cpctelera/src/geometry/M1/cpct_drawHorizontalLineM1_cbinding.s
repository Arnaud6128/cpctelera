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

.include "macros/cpct_undocumentedOpcodes.h.s"

.globl cpct_drawHorizontalLineM1

;; extern void cpct_drawHorizontalLineM1 (u8* vmem, u16 x0, u16 x1, u8 y, u8 color) __z88dk_callee;
;;    vmem        - Base VRAM memory address (typically 0xC000)
;;    x0          - Starting X coordinate (0-319)
;;    x1          - Ending X coordinate (0-319)
;;    y           - Y coordinate (0-199, 8-bit integer)
;;    color       - Ink color of line (0..3)
;;

;;  34 microSecs, 26 bytes
_cpct_drawHorizontalLineM1::
   ld   (restore_ix), ix         ;; [6] Save IX to restore it before returning
	
   pop   ix                      ;; [4] IX = Return address
   ld   (simulated_return), ix   ;; [6] Save return address for simulated return

    ; Get Parameters
    ;; HL = Screen Adress / DE = X0 Coordinate 
    pop bc     ;; bc = X1 coordinate 
    pop ix     ;; ixh = Y0 coordinate / ixl = color
   
   call cpct_drawHorizontalLineM1    ;; Call to asm entry point

restore_ix=.+2
   ld   ix, #0000                 ;; [4] Restore IX before returning   

simulated_return=.+1
   ld   hl, #0000                 ;; [3] HL = return address
   jp  (hl)                         ;; [1] Do a manual "ret"
