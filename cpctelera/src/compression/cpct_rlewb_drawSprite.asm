;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine
;;  Copyright (C) 2022 mvac7 for code decrunch RLEWB (@mvac7)
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
.module cpct_compression

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_rlewb_drawSprite
;;
;;   Decompresses and draws an RLEWB (Wonder Boy RLE) compressed sprite
;;   directly to Amstrad CPC video memory (VRAM).
;;
;; C Definition:
;;   void cpct_rlewb_drawSprite(const u8* src, u8* dst, u16 width) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B HL) src   - Pointer to compressed stream (RLEWB format)
;;   (2B DE) dst   - Pointer to destination screen address in VRAM
;;   (1B  C) width - Sprite width in bytes
;;
;; Assembly call:
;;   > call cpct_rlewb_drawSprite_asm (with HL=src, DE=dst, C=width)
;;
;; Data Format Details (Wonder Boy RLE / Direct Range Mode):
;;   CD = Control Digit  = 0x80
;;   ED = End Data Block = 0xFF
;;
;;   - CD + 0x00      --> Literal 0x80 byte value
;;   - CD + 0xFF      --> End of data block marker / sprite termination
;;   - CD + nn + dd   --> Repeat byte 'dd', 'nn' times (nn = 1..254)
;;   - dd (!= CD)     --> Uncompressed raw byte
;;
;; Destroyed Register values:
;;   AF, BC, DE, HL, IX, IY
;;
;; Required memory:
;;     C-bindings  - 114 bytes (111 bytes routine + 3 bytes C-binding wrapper)
;;   ASM-bindings  - 111 bytes (0 bytes RAM workspace required, 100% ROM-safe)
;;
;; Time Measures (1 NOP = 1 microSec = 4 CPU cycles @ 4 MHz) :
;; (start code)
;;  Case      |      microSecs (us)       |          CPU Cycles
;; ------------------------------------------------------------------
;;  RLE-full  | 53 + (47.25 + 6.25W)H + 4HH | 212 + (189 + 25W)H + 16HH
;;  Raw-only  | 53 + (18.75 + 13.0W)H + 4HH | 212 + (75  + 52W)H + 16HH
;; ------------------------------------------------------------------
;;  W=2, H=16 |        763 / 1013         |        3052 / 4052
;;  W=4, H=32 |       2273 / 2377         |        9092 / 9508
;;  W=8, H=32 |       3169 / 3817         |       12676 / 15268
;; ------------------------------------------------------------------
;;  Per byte  |  6.25 (RLE) / 13.0 (raw)  |   25 (RLE) / 52 (raw)
;; ------------------------------------------------------------------
;; (end code)
;;    W  = *width* in bytes
;;    H  = *height* in scanlines
;;    HH = number of 8-scanline character row crossings: [(H-1)/8]
;;    RLE-full = all lines drawn as single full RLE runs (inner loop: 25 cycles/byte)
;;    Raw-only = all bytes uncompressed raw tokens (52 cycles/byte)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CD = Control Digit = 0x80
RLEWB_CD  = #0x80
;; ED = End Data Block Marker = 0xFF
RLEWB_END = #0xFF

rlewb_draw_sprite:
    push iy                     ;; [5] Preserve IY register on stack
    push ix                     ;; [5] Preserve IX register on stack
    
    ;; Initialize index registers for fast CPC scanline stepping
    ld   a, c                   ;; [1] A = Sprite width (bytes per line)
    ld__ixh_c                   ;; [2] | IXH = width (stored for scanline reset)
    neg                         ;; [2] | A = -width (two's complement)
    ld__ixl_a                   ;; [2] | IXL = -width (stored for scanline arithmetic)
    ld   b, #0                  ;; [2] B = 0 (ensures BC = 16-bit counter for LDI)

;; ==============================================================================
;; 1. MAIN LOOP: TOKEN DECODING
;; ==============================================================================
unRLEWBRAM:
    ld   a, (hl)                ;; [2] Fetch next byte from compressed stream
    cp   #RLEWB_CD              ;; [2] Compare with Control Digit (0x80)
    jr   nz, write_Byte2RAM     ;; [2/3] | IF not 0x80 THEN treat as raw uncompressed byte

    inc  hl                     ;; [2] Advance source pointer to control parameter
    ld   a, (hl)                ;; [2] Read control byte parameter (nn)
    or   a                      ;; [1] Check if parameter == 0x00
    jr   z, write_DC2RAM        ;; [2/3] | IF 0x00 THEN write literal 0x80 byte
    cp   #RLEWB_END             ;; [2] Check if End Marker (0xFF)
    jr   z, exit_drawSprite_RLE ;; [2/3] | IF 0xFF THEN terminate decompression

;; ------------------------------------------------------------------------------
;; 2. RLE BLOCK: Extract repeat count and dispatch
;; ------------------------------------------------------------------------------
    ld   b, a                   ;; [1] B = repeat count (nn)
    inc  hl                     ;; [2] HL points directly to value byte (dd)

rle_run:
    ld   a, b                   ;; [1] A = remaining RLE run length
    sub  c                      ;; [1] Compute A = B - C (leftover) and set Carry if B < C
    jr   c, rle_partial         ;; [2/3] | IF B < C (Carry=1) THEN partial run within scanline

;; ------------------------------------------------------------------------------
;; 3. FULL CHUNK (B >= C): Fill up to the end of current scanline
;; ------------------------------------------------------------------------------
    ld__iyh_a                   ;; [2] Save leftover run (A = B - C) in IYH
    ld   b, c                   ;; [1] B = C (write up to end of scanline)
    ld   a, (hl)                ;; [2] Read pixel value directly from source stream (dd)

rle_w2:
    ld   (de), a                ;; [2] Write repeated byte to VRAM
    inc  de                     ;; [2] Advance destination VRAM pointer
    djnz rle_w2                 ;; [2/3] Loop chunk until end of scanline (no line test)

;; ------------------------------------------------------------------------------
;; 4. DIRECT 8-BIT CPC SCANLINE STEP (FOR RLE BLOCKS)
;;    DE_new = DE - width + 0x0800  (or + 0xC050 if 8-line boundary crossed)
;; ------------------------------------------------------------------------------
    ld   a, e                   ;; [1] Calculate next scanline E = E - width
    add__ixl                    ;; [2] | (produces Carry = 1)
    ld   e, a                   ;; [1] |
    ld   a, d                   ;; [1] Calculate next scanline D = D + 0x08
    adc  a, #0x07               ;; [2] | (D + 0x07 + Carry 1 = D + 0x08)
    ld   d, a                   ;; [1] |
    and  #0x38                  ;; [2] Check 8-line character block boundary
    jr   nz, rle_ls_ok          ;; [2/3] | IF inside block THEN skip correction

    ;; 8-line boundary crossed: Apply character row correction (+0xC050)
    ld   a, e                   ;; [1] Character row correction: E = E + 0x50
    add  a, #0x50               ;; [2] | (+80 bytes per character row)
    ld   e, a                   ;; [1] |
    ld   a, d                   ;; [1] Character row correction: D = D + 0xC0 + Carry
    adc  a, #0xC0               ;; [2] |
    ld   d, a                   ;; [1] |

rle_ls_ok:
    ld__c_ixh                   ;; [2] Reset line width counter C = width (IXH)
    ld__b_iyh                   ;; [2] B = leftover run count from IYH
    ld   a, b                   ;; [1] Check if leftover run > 0
    or   a                      ;; [1] |
    jr   nz, rle_run            ;; [2/3] | IF leftover > 0 THEN continue run on new scanline

    ;; RLE block complete
    inc  hl                     ;; [2] Advance source pointer past value byte (dd)
    jp   unRLEWBRAM             ;; [3] Process next token in stream

;; ------------------------------------------------------------------------------
;; 5. PARTIAL CHUNK (B < C): Run fits entirely within current scanline
;; ------------------------------------------------------------------------------
rle_partial:
    neg                         ;; [2] A = -(B - C) = C - B (remaining line width)
    ld   c, a                   ;; [1] C = updated remaining line width budget
    ld   a, (hl)                ;; [2] Read pixel value directly from source stream (dd)

rle_w1:
    ld   (de), a                ;; [2] Write repeated byte to VRAM
    inc  de                     ;; [2] Advance destination VRAM pointer
    djnz rle_w1                 ;; [2/3] Loop remaining run bytes

    inc  hl                     ;; [2] Advance source pointer past value byte (dd)
    jp   unRLEWBRAM             ;; [3] Block finished, return to main decoder loop

;; ==============================================================================
;; 6. RAW BYTES AND LITERAL 0x80 HANDLING
;; ==============================================================================
write_DC2RAM:
    ld   a, #RLEWB_CD           ;; [2] Load literal Control Digit (0x80)

write_Byte2RAM:
    ;; LDI copies (HL)->(DE), increments HL and DE, and decrements 16-bit counter BC.
    ;; The Parity/Overflow flag is set to PE (Parity Even / V=1) as long as BC != 0.
    ldi                         ;; [4] Copy raw byte (DE)=(HL), inc DE/HL, dec BC (C=width)
    jp   pe, unRLEWBRAM         ;; [3] | IF BC != 0 (not end of line) THEN next token

;; ------------------------------------------------------------------------------
;; 7. DIRECT 8-BIT CPC SCANLINE STEP (FOR RAW BYTES AT END OF SCANLINE)
;; ------------------------------------------------------------------------------
    ld   a, e                   ;; [1] Calculate next scanline E = E - width
    add__ixl                    ;; [2] | (produces Carry = 1)
    ld   e, a                   ;; [1] |
    ld   a, d                   ;; [1] Calculate next scanline D = D + 0x08
    adc  a, #0x07               ;; [2] | (D + 0x07 + Carry 1 = D + 0x08)
    ld   d, a                   ;; [1] |
    and  #0x38                  ;; [2] Check 8-line character block boundary
    jr   nz, rv_ok              ;; [2/3] | IF inside block THEN skip correction

    ;; 8-line boundary crossed: Apply character row correction (+0xC050)
    ld   a, e                   ;; [1] Character row correction: E = E + 0x50
    add  a, #0x50               ;; [2] | (+80 bytes per character row)
    ld   e, a                   ;; [1] |
    ld   a, d                   ;; [1] Character row correction: D = D + 0xC0 + Carry
    adc  a, #0xC0               ;; [2] |
    ld   d, a                   ;; [1] |

rv_ok:
    ld__c_ixh                   ;; [2] Reset line width counter C = width (IXH)
    ;; Note: B is already 0 (untouched by 8-bit math), ensuring BC = C for future LDIs
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

;; ==============================================================================
;; 8. DECOMPRESSION TERMINATION & EXIT
;; ==============================================================================
exit_drawSprite_RLE:
    pop  ix                     ;; [4] Restore IX register
    pop  iy                     ;; [4] Restore IY register
    ret                         ;; [3] Return cleanly to caller