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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_setClipRect
;;
;;    Sets the clipping rectangle used by <cpct_clipLine>. Bounds are inclusive.
;;
;; C Definition:
;;    void cpct_setClipRect(i16 xmin, i16 ymin, i16 xmax, i16 ymax) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B HL)    xmin - Left bound   (inclusive)
;;    (2B DE)    ymin - Top bound    (inclusive)
;;    (2B Stack) xmax - Right bound  (inclusive)
;;    (2B Stack) ymax - Bottom bound (inclusive)
;;
;; Details:
;;    The default clipping rectangle is the whole Mode 1 screen (0, 0, 319, 199).
;;    For Mode 0, use cpct_setClipRect(0, 0, 159, 199). A smaller rectangle
;;    can be used to clip lines inside a window or a viewport.
;;
;; Destroyed Register values:
;;    BC, DE, HL
;;
;; Time Measures:
;;    ~30 microSecs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_cpct_setClipRect::
    ld    (clip_xmin), hl         ;; [5] Store xmin
    ex    de, hl                  ;; [1] HL = ymin
    ld    (clip_ymin), hl         ;; [5] Store ymin
    pop   bc                      ;; [3] BC = return address
    pop   hl                      ;; [3] HL = xmax
    inc   hl                      ;; [2] HL = xmax + 1
    ld    (clip_xend), hl         ;; [5] Store xmax + 1
    pop   hl                      ;; [3] HL = ymax
    inc   hl                      ;; [2] HL = ymax + 1
    ld    (clip_yend), hl         ;; [5] Store ymax + 1
    push  bc                      ;; [4] Restore return address (__z88dk_callee)
    ret                           ;; [3]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_clipLine
;;
;;    Clips the line segment (X0, Y0) - (X1, Y1) against the clipping rectangle
;;    set by <cpct_setClipRect>, using the Cohen-Sutherland algorithm.
;;    Mode independent: use it before any cpct_drawLine* function.
;;
;; C Definition:
;;    u8 cpct_clipLine(i16* x0, i16* y0, i16* x1, i16* y1) __z88dk_callee;
;;
;; Input Parameters:
;;    (2B HL)    x0 - Pointer to starting X coordinate
;;    (2B DE)    y0 - Pointer to starting Y coordinate
;;    (2B Stack) x1 - Pointer to ending X coordinate
;;    (2B Stack) y1 - Pointer to ending Y coordinate
;;
;; Return Value:
;;    (1B A) 1 if (part of) the line is inside the clipping rectangle: the 4
;;           coordinates are updated with the clipped segment.
;;           0 if the line is fully outside: the coordinates are left unchanged.
;;
;; Parameter Restrictions:
;;    * Coordinates must be in the range [-16384, 16383], so that differences
;;      between coordinates fit in 16 bits.
;;
;; Details:
;;    Each endpoint outside of the rectangle is moved to the intersection of
;;    the line with the crossed edge. The intersection is computed exactly and
;;    rounded to the nearest integer, with only 16-bit arithmetic: the
;;    multiplication and the division are merged in a single loop over the
;;    significant bits of the moved coordinate delta (no 32-bit product). The direction of the line is kept (X0, Y0 stays the
;;    starting point), so that the clipped line is drawn in the same direction.
;;    As the clipped line starts at a rounded intersection, its pixels may
;;    differ by 1 from the pixels of the unclipped line near the edges.
;;
;; Usage example:
;; (start code)
;;    i16 x0 = -40, y0 = 20, x1 = 400, y1 = 150;
;;    if (cpct_clipLine(&x0, &y0, &x1, &y1))
;;       cpct_drawLineM1_f(CPCT_VMEM_START, x0, y0, x1, y1, 1);
;; (end code)
;;
;; Known limitations:
;;  * This function will not work from ROM, as the clipping rectangle is
;;    stored with the code.
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL
;;
;; Required memory:
;;    571 bytes (<cpct_setClipRect> + <cpct_clipLine> + clipping rectangle
;;    and working data)
;;
;; Time Measures (Measured from C, including call overhead):
;; (start code)
;;    Case (default clipping rectangle)               | microSecs (us)
;;   --------------------------------------------------------------------
;;    Fully inside        (10,10)  - (300,150)        | ~375
;;    Fully outside       (-50,-20) - (-10,250)       | ~380
;;    1 endpoint clipped  (-50,20) - (300,150)        | ~1115
;;    2 endpoints clipped (-50,-20) - (400,250)       | ~2900
;;   --------------------------------------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_cpct_clipLine::
    ;; ---- Get pointers (HL = &x0, DE = &y0, stack = &x1, &y1) and coordinates ----
    ld    (ptr_x0), hl            ;; [5] Store &x0
    ld    c, (hl)                 ;; [2] X0 = *(&x0)
    inc   hl                      ;; [2] |
    ld    b, (hl)                 ;; [2] |
    ld    (cx0), bc               ;; [6] |
    ex    de, hl                  ;; [1] HL = &y0
    ld    (ptr_y0), hl            ;; [5] Store &y0
    ld    c, (hl)                 ;; [2] Y0 = *(&y0)
    inc   hl                      ;; [2] |
    ld    b, (hl)                 ;; [2] |
    ld    (cy0), bc               ;; [6] |
    pop   de                      ;; [3] DE = return address
    pop   hl                      ;; [3] HL = &x1
    ld    (ptr_x1), hl            ;; [5] Store &x1
    ld    c, (hl)                 ;; [2] X1 = *(&x1)
    inc   hl                      ;; [2] |
    ld    b, (hl)                 ;; [2] |
    ld    (cx1), bc               ;; [6] |
    pop   hl                      ;; [3] HL = &y1
    ld    (ptr_y1), hl            ;; [5] Store &y1
    ld    c, (hl)                 ;; [2] Y1 = *(&y1)
    inc   hl                      ;; [2] |
    ld    b, (hl)                 ;; [2] |
    ld    (cy1), bc               ;; [6] |
    push  de                      ;; [4] Restore return address (__z88dk_callee)

    xor   a                       ;; [1] Endpoints not swapped, no edge crossed
    ld    (swapped), a            ;; [4] |
    ld    (clipped), a            ;; [4] |

    ;; ---- Outcode of P1 is computed once: P1 only changes when endpoints are swapped ----
    ld    hl, (cx1)               ;; [5] HL = X1
    ld    de, (cy1)               ;; [6] DE = Y1
    call  outcode                 ;; [5] A = outcode(P1)
    ld    (code1), a              ;; [4] Store outcode(P1)

clip_loop:
    ;; ---- B = outcode(P0), C = outcode(P1) ----
    ld    hl, (cx0)               ;; [5] HL = X0
    ld    de, (cy0)               ;; [6] DE = Y0
    call  outcode                 ;; [5] A = outcode(P0)
    ld    b, a                    ;; [1] B = outcode(P0)
    ld    a, (code1)              ;; [4] C = outcode(P1)
    ld    c, a                    ;; [1] |

    or    b                       ;; [1] IF both endpoints inside
    jp    z, accept               ;; [3] THEN accept
    ld    a, b                    ;; [1] IF both endpoints outside of the same edge
    and   c                       ;; [1] |
    jp    nz, reject              ;; [3] THEN reject

    ld    a, b                    ;; [1] IF P0 is inside
    or    a                       ;; [1] |
    jr    nz, clip_p0             ;; [2/3] |
    call  swap_points             ;; [5] THEN swap endpoints so that P0 is outside
    xor   a                       ;; [1] | Outcode of new P1 = 0 (old P0 was inside)
    ld    (code1), a              ;; [4] |
    ld    b, c                    ;; [1] | B = outcode of new P0
clip_p0:
    ;; ---- Move P0 to the first crossed edge: Top, Bottom, Left, Right ----
    bit   2, b                    ;; [2] IF above top edge
    jr    z, not_top              ;; [2/3] |
    ld    hl, (clip_ymin)         ;; [5] THEN Y edge = ymin
    jr    clip_y                  ;; [3]
not_top:
    bit   3, b                    ;; [2] IF below bottom edge
    jr    z, not_bottom           ;; [2/3] |
    ld    hl, (clip_yend)         ;; [5] THEN Y edge = ymax
    dec   hl                      ;; [2] |
    jr    clip_y                  ;; [3]
not_bottom:
    bit   0, b                    ;; [2] IF left of left edge
    jr    z, not_left             ;; [2/3] |
    ld    hl, (clip_xmin)         ;; [5] THEN X edge = xmin
    jr    clip_x                  ;; [3]
not_left:
    ld    hl, (clip_xend)         ;; [5] ELSE X edge = xmax
    dec   hl                      ;; [2] |
    jr    clip_x                  ;; [3]

    ;; ---- Horizontal edge Ye: X0 += (X1 - X0) * (Ye - Y0) / (Y1 - Y0), Y0 = Ye ----
clip_y:
    ld    de, #cx0                ;; [3] DE = &A0 = &X0 (coordinate moved along the edge)
    ld    bc, #cy0                ;; [3] BC = &B0 = &Y0 (coordinate set to the edge)
    jr    clip_edge               ;; [3]

    ;; ---- Vertical edge Xe: Y0 += (Y1 - Y0) * (Xe - X0) / (X1 - X0), X0 = Xe ----
clip_x:
    ld    de, #cy0                ;; [3] DE = &A0 = &Y0 (coordinate moved along the edge)
    ld    bc, #cx0                ;; [3] BC = &B0 = &X0 (coordinate set to the edge)

    ;; HL = edge, DE = &A0, BC = &B0 (A1 / B1 are 8 bytes after A0 / B0)
    ;; A0 += round((A1 - A0) * (edge - B0) / (B1 - B0)), B0 = edge
clip_edge:
    ld    a, #1                   ;; [2] An edge is crossed: coordinates will change
    ld    (clipped), a            ;; [4] |
    ld    (edge), hl              ;; [5] Save edge value
    ld    (a0_ptr), de            ;; [6] Save &A0
    ld    (b0_ptr), bc            ;; [6] Save &B0
    ld    h, b                    ;; [1] HL = &B0
    ld    l, c                    ;; [1] |
    call  load_pair               ;; [5] DE = B0, HL = B1
    push  de                      ;; [4] Save B0
    or    a                       ;; [1] t_d = |B1 - B0|
    sbc   hl, de                  ;; [4] |
    call  abs_hl                  ;; [5] |
    ld    (t_d), hl               ;; [5] |
    pop   de                      ;; [3] DE = B0
    ld    hl, (edge)              ;; [5] t_e = |edge - B0|
    or    a                       ;; [1] |
    sbc   hl, de                  ;; [4] |
    call  abs_hl                  ;; [5] |
    ld    (t_e), hl               ;; [5] |
    ld    hl, (a0_ptr)            ;; [5] HL = &A0
    call  load_pair               ;; [5] DE = A0, HL = A1
    push  de                      ;; [4] Save A0
    or    a                       ;; [1] HL = t_da = A1 - A0
    sbc   hl, de                  ;; [4] |
    call  intersect               ;; [5] HL = round(t_da * t_e / t_d)
    pop   de                      ;; [3] DE = A0
    add   hl, de                  ;; [3] DE = A0 + offset
    ex    de, hl                  ;; [1] |
    ld    hl, (a0_ptr)            ;; [5] Store new A0
    ld    (hl), e                 ;; [2] |
    inc   hl                      ;; [2] |
    ld    (hl), d                 ;; [2] |
    ld    de, (edge)              ;; [6] Store B0 = edge
    ld    hl, (b0_ptr)            ;; [5] |
    ld    (hl), e                 ;; [2] |
    inc   hl                      ;; [2] |
    ld    (hl), d                 ;; [2] |
    jp    clip_loop               ;; [3] Next clipping step

accept:
    ld    a, (clipped)            ;; [4] IF no edge was crossed
    or    a                       ;; [1] |
    jr    z, accept_end           ;; [2/3] THEN coordinates are unchanged
    ld    a, (swapped)            ;; [4] IF endpoints were swapped
    or    a                       ;; [1] |
    call  nz, swap_points         ;; [3/5] THEN restore original direction
    ;; ---- Copy back the 4 clipped coordinates to their pointers ----
    ld    hl, (ptr_x0)            ;; [5] *(&x0) = X0
    ld    de, (cx0)               ;; [6] |
    ld    (hl), e                 ;; [2] |
    inc   hl                      ;; [2] |
    ld    (hl), d                 ;; [2] |
    ld    hl, (ptr_y0)            ;; [5] *(&y0) = Y0
    ld    de, (cy0)               ;; [6] |
    ld    (hl), e                 ;; [2] |
    inc   hl                      ;; [2] |
    ld    (hl), d                 ;; [2] |
    ld    hl, (ptr_x1)            ;; [5] *(&x1) = X1
    ld    de, (cx1)               ;; [6] |
    ld    (hl), e                 ;; [2] |
    inc   hl                      ;; [2] |
    ld    (hl), d                 ;; [2] |
    ld    hl, (ptr_y1)            ;; [5] *(&y1) = Y1
    ld    de, (cy1)               ;; [6] |
    ld    (hl), e                 ;; [2] |
    inc   hl                      ;; [2] |
    ld    (hl), d                 ;; [2] |
accept_end:
    ld    a, #1                   ;; [2] Return 1: line visible
    ret                           ;; [3]

reject:
    xor   a                       ;; [1] Return 0: line fully outside
    ret                           ;; [3]

;; ----------------------------------------------------------------------------
;; Helper Routine: outcode
;;    Input : HL = X, DE = Y
;;    Output: A = outcode (bit0 = left, bit1 = right, bit2 = top, bit3 = bottom)
;;    Destroyed: AF, BC, DE, HL
;; ----------------------------------------------------------------------------
outcode:
    xor   a                       ;; [1] A = 0 (inside), Carry = 0
    ld    bc, (clip_xmin)         ;; [6] IF X < xmin
    push  hl                      ;; [4] |
    sbc   hl, bc                  ;; [4] |
    pop   hl                      ;; [3] |
    jp    p, oc_not_left          ;; [3] |
    or    #1                      ;; [2] THEN left
oc_not_left:
    ld    bc, (clip_xend)         ;; [6] IF X >= xmax + 1
    or    a                       ;; [1] |
    sbc   hl, bc                  ;; [4] |
    jp    m, oc_not_right         ;; [3] |
    or    #2                      ;; [2] THEN right
oc_not_right:
    ex    de, hl                  ;; [1] HL = Y
    ld    bc, (clip_ymin)         ;; [6] IF Y < ymin
    push  hl                      ;; [4] |
    or    a                       ;; [1] |
    sbc   hl, bc                  ;; [4] |
    pop   hl                      ;; [3] |
    jp    p, oc_not_top           ;; [3] |
    or    #4                      ;; [2] THEN top
oc_not_top:
    ld    bc, (clip_yend)         ;; [6] IF Y >= ymax + 1
    or    a                       ;; [1] |
    sbc   hl, bc                  ;; [4] |
    ret   m                       ;; [2/4] |
    or    #8                      ;; [2] THEN bottom
    ret                           ;; [3]

;; ----------------------------------------------------------------------------
;; Helper Routine: swap_points
;;    Swaps (X0, Y0) and (X1, Y1) and toggles the swapped flag
;;    Destroyed: AF, DE, HL
;; ----------------------------------------------------------------------------
swap_points:
    ld    hl, (cx0)               ;; [5] Swap X0 and X1
    ld    de, (cx1)               ;; [6] |
    ld    (cx0), de               ;; [6] |
    ld    (cx1), hl               ;; [5] |
    ld    hl, (cy0)               ;; [5] Swap Y0 and Y1
    ld    de, (cy1)               ;; [6] |
    ld    (cy0), de               ;; [6] |
    ld    (cy1), hl               ;; [5] |
    ld    a, (swapped)            ;; [4] Toggle swapped flag
    xor   #1                      ;; [2] |
    ld    (swapped), a            ;; [4] |
    ret                           ;; [3]

;; ----------------------------------------------------------------------------
;; Helper Routine: load_pair
;;    Input : HL = &V0 (V1 is 8 bytes after V0)
;;    Output: DE = V0, HL = V1
;;    Destroyed: AF, BC, DE, HL
;; ----------------------------------------------------------------------------
load_pair:
    ld    e, (hl)                 ;; [2] DE = V0
    inc   hl                      ;; [2] |
    ld    d, (hl)                 ;; [2] |
    ld    bc, #7                  ;; [3] HL = &V1
    add   hl, bc                  ;; [3] |
    ld    a, (hl)                 ;; [2] HL = V1
    inc   hl                      ;; [2] |
    ld    h, (hl)                 ;; [2] |
    ld    l, a                    ;; [1] |
    ret                           ;; [3]

;; ----------------------------------------------------------------------------
;; Helper Routine: intersect
;;    Input : HL = t_da, (t_e) = |edge - B0|, (t_d) = |B1 - B0|
;;            with |t_e| <= |t_d|, t_d != 0 (edge - B0 and B1 - B0 have the same sign)
;;    Output: HL = round(t_da * |t_e| / |t_d|) with the sign of t_da
;;    Destroyed: AF, BC, DE, HL
;;
;;    Multiplication and division are merged in a single 16-bit loop over the
;;    bits of |t_da| (no 32-bit arithmetic): for each bit, from the most
;;    significant one, the invariant  |t_da|_prefix * E = q * D + r  (0 <= r < D)
;;    is kept with q = 2q, r = 2r (+ E if the bit is set), and at most one
;;    subtraction of D after each addition (as r < D and E <= D).
;;    Leading zero bits of |t_da| are skipped, so the loop runs only for its
;;    significant bits. Rounding to nearest: q++ when 2r >= D.
;; ----------------------------------------------------------------------------
intersect:
    ld    a, h                    ;; [1] Save sign of t_da
    push  af                      ;; [4] |
    call  abs_hl                  ;; [5] HL = |t_da|
    push  ix                      ;; [5] Preserve IX (used for q)
    ld    a, l                    ;; [1] Save low byte of |t_da|
    ld    (da_lo), a              ;; [4] |
    ld    a, h                    ;; [1] A = high byte of |t_da|
    ld    ix, #0                  ;; [4] IX = q = 0
    ld    hl, #0                  ;; [3] HL = r = 0
    ld    bc, (t_e)               ;; [6] BC = E = |t_e|
    ld    de, (t_d)               ;; [6] DE = D = |t_d|
    or    a                       ;; [1] IF high byte != 0
    jr    z, md_low_first         ;; [2/3] |
    call  md_byte_first           ;; [5] THEN process high byte (from its first set bit)
    ld    a, (da_lo)              ;; [4] |
    call  md_byte                 ;; [5] | and all the bits of the low byte
    jr    md_round                ;; [3]
md_low_first:
    ld    a, (da_lo)              ;; [4] ELSE IF low byte != 0
    or    a                       ;; [1] |
    call  nz, md_byte_first       ;; [3/5] THEN process low byte (from its first set bit)

md_round:
    add   hl, hl                  ;; [3] IF 2r >= D (2r < 65536 as r < D <= 32767)
    or    a                       ;; [1] |
    sbc   hl, de                  ;; [4] |
    jr    c, md_q_ok              ;; [2/3] |
    inc   ix                      ;; [3] THEN round up: q++
md_q_ok:
    push  ix                      ;; [5] HL = q
    pop   hl                      ;; [3] |
    pop   ix                      ;; [4] Restore IX

    ;; Apply sign of t_da
    pop   af                      ;; [3] A = high byte of t_da
    rla                           ;; [1] IF t_da >= 0
    ret   nc                      ;; [2/4] THEN result is positive
abs_neg:
    xor   a                       ;; [1] HL = -HL
    sub   l                       ;; [1] |
    ld    l, a                    ;; [1] |
    sbc   a, a                    ;; [1] |
    sub   h                       ;; [1] |
    ld    h, a                    ;; [1] |
    ret                           ;; [3]

;; ----------------------------------------------------------------------------
;; Helper Routine: abs_hl (HL = |HL|, destroys AF)
;; ----------------------------------------------------------------------------
abs_hl:
    bit   7, h                    ;; [2] IF HL >= 0
    ret   z                       ;; [2/4] THEN done
    jr    abs_neg                 ;; [3] ELSE negate

;; ----------------------------------------------------------------------------
;; Helper Routines: md_byte / md_byte_first
;;    Merged multiplication / division steps for the 8 bits of A (MSB first)
;;    In/Out: HL = r, IX = q    Preserved: BC = E, DE = D
;;    md_byte_first skips the leading zero bits of A (A must not be 0)
;;    A sentinel bit is shifted in below the data bits: the loop ends when
;;    it is shifted out (A becomes 0).
;; ----------------------------------------------------------------------------
md_byte_first:
    scf                           ;; [1] A = (A << 1) | 1 (sentinel), Carry = bit 7
    adc   a, a                    ;; [1] |
md_skip:
    jr    c, md_one               ;; [2/3] First set bit found: process it
    add   a, a                    ;; [1] Skip leading zero bit
    jr    md_skip                 ;; [3]
md_byte:
    scf                           ;; [1] A = (A << 1) | 1 (sentinel), Carry = bit 7
    adc   a, a                    ;; [1] |
    jr    md_bit                  ;; [3]
md_loop:
    add   a, a                    ;; [1] Carry = next bit, Z = sentinel shifted out
    ret   z                       ;; [2/4] IF sentinel THEN byte done
md_bit:
    jr    c, md_one               ;; [2/3] IF bit = 1 THEN process bit 1
    ;; ---- Bit 0: q = 2q, r = 2r ----
    add   ix, ix                  ;; [4] q = 2q
    add   hl, hl                  ;; [3] r = 2r (Carry = 0 as r < D <= 32767)
    sbc   hl, de                  ;; [4] IF r >= D
    jr    nc, md_zero_sub         ;; [2/3] |
    add   hl, de                  ;; [3] ELSE restore r
    jr    md_loop                 ;; [3]
md_zero_sub:
    inc   ix                      ;; [3] THEN r -= D, q++
    jr    md_loop                 ;; [3]
    ;; ---- Bit 1: q = 2q, r = 2r + E ----
md_one:
    add   ix, ix                  ;; [4] q = 2q
    add   hl, hl                  ;; [3] r = 2r (Carry = 0 as r < D <= 32767)
    sbc   hl, de                  ;; [4] IF r >= D
    jr    nc, md_one_sub          ;; [2/3] |
    add   hl, de                  ;; [3] ELSE restore r
    jr    md_one_add              ;; [3]
md_one_sub:
    inc   ix                      ;; [3] THEN r -= D, q++
md_one_add:
    add   hl, bc                  ;; [3] r += E (r < 2D <= 65534)
    or    a                       ;; [1] IF r >= D
    sbc   hl, de                  ;; [4] |
    jr    nc, md_zero_sub         ;; [2/3] THEN r -= D, q++
    add   hl, de                  ;; [3] ELSE restore r
    jr    md_loop                 ;; [3]

;; ----------------------------------------------------------------------------
;; Clipping rectangle (stored with the code: default = whole Mode 1 screen)
;; ----------------------------------------------------------------------------
clip_xmin:  .dw 0              ;; Left bound (inclusive)
clip_ymin:  .dw 0              ;; Top bound (inclusive)
clip_xend:  .dw 320            ;; Right bound + 1
clip_yend:  .dw 200            ;; Bottom bound + 1

;; ----------------------------------------------------------------------------
;; Working data: { pointer, value } entries for X0, Y0, X1, Y1 (in this order)
;; ----------------------------------------------------------------------------
ptr_x0:     .dw 0              ;; Pointer to X0
cx0:        .dw 0              ;; X0
ptr_y0:     .dw 0              ;; Pointer to Y0
cy0:        .dw 0              ;; Y0
ptr_x1:     .dw 0              ;; Pointer to X1
cx1:        .dw 0              ;; X1
ptr_y1:     .dw 0              ;; Pointer to Y1
cy1:        .dw 0              ;; Y1
edge:       .dw 0              ;; Value of the crossed edge
a0_ptr:     .dw 0              ;; Pointer to the coordinate of P0 moved along the edge
b0_ptr:     .dw 0              ;; Pointer to the coordinate of P0 set to the edge
t_e:        .dw 0              ;; |Edge - B0|
t_d:        .dw 0              ;; |B1 - B0|
swapped:    .db 0              ;; 1 if endpoints are swapped
clipped:    .db 0              ;; 1 if at least one edge was crossed
code1:      .db 0              ;; Outcode of P1
da_lo:      .db 0              ;; Low byte of |t_da| (intersect)
