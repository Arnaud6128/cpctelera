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

;; Global external symbols
.globl cpct_drawPlotM1_asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_drawCircleM1
;;
;;    Draws a circle on screen in Mode 1 (320x200, 4 colors) using the
;;    Midpoint Circle Algorithm.
;;
;; Algorithm & Details:
;;    The routine evaluates a single octant (1/8th) of the circle starting at
;;    coordinates (x = 0, y = radius) and iterates until x > y. For each
;;    calculated (x, y) point, 8 symmetrical points are plotted across all
;;    octants.
;;
;;    Decision Variable Optimization:
;;      Multiplying the decision variable d by 2 eliminates floating-point math:
;;        - Initial decision variable   : d = 3 - 2 * radius
;;        - If d <= 0 (East step)       : d_new = d + 4 * x + 6
;;        - If d > 0  (South-East step) : y = y - 1, d_new = d + 4 * (x - y) + 10
;;
;; C Definition:
;;    void cpct_drawCircleM1(void* memory, u16 cx, u16 cy, u8 radius, u8 color) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B HL)  memory     - Base VRAM memory address (typically 0xC000)
;;    (2B DE)  cx         - Center X coordinate (0-319)
;;    (1B IXH) Unused
;;    (1B IXL) cy         - Center Y coordinate (0-199)
;;    (1B B)   color      - Color index / byte pattern (0-3 or 8-bit mask)
;;    (1B C)   radius     - Radius (R) in pixels
;;
;; Assembly call:
;;    > call _cpct_drawCircleM1_asm
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;    258 bytes core routine 
;;     18 bytes C binding
;;      9 bytes Asm binding
;;
;; Time Measures (Excludes pixel plot function execution overhead):
;; (start code)
;;    Case / Coordinates                        | Pixels | microSecs (us) | CPU Cycles
;;   ---------------------------------------------------------------------------------
;;    Small Circle  (R = 5,  N = 4 iterations)  | ~32    | ~1046          | ~4184
;;    Medium Circle (R = 20, N = 15 iterations) | ~120   | ~3640          | ~14560
;;    Large Circle  (R = 50, N = 36 iterations) | ~288   | ~8628          | ~34512
;;   ---------------------------------------------------------------------------------
;; (end code)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ld   (smc_vram), hl        ;; [5] Inject VRAM base address into helper

    ;; Store cy into IYL (via A) and color into IYH (avoids SMC memory writes)
    ld__a_ixl                  ;; [2] A = cy (8-bit)
    ld__iyl_a                  ;; [2] IYL = cy (8-bit)
    ld__iyh_b                  ;; [2] IYH = color byte pattern
    ld    a, c                 ;; [1] A = radius

    ;; Inject cx into smc_cx
    ld    (smc_cx), de        ;; [5] Inject cx

    ;; ------------------------------------------------------------------------
    ;; Initialization: IXH = x = 0, IXL = y = radius
    ;; ------------------------------------------------------------------------
    ld__ixh #00                ;; [3] IXH = x = 0
    ld__ixl_a                  ;; [2] IXL = y = radius

    ;; Calculate initial decision variable d = 3 - (2 * radius)
    add   a, a                 ;; [1] A = 2 * radius
    ld    e, a                 ;; [1] E = 2 * radius
    ld    d, #00               ;; [2] DE = 2 * radius
    ld    hl, #3               ;; [3] HL = 3
    or    a                    ;; [1] Clear carry flag
    sbc   hl, de               ;; [4] HL = 3 - (2 * radius)
    ld   (smc_d), hl           ;; [5] Store initial decision variable d

;; Circle loop draw
circle_loop:
    ld__a_ixl                  ;; [2] A = y (IXL)
    cp__ixh                    ;; [2] Compare y with x (IXH)
    jp    c, ret_draw_circle   ;; [3] Exit loop if x > y

    ;; PLOT OCTANT 1 : (cx + x, cy + y)
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixl                  ;; [2] E = y
    add   a, e                 ;; [1] A = cy + y
    ld    c, a                 ;; [1] C = Y coordinate

smc_cx =.+1
    ld    hl, #0x0000          ;; [3] HL = cx
    ld__a_ixh                  ;; [2] A = x
    add   a, l                 ;; [1] Fast 8-bit addition into HL (HL = cx + x)
    ld    l, a                 ;; [1] 
    adc   a, h                 ;; [1] 
    sub   l                    ;; [1] 
    ld    h, a                 ;; [1] 
    call  plot_point           ;; [5] Plot (cx + x, cy + y)

    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 2 : (cx - x, cy + y)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixl                  ;; [2] E = y
    add   a, e                 ;; [1] A = cy + y
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__e_ixh                  ;; [2] E = x
    ld    d, #00               ;; [2] D = 0
    or    a                    ;; [1] Clear carry
    sbc   hl, de               ;; [4] HL = cx - x
    call  plot_point           ;; [5] Plot (cx - x, cy + y)

    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 3 : (cx + x, cy - y)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixl                  ;; [2] E = y
    sub   e                    ;; [1] A = cy - y
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__a_ixh                  ;; [2] A = x
    add   a, l                 ;; [1] Fast 8-bit addition into HL (HL = cx + x)
    ld    l, a                 ;; [1] 
    adc   a, h                 ;; [1] 
    sub   l                    ;; [1] 
    ld    h, a                 ;; [1] 
    call  plot_point           ;; [5] Plot (cx + x, cy - y)

    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 4 : (cx - x, cy - y)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixl                  ;; [2] E = y
    sub   e                    ;; [1] A = cy - y
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__e_ixh                  ;; [2] E = x
    ld    d, #00               ;; [2] D = 0
    or    a                    ;; [1] Clear carry
    sbc   hl, de               ;; [4] HL = cx - x
    call  plot_point           ;; [5] Plot (cx - x, cy - y)

    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 5 : (cx + y, cy + x)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixh                  ;; [2] E = x
    add   a, e                 ;; [1] A = cy + x
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__a_ixl                  ;; [2] A = y
    add   a, l                 ;; [1] Fast 8-bit addition into HL (HL = cx + y)
    ld    l, a                 ;; [1] 
    adc   a, h                 ;; [1] 
    sub   l                    ;; [1] 
    ld    h, a                 ;; [1] 
    call  plot_point           ;; [5] Plot (cx + y, cy + x)

    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 6 : (cx - y, cy + x)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixh                  ;; [2] E = x
    add   a, e                 ;; [1] A = cy + x
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__e_ixl                  ;; [2] E = y
    ld    d, #00               ;; [2] D = 0
    or    a                    ;; [1] Clear carry
    sbc   hl, de               ;; [4] HL = cx - y
    call  plot_point           ;; [5] Plot (cx - y, cy + x)

    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 7 : (cx + y, cy - x)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixh                  ;; [2] E = x
    sub   e                    ;; [1] A = cy - x
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__a_ixl                  ;; [2] A = y
    add   a, l                 ;; [1] Fast 8-bit addition into HL (HL = cx + y)
    ld    l, a                 ;; [1] 
    adc   a, h                 ;; [1] 
    sub   l                    ;; [1] 
    ld    h, a                 ;; [1] 
    call  plot_point           ;; [5] Plot (cx + y, cy - x)
 
    ;; ------------------------------------------------------------------------
    ;; PLOT OCTANT 8 : (cx - y, cy - x)
    ;; ------------------------------------------------------------------------
    ld__a_iyl                  ;; [2] A = cy
    ld__e_ixh                  ;; [2] E = x
    sub   e                    ;; [1] A = cy - x
    ld    c, a                 ;; [1] C = Y coordinate

    ld    hl, (smc_cx)         ;; [5] HL = cx
    ld__e_ixl                  ;; [2] E = y
    ld    d, #0                ;; [2] D = 0
    or    a                    ;; [1] Clear carry
    sbc   hl, de               ;; [4] HL = cx - y
    call  plot_point           ;; [5] Plot (cx - y, cy - x)

    inc__ixh                   ;; [2] x++

    ;; Update Decision Variable d
smc_d=.+1
    ld    hl, #0x0000          ;; [3] SMC: Load current decision variable d
    bit   7, h                 ;; [2] Test sign bit of d (Bit 7 of H)
    jr    z, d_positive        ;; [3] Jump if d > 0

    ;; Case d <= 0 : d = d + 4 * x + 6
    ld__e_ixh                  ;; [2] E = x (IXH)
    ld    d, #0                ;; [2] D = 0
    add   hl, de               ;; [3] HL = d + x
    add   hl, de               ;; [3] HL = d + 2x
    add   hl, de               ;; [3] HL = d + 3x
    add   hl, de               ;; [3] HL = d + 4x
    ld    de, #6               ;; [3] DE = 6
    add   hl, de               ;; [3] HL = d + 4x + 6
    ld   (smc_d), hl           ;; [5] Save updated d
    jp    circle_loop          ;; [3] Next iteration

    ;; Case d > 0 : y--, d = d + 4 * (x - y) + 10
d_positive:
    dec__ixl                   ;; [2] y--

    ld__a_ixh                  ;; [2] A = x
    sub__ixl                   ;; [2] A = x - y
    ld    e, a                 ;; [1] E = x - y
    add   a, a                 ;; [1] Sign expansion check
    sbc   a, a                 ;; [1] A = 0x00 if positive, 0xFF if negative
    ld    d, a                 ;; [1] DE = 16-bit signed (x - y)

    add   hl, de               ;; [3] HL = d + (x - y)
    add   hl, de               ;; [3] HL = d + 2*(x - y)
    add   hl, de               ;; [3] HL = d + 3*(x - y)
    add   hl, de               ;; [3] HL = d + 4*(x - y)
    ld    de, #10              ;; [3] DE = 10
    add   hl, de               ;; [3] HL = d + 4*(x - y) + 10
    ld   (smc_d), hl           ;; [5] Save updated d
    jp    circle_loop          ;; [3] Next iteration

;; ============================================================================
;; Fonction plot_point
;; ============================================================================
plot_point:
    ld__b_iyh                  ;; [2] Load color pattern from IYH
smc_vram =.+1
    ld    de, #0x0000          ;; [3] Inject VRAM base address
    jp    cpct_drawPlotM1_asm ;; [3] Jump to Mode 1 plot routine
