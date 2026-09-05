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

;; =============================================================================
;; Lookup Tables Geometry (Mode 1 Graphics Configuration)
;; =============================================================================
cpct_plotMasksTable_M1::
    .db 0x77, 0xBB, 0xDD, 0xEE

cpct_plotColorTable_M1::
    ;; Color 0: P0, P1, P2, P3
    .db 0x00, 0x00, 0x00, 0x00
    ;; Color 1: LSB bits
    .db 0x80, 0x40, 0x20, 0x10
    ;; Color 2: MSB bits
    .db 0x08, 0x04, 0x02, 0x01
    ;; Color 3: Both LSB + MSB bits
    .db 0x88, 0x44, 0x22, 0x11	

;; Masks from one subpixel (0..3) to another (0..3) 
cpct_subPixelHorizontalMask_M1::
    .db 0x77, 0x33, 0x11, 0x00
    .db 0x33, 0xBB, 0x99, 0x88
    .db 0x11, 0x99, 0xDD, 0xCC
    .db 0x00, 0x88, 0xCC, 0xEE 
