;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_RLEWB_compress
;;
;;   Compresses uncompressed input data into RLEWB stream format.
;;
;; C Definition:
;;   u16 cpct_RLEWB_compress(const u8* src, u8* dst, u16 length) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B HL) src    - Pointer to uncompressed source data
;;   (2B DE) dst    - Pointer to destination buffer for compressed stream
;;   (2B BC) length - Length of input data to compress (in bytes)
;;
;; Return Value:
;;   (2B HL) Compressed length in bytes (dst_final - dst_initial)
;;
;; Assembly call:
;;     > call cpct_RLEWB_compress_asm
;;
;; Encoding Rules:
;;   - Unrepeated bytes < 0x80 are stored raw (1 byte output).
;;   - Repeated bytes or isolated bytes >= 0x80 are stored as a 2-byte sequence:
;;       [0x80 | Count] [Value]  (Max count per block = 127).
;;
;; Destroyed Register values: 
;;   AF, BC, DE, HL, IX
;;
;; Required memory:
;;   80 bytes (77 bytes routine + 3 bytes binding wrapper)
;;
;; Time Measures (Includes +10 us / +40 CPU cycles binding wrapper overhead):
;; (start code)
;;    Case / Compression Operation              | microSecs (us) | CPU Cycles
;;   -------------------------------------------------------------------------
;;    Setup Overhead (routine + C binding)      | ~25            | ~100
;;    Exit Overhead (HL = length, pop IX)       | ~20            | ~80
;;    Raw Byte (Uncompressed < 0x80)            | ~29            | ~116
;;    RLE Inner Count Loop (per repeated byte)  | ~18            | ~72
;;   -------------------------------------------------------------------------
;;    Average Compression Speed                 | ~18 - 30 /byte | ~72 - 120 /byte
;; (end code)
;;
;; Credits:
;;    * RLEWB encoder is inspired by Wonder Boy RLE <https://www.smspower.org/Development/Compression#WonderBoyRLE>
;;    * Original code by mvac7 <https://github.com/mvac7/Z80_RLEWB>
;;    * Optimization support <https://www.cpcwiki.eu/forum/programming/draw-spriterle-optimization/>
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.macro ld__a_ixl
   .dw #0x7DDD                  ;; [2] Opcode for ld a, ixl
.endm

.macro ld__ixl_a
   .dw #0x6FDD                  ;; [2] Opcode for ld ixl, a
.endm

    push ix                     ;; [4] Preserve IX register
	
    ld   a, e                   ;; [1] A = initial dst low byte (E)
    push af                     ;; [3] Save initial E on stack
    ld   a, d                   ;; [1] A = initial dst high byte (D)
    push af                     ;; [3] Save initial D on stack

    ld   b, c                   ;; [1] B = remaining length counter
    ld   c, #0                  ;; [2] C = local repetition counter

main_loop$:
    ld   a, b                   ;; [1] A = remaining bytes count
    or   a                      ;; [1] Check if remaining bytes == 0
    jr   z, end_encode          ;; [2/3] IF remaining bytes == 0 THEN finish compression

    ld   a, (hl)                ;; [2] A = current byte value
    ld   c, #1                  ;; [2] Initialize repetition count to 1

count_loop$:
    dec  b                      ;; [1] Decrement remaining bytes counter
    jr   z, write_block$        ;; [2/3] IF no more input bytes THEN force block write

    inc  hl                     ;; [2] Advance source pointer
    cp   a, (hl)                ;; [2] Compare current byte with next byte
    jr   nz, mismatch$          ;; [2/3] IF values differ THEN break RLE sequence

    inc  c                      ;; [1] Increment repetition counter
    ld   a, c                   ;; [1] A = current count
    cp   #127                   ;; [2] Check max RLE limit (127)
    ld   a, (hl)                ;; [2] Restore current value into A
    jr   nz, count_loop$        ;; [2/3] IF count < 127 THEN continue counting
    jr   write_block$           ;; [3] IF count == 127 THEN force block write

mismatch$:
    inc  b                      ;; [1] Revert B decrement (unconsume mismatched byte)
    jr   write_decision$        ;; [3] Jump to format decision logic

write_block$:
    inc  hl                     ;; [2] Advance source pointer past completed run

write_decision$:
    ld__ixl_a                   ;; [2] Store current byte value into IXL
    ld   a, c                   ;; [1] A = repetition count
    cp   #1                     ;; [2] Compare count with 1
    jr   nz, write_rle$         ;; [2/3] IF count > 1 THEN write RLE sequence

    ld__a_ixl                   ;; [2] Retrieve byte value from IXL
    bit  7, a                   ;; [2] Test if bit 7 is set (val >= 0x80)
    jr   nz, write_rle$         ;; [2/3] IF val >= 0x80 THEN write RLE sequence

    ld   (de), a                ;; [2] Write raw byte directly to destination
    inc  de                     ;; [2] Advance destination pointer
    jr   main_loop$             ;; [3] Loop for next sequence

write_rle$:
    ld   a, c                   ;; [1] A = repetition count
    set  7, a                   ;; [2] Set bit 7 to mark RLE control byte
    ld   (de), a                ;; [2] Write RLE header byte [0x80 | count]
    inc  de                     ;; [2] Advance destination pointer
    ld__a_ixl                   ;; [2] Retrieve raw byte value
    ld   (de), a                ;; [2] Write repeated byte value
    inc  de                     ;; [2] Advance destination pointer
    jr   main_loop$             ;; [3] Loop for next sequence

end_encode:
    pop  bc                     ;; [3] Restore B = initial D
    pop  af                     ;; [3] Restore C = initial E
    ld   c, a                   ;; [1] C = initial E

    ld   a, e                   ;; [1] A = final E
    sub  c                      ;; [1] A = final E - initial E
    ld   l, a                   ;; [1] L = low byte of compressed size
    ld   a, d                   ;; [1] A = final D
    sbc  a, b                   ;; [1] A = final D - initial D - borrow
    ld   h, a                   ;; [1] HL = total compressed size in bytes

    pop  ix                     ;; [4] Restore IX register
    ret                         ;; [3] Return to caller (HL = compressed length)
