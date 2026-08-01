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

.module cpct_draw

.globl cpct_getScreenPtr_asm
.globl cpct_plotColorTable_M1
.globl cpct_plotMasksTable_M1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: plot_mode1_asm
;;
;;    Draws a single pixel on screen in Mode 1 (320x200, 4 colors) at specified
;;    coordinates using lookup tables for masks and pixel color patterns.
;;
;; C Definition:
;;    void cpct_geometryPlotM1(u8* screen_start, u16 x, u8 y, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B DE) screen_start - Base VRAM memory address (typically 0xC000)
;;   (2B HL) x            - X coordinate in pixels (0-319)
;;   (1B C)  y            - Y coordinate in pixels (0-199)
;;   (1B B)  color        - Pen color index (0-3)
;;
;; Assembly call:
;;    > call cpct_geometryPlotM1_asm
;;
;; Requirements and limitations:
;;   * Coordinates must stay within Mode 1 screen bounds (X: 0-319, Y: 0-199).
;;   * Requires `cpct_getScreenPtr_asm`, `cpct_plotColorTable_M1`, and
;;     `cpct_plotMasksTable_M1` to be defined globally.
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    ASM routine - 63 bytes
;;      C routine - 67 bytes
;;
;; Time Measures:
;; (start code)
;;    Case      | microSecs (us)  | CPU Cycles
;; ------------------------------------------
;;    Execution | 93              | 372
;; ------------------------------------------
;;  W C binding | 104             | 416
;; ------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; 1. Extract pixel index (x & 3)
    ld    a, l            ;; [1] A = X coordinate low byte
    and   #3              ;; [2] Isolate lower 2 bits

    ;; 2. Convert X-pixels to X-bytes (HL = X / 4)
    srl   h               ;; [2] Shift X coordinate right
    rr    l               ;; [2] Rotate right through carry
    srl   h               ;; [2] Shift X coordinate right second time
    rr    l               ;; [2] L now contains X_byte coordinate (0-79)

    ld    h, c            ;; [1] H = C = Y coordinate
    ld    c, a            ;; [1] C = A = Pixel offset (0-3)
    push  bc              ;; [4] Save Color (B) and pixel offset (C) to stack

    ;; 3. Set registers for cpct_getScreenPtr_asm API
    ld    b, h            ;; [1] B = H = Y coordinate
    ld    c, l            ;; [1] C = L = X_byte coordinate

    ;; 4. Calculate VRAM pointer (DE=Base, B=Y, C=X_byte)
    ;; call instruction cost [5] + cpct_getScreenPtr_asm execution cost [28]
    ld    a, b               ;; [1] rA = Y-Coordinate
    and   #0x07              ;; [2] /
    ld    h, a               ;; [1] \ rH = Y % 8      
              
    ;; Now extract Screen Character Row (R) from Y-Coordinate
    ld    a, b               ;; [1] rA = Y-Coordinate
    and   #0xF8              ;; [2] /
    ld    l, a               ;; [1] \ rL = 8*int(Y/8)                                           
    rrca                     ;; [1] / rA' = rA / 4 = 2*int(Y/8)
    rrca                     ;; [1] \ 
    add   a, l               ;; [1] / rL = rL + rA' = 8*int(Y/8) + 2*int(Y/8) = 10*int(Y/8)
    ld    l, a               ;; [1] \ 

    ;; Now rHL = 256*L + 10*R
    add   hl, hl             ;; [3] / rHL' = 8*rHL
    add   hl, hl             ;; [3] | rHL' = 2048*L + 80*R
    add   hl, hl             ;; [3] \ 

    ;; Add up X coordinate
    ld    b, #00             ;; [2] / As rC = X-Coordinate, having rB=0 makes rBC = X-Coordinate
    add   hl, bc             ;; [3] \ rHL' = rHL + X 
	
	;; Add up screen start address we still keep in DE
    add   hl, de             ;; [3] rHL' = rHL + screen_start
	
    ;; 5. Restore pixel context
    pop   bc              ;; [3] B = Color, C = Pixel index (0-3)

    ;; 6. Apply background clearing mask
    ld    a, (hl)         ;; [2] A = Current screen byte from VRAM
    push  hl              ;; [4] Save screen byte pointer
    
    ld    hl, #cpct_plotMasksTable_M1 ;; [3] HL = Base address of mask table
    ld    e, c            ;; [1] E = Pixel index
    ld    d, #00          ;; [2] Clear D for 16-bit offset calculation
    add   hl, de          ;; [3] HL = &masks_table[pixel_index]
    ld    e, (hl)         ;; [2] E = Clearing mask byte
    and   e               ;; [1] A = Screen byte with target pixel cleared
    ld    e, a            ;; [1] E = Cleaned background pixels preserved
	
    ;; 7. Inject the new color bits
    ld    a, b            ;; [1] A = B = Color value (0-3)
    ld    b, e            ;; [1] B = Cleaned background pixels preserved
    add   a, a            ;; [1] Color * 2
    add   a, a            ;; [1] Color * 4
    add   a, c            ;; [1] A = (Color * 4) + Pixel index
    ld    e, a            ;; [1] E = Final color table offset
    ld    hl, #cpct_plotColorTable_M1 ;; [3] HL = Base address of color table
    add   hl, de          ;; [3] HL = &color_table[offset]
    ld    a, (hl)         ;; [2] A = Mode 1 interlaced color bit

    or    b               ;; [1] Merge new color bits into background
    pop   hl              ;; [3] Restore screen byte pointer
    ld    (hl), a         ;; [2] Write finalized byte back into VRAM

    ret                   ;; [3] Return to caller