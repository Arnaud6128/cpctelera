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

;; .globl cpct_plotColorTable_M1
;; .globl cpct_plotMasksTable_M1
.globl cpct_getScreenPtr_asm
.globl cpct_subPixelHorizontalMask_M1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_geometryLineM1
;;
;;    Draws an arbitrary straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using Bresenham's line algorithm.
;;
;; Required memory:
;;    TODO bytes (TODO bytes core routine + TODO bytes binding wrapper)
;;
;; Time Measures (Includes TODO us / TODO cycles binding wrapper overhead):
;;    Horizontal    (0,0)   to (100,0)         | 101    | 11250          | 45000
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; parameters
;;      (2B HL) = VMEM start adress
;;      (2B DE) = X0
;;      (2B BC) = X1
;;      (2B IX) = ixh INK Color  / ixl = Y
;; Destroyed Register values:
;;      AF, BC, DE, HL, IX
;;

    ; exchange X0 / X1 (if needed) to draw from left to right
    ld a,b
    cp d
    jr c,exchangeX		; d>b   ==> exchange
    jr nz,decodeAdresses	    ; d!=b  ==> d<b
    ld a,c				; here d=b   ==> Compare e and c
    cp e
    jr nc,decodeAdresses	    ; e<=c	==> de<bc
exchangeX:   ; exchange de and bc / X0 and X1
   	ld a,e
	ld e,c
	ld c,a
	ld a,d
	ld d,b
	ld b,a

decodeAdresses:
    ;  Computiong left adress in hl
    ;  left subpixel in d, nbOctet in e

    ; Compute subPixels and line octet (left and right)

    ld a,e                  ; a= low X0
    and #0x03	            ; Keep only the 2 least significant bits of X0 : subPixel

    sra d           ;; d can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
    rr  e           ;; rotate e once with carry from d
    srl e           ;; Now e is the left byte offset in the line (0-39)

    ld d,a          ;; Store left sub pixel in d for the moment

    ld a,c                  ; a= low X1
    and #0x03	            ; Keep only the 2 least significant bits of X1 : subPixel

    sra b           ;; b can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
    rr  c           ;; rotate c once with carry from b
    srl c           ;; Now c is the Right byte offset in the line (0-39)

    ld b,a          ;; Store Rigth sub pixel in b for the moment

    ; Compute left adress in HL
    push bc         ;; save Right info
    push de         ;; save Left info

    ld__b_ixl       ;; b = Y0 in pixels

    ex de,hl        ;; de = SCREEN ADRESS / HL = X0 (but no need)

    call cpct_getScreenPtr_asm    ; HL = Left Adress = Current adress for loop

    pop de          ;; d = Left subpixel  / e = left octect
    pop bc          ;; b = right subpixel / c = right octet
                    ;  HL = Left Adress 

    ;; Compute nbOctet to print
    ld a,c          ;; a = right octet
    sub e           ;; a = nbOctet = right octet - left octet
    ld e,a          ;; e = nbOctet

    ;; Rearrange registers so B= LeftSubpixel and C = RightSubPixel - E = nbOctet
    ld a,b          ;; a = right subpixel
    ld b,d          ;; b = left subPixel
    ld c,a          ;; c = right subpixel          

    ld__a_ixh       ;; Put INK Color in a

    ;; We are ready for fast entry
