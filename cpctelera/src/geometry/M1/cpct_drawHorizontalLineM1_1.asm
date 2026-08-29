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
.globl cpct_plotFullColor_M1
.globl cpct_subPixelHorizontalMask_M1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_geometryLineM1
;;
;;    Draws an arbitrary straight line between two points (X0, Y0) and (X1, Y1)
;;    in Mode 1 (320x200, 4 colors) using Bresenham's line algorithm.
;;
;; C Definition:
;;    void cpct_drawHorizontalLineM1(void* screen_base, u16 x0, u16 x1, u8 y0, u8 color ) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B DE) screen_base - Base VRAM memory address (typically 0xC000)
;;    (2B HL) x0          - Starting X coordinate (0-319)
;;    (Stack) x1          - Ending X coordinate (0-319)
;;    (Stack) color / y0  - Color of line (0..3) / Starting Y coordinate (0-199, 8-bit integer)
;;
;; Assembly call:
;;    > call cpct_drawHorizontalLineM1
;;      (2B DE) screen_base - Base VRAM memory address (typically 0xC000)
;;      (2B HL) x0          - Starting X coordinate (0-319)
;;      (2B BC) x1          - Ending X coordinate (0-319)
;;      (2B IY) High = color / Low = y0  - Color of line (0..3) / Starting Y coordinate (0-199, 8-bit integer)
;;
;;    > call cpct_drawHorizontAlLineM1_f
;;      (2B HL) current adress (leftAdress)
;;      (2B DE) Target  adress (rightAdress)
;;      (1B B ) current sub pixel (leftSubPixel)
;;      (1B C ) target  sub pixel (rightSubPixel)
;;      (1B A ) Color

;; Destroyed Register values:
;;    AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;    TODO bytes (TODO bytes core routine + TODO bytes binding wrapper)
;;
;; Time Measures (Includes TODO us / TODO cycles binding wrapper overhead):
;;    Horizontal    (0,0)   to (100,0)         | 101    | 11250          | 45000
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Get Parameters
    ;; HL = Screen Adress / DE = X0 Coordinate 
    pop bc     ;; bc = X1 coordinate 
    pop iy     ;; iyh = color / iyl = Y0 coordinate
cpct_drawHorizontAlLineM1::
    ; exchange X0 / X1 if needed to draw from left to right
    ld a,b
    cp d
    jr c,exchange		; d>b   ==> exchange
    jr nz,continue	    ; d!=b  ==> d<b
    ld a,c				; d=b   ==> Compare e and c
    cp e
    jr nc,continue	    ; e<=c	==> de<bc
exchange:   ; exchange de and bc / X0 and X1
    ; push de
    ; push bc
    ; pop de
    ; pop bc
   	ld a,e
	ld e,c
	ld c,a
	ld a,d
	ld d,b
	ld b,a
continue:
    ; We will draw from X0 to X1, so we first get X1 info to have X0 ready before starting
    ; Compute Right ScreenX octets and SubPixel from X1
    ld a,c                  ; a = low X1
    and #0x03	            ; Keep only the 2 least significant bits of X1 : subPixel
    ld (#rightSubPixel),a   ; Store right sub pixel in SMC

    sra b           ;; b can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
    rr  c           ;; rotate c once with carry from b
    srl c           ;; Now c is the byte offset in the line (0-39)

    ld__b_iyl       ;; b = Y0 in pixels

    ex de,hl        ;; de = SCREEN ADRESS / HL = X0

    push de 
    push hl

    call cpct_getScreenPtr_asm    ; HL = Right Adress

    ; Store right adress inside SMC
    ld (#rightAdress),hl

    pop hl         ;; hl = X0 coordinate
    pop de         ;; de = SCREEN ADRESS

    ; Compute Left SX ScreenX octets and Sub Pixel from X0
    ld a,l                  ; a= low X0
    and #0x03	            ; Keep only the 2 least significant bits of X0 : subPixel
    ld (#leftSubPixel),a    ; Store left sub pixel in SMC

    sra h           ;; h can only be 1 or 0 (319 is < 512), so one shift right to carry is enough
    rr  l           ;; rotate l once with carry from h
    srl l           ;; Now l is the byte offset in the line (0-39)

    ld__b_iyl       ;; b = Y0 in pixels
    ld c, l         ;; c = X0 in bytes

    call cpct_getScreenPtr_asm    ; HL = Left Adress = Current adress for loop

leftSubPixel=.+1
    ld b, #00  ; b = left sub pixel = current pixel offset in the left adress
rightSubPixel=.+1
    ld c, #00  ; c = right sub pixel = target pixel offset in the right adress
rightAdress=.+1
    ld de,#0000  ; de = right adress
    ld__a_iyh    ; a = input color

