;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Xavier Jollet (@SagaDS)
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_getColorAtM1
;;
;;    Get INK color of one pixel in Mode 1 (320x200, 4 colors).
;;
;; Assembly call:
;;    > call cpct_getColorAtM1_asm 
;;          HL = Screen start Adress
;;          DE = X
;;          C  = Y
;;
;;      Destroyed Register values:
;;          AF, BC, DE, HL
;;
;;    > call cpct_getColorAtM1_asm_f
;;          HL = Adress of octet to test
;;          A  = SubPixel to test in octet (0..3)
;;
;;      Destroyed Register values:
;;          AF, BC, HL
;;
;;      Output : A = color (and L contains it also)
;;
;; Required memory:
;;    TODO bytes (TODO bytes core routine + TODO bytes binding wrapper)
;;
;; Time Measures (Includes TODO us / TODO cycles binding wrapper overhead):
;;    Get color at subPixel 0            | 101    | 11250          | 45000
;;    Get color at subPixel 3            | 101    | 11250          | 45000
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ASM bindings for <cpct_geometryHorizontlaLineM1>
;;
;;  0 microSecs, 0 bytes
;;

;; ASM entry point for fast getColorAt from asm
cpct_getColorAtM1_asm::
.include  /cpct_getColorAtM1_1.asm/

;; Entry point for fast getColorAt from asm
cpct_getColorAtM1_asm_f::
.include  /cpct_getColorAtM1_2.asm/
