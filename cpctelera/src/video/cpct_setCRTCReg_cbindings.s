;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2017 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
.module cpct_video
  
.include "video/videomode.h.s"
;;
;; C bindings for <cpct_setCRTCReg>
;;
;;   2 microSecs, 2 bytes
;;
_cpct_setCRTCReg::
   ;; Get parameters from A and L registers (8 + 8 bits) with __sdcccall(1) convention
   ;; A = CRTC Register Number
   ;; L = New Value for Register
   ld  b, l  ;; [1] B = L = New Value for Register
   ld  c, a  ;; [1] C = A = CRTC Register Number

.include /cpct_setCRTCReg.asm/