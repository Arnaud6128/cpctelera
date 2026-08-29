;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;   AF, BC, DE, HL, IX
;;
;; Required memory:
;;     C-bindings  - 128 bytes  (routine + 3 bytes binding + 2 bytes workspace RAM)
;;   ASM-bindings  - 125 bytes  (routine + 2 bytes workspace RAM)
;;
;; Time Measures (1 NOP = 1 microSec = 4 CPU cycles @ 4 MHz) :
;; (start code)
;;  Case      |    microSecs (us)        |         CPU Cycles
;; ----------------------------------------------------------------
;;  Best      | 20 + (28 + 7W)H + 4HH    | 80 + (110 + 26W)H + 16HH
;;  Worst     |      Best + 7WH          |     Best + 26WH
;; ----------------------------------------------------------------
;;  W=2,H=16  |       672 /  880         |   2688 / 3520
;;  W=4,H=32  |      1744 / 2576         |   6976 / 10304
;; ----------------------------------------------------------------
;;  Per byte  |   7 (RLE) / 13 (raw)     |   26 (RLE) / 52 (raw)
;; ----------------------------------------------------------------
;; (end code)
;;    W = *width* in bytes, H = *height* in bytes, HH = [(H-1)/8]
;;    Best  = all bytes RLE-encoded (runs aligned to lines)
;;    Worst = all bytes raw (no runs)
;;
;; Optimization:
;;   Instead of checking for the end of the scanline on every single byte
;;   inside the inner loop, the routine compares the RLE run length (B)
;;   with the remaining bytes on the current scanline (C):
;;     - If B < C  : Fast inner DJNZ loop with no line checks.
;;     - If B >= C : Fills up to the end of the scanline, steps to the next
;;                   CPC scanline, and resumes the leftover run on the new line.
;;
;; Credits:
;;    * RLEWB encoder is inspired from Wonder Boy RLE  [https://www.smspower.org/Development/Compression#WonderBoyRLE](https://www.smspower.org/Development/Compression#WonderBoyRLE)
;;    * Original code by mvac7  [https://github.com/mvac7/Z80_RLEWB](https://github.com/mvac7/Z80_RLEWB)
;;    * Optimization support  [https://www.cpcwiki.eu/forum/programming/draw-spriterle-optimization/](https://www.cpcwiki.eu/forum/programming/draw-spriterle-optimization/)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CD = Control Digit = 0x80
RLEWB_CD  = #0x80
;; ED = End Data Block Marker = 0xFF
RLEWB_END = #0xFF

rlewb_draw_sprite:
    push ix                     ;; [4] Preserve SDCC frame pointer IX on stack
    
    ;; Initialize index registers for fast CPC scanline stepping
    ld   a, c                   ;; [1] A = Sprite width (bytes per line)
    ld__ixh_c                   ;; [2] IXH = width (preserved to reset scanline counter C)
    neg                         ;; [2] A = -width (two's complement)
    ld__ixl_a                   ;; [2] IXL = -width (used for scanline address arithmetic)
    ld   b, #0                  ;; [2] B = 0 -> BC = 16-bit counter initialized for LDI

;; ==============================================================================
;; 1. MAIN LOOP: TOKEN DECODING
;; ==============================================================================
unRLEWBRAM:
    ld   a, (hl)                ;; [2] Fetch next byte from compressed stream
    cp   #RLEWB_CD              ;; [2] Compare with Control Digit (0x80)
    jr   nz, write_Byte2RAM     ;; [2/3] IF not 0x80 THEN treat as raw uncompressed byte

    inc  hl                     ;; [2] Advance source pointer to control parameter
    ld   a, (hl)                ;; [2] A = parameter byte
    or   a                      ;; [1] Check if parameter == 0x00 (literal 0x80)
    jr   z, write_DC2RAM        ;; [2/3] IF 0x00 THEN write literal 0x80 byte
    cp   #RLEWB_END             ;; [2] Check if parameter == 0xFF (end marker)
    jr   z, exit_drawSprite_RLE ;; [2/3] IF 0xFF THEN terminate decompression

;; ------------------------------------------------------------------------------
;; 2. RLE BLOCK: Extract repeat count and value
;; ------------------------------------------------------------------------------
    ld   b, a                   ;; [1] B = repeat count (nn)
    inc  hl                     ;; [2] Advance source pointer to value byte (dd)
    ld   a, (hl)                ;; [2] A = value byte to repeat (dd)
    ld   (rle_value), a         ;; [3] Store value in RAM workspace for chunk reloads

rle_run:
    ld   a, b                   ;; [1] A = remaining RLE run length
    cp   c                      ;; [1] Compare run length vs remaining bytes on line (C)
    jr   c, rle_partial         ;; [2/3] IF B < C THEN run fits entirely on current scanline

;; ------------------------------------------------------------------------------
;; 3. FULL CHUNK (B >= C): Fill up to the end of current scanline
;; ------------------------------------------------------------------------------
    ld   a, b                   ;; [1] A = total run length
    sub  c                      ;; [1] A = leftover run to carry over to next scanline
    ld   (rle_left), a          ;; [3] Store leftover run count in RAM workspace
    ld   b, c                   ;; [1] B = C -> write exactly up to the end of the line
    ld   a, (rle_value)         ;; [3] Reload pixel value into A

rle_w2:
    ld   (de), a                ;; [2] Write pixel byte to VRAM
    inc  de                     ;; [2] Advance destination VRAM pointer
    djnz rle_w2                 ;; [2/3] Fast loop (no scanline check required)

;; ------------------------------------------------------------------------------
;; 4. CPC SCANLINE STEP (FOR RLE BLOCKS)
;;    Formula: Next_Line = Current_Line_End - width + 0x0800
;;    Math: HL + 0x0700 + (256 - width) = HL + 0x0800 - width (via low-byte carry)
;; ------------------------------------------------------------------------------
    ex   de, hl                 ;; [1] Swap: HL = VRAM pointer, DE = source pointer
    ld   b, #0x07               ;; [2] High byte for intra-character line step (+0x0700)
    ld__c_ixl                   ;; [2] C = -width (IXL)
    add  hl, bc                 ;; [3] HL = start of next scanline

    ;; Test 8-line character block boundary (bits 3, 4, 5 of H)
    ld   a, h                   ;; [1] A = high byte of VRAM address
    and  #0x38                  ;; [2] Mask intra-character scanline bits
    jr   nz, rle_ls_ok          ;; [2/3] IF non-zero -> still within 8-line block (skip correction)

    ;; 8-line boundary crossed: Apply character row correction (+0xC050 / +80 bytes)
    ld   bc, #0xC050            ;; [3] Character row correction offset
    add  hl, bc                 ;; [3] HL points to first scanline of next character row

rle_ls_ok:
    ex   de, hl                 ;; [1] Restore: DE = VRAM (next line start), HL = source
    ld__c_ixh                   ;; [2] Reset line width counter C = width (IXH)
    ld   a, (rle_left)          ;; [3] A = leftover run count
    ld   b, a                   ;; [1] B = leftover run (restored after scanline step)
    or   a                      ;; [1] Are there remaining bytes to write?
    jr   nz, rle_run            ;; [2/3] IF leftover > 0 THEN continue run on new scanline

    ;; RLE block complete
    inc  hl                     ;; [2] Advance source pointer past value byte (dd)
    jp   unRLEWBRAM             ;; [3] Process next token in stream

;; ------------------------------------------------------------------------------
;; 5. PARTIAL CHUNK (B < C): Run fits entirely within current scanline
;; ------------------------------------------------------------------------------
rle_partial:
    ld   a, c                   ;; [1] A = remaining line width
    sub  b                      ;; [1] A = line width remaining after this run
    ld   c, a                   ;; [1] C = updated remaining line width budget
    ld   a, (rle_value)         ;; [3] Reload pixel value into A

rle_w1:
    ld   (de), a                ;; [2] Write pixel byte to VRAM
    inc  de                     ;; [2] Advance destination VRAM pointer
    djnz rle_w1                 ;; [2/3] Fast write loop (B bytes)

    inc  hl                     ;; [2] Advance source pointer past value byte (dd)
    jp   unRLEWBRAM             ;; [3] Block finished, return to main decoder loop

;; ==============================================================================
;; 6. RAW BYTES AND LITERAL 0x80 HANDLING
;; ==============================================================================
write_DC2RAM:
    ld   a, #RLEWB_CD           ;; [2] Load literal 0x80 value into A

write_Byte2RAM:
    ;; LDI copies (HL)->(DE), increments HL and DE, and decrements 16-bit counter BC.
    ;; The Parity/Overflow flag is set to PE (Parity Even / V=1) as long as BC != 0.
    ldi                         ;; [4] (DE)=(HL), DE++, HL++, BC-- (line byte counter)
    jp   pe, unRLEWBRAM         ;; [3] IF BC != 0 (scanline not finished) -> next token

;; ------------------------------------------------------------------------------
;; 7. CPC SCANLINE STEP (FOR RAW BYTES AT END OF SCANLINE)
;; ------------------------------------------------------------------------------
    ex   de, hl                 ;; [1] Swap: HL = VRAM pointer, DE = source pointer
    ld   b, #0x07               ;; [2] High byte for intra-character step (+0x0700)
    ld__c_ixl                   ;; [2] C = -width (IXL)
    add  hl, bc                 ;; [3] HL = start of next scanline (+0x0800 - width)

    ;; Test 8-line character block boundary
    ld   a, h                   ;; [1]
    and  #0x38                  ;; [2]
    jr   nz, rv_ok              ;; [2/3] IF inside 8-line block THEN skip correction

    ld   bc, #0xC050            ;; [3] Character row correction (+80 bytes)
    add  hl, bc                 ;; [3]

rv_ok:
    ex   de, hl                 ;; [1] Restore: DE = VRAM, HL = source
    ld__c_ixh                   ;; [2] Reset line width counter C = width (IXH)
    ld   b, #0                  ;; [2] B = 0 -> ensures BC = C for future LDI instructions
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

;; ==============================================================================
;; 8. DECOMPRESSION TERMINATION & EXIT
;; ==============================================================================
exit_drawSprite_RLE:
    pop  ix                     ;; [4] Restore SDCC frame pointer IX
    ret                         ;; [3] Return cleanly to C caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RAM WORKSPACE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.area _DATA
rle_value:
    .db  0                      ;; Current RLE byte value being repeated (dd)
rle_left:
    .db  0                      ;; Leftover run count to resume on next scanline