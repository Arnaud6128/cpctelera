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
;;   Draw RLEWB compressed sprite directly to CPC video memory.
;;
;; C Definition:
;;   void cpct_rlewb_drawSprite(const u8* src, u8* dst, u8 width) __z88dk_callee;
;;
;; Input Parameters:
;;   (2B HL) src   - Pointer to source (compressed data in RLEWB format)
;;   (2B DE) dst   - Pointer to destination video memory
;;   (1B  C) width - Sprite width in bytes
;;
;; Assembly call:
;;     > call cpct_rlewb_drawSprite_asm
;;
;; Format Details (Wonder Boy RLE):
;;   CD = Control Digit  = 0x80
;;   ED = End Data Block = 0xFF
;;
;;   - CD + 0x00      --> Literal 0x80 value
;;   - CD + 0xFF      --> End of data block
;;   - CD + nn + dd   --> Repeat value dd (nn + 1) times (nn = 0x01..0xFE)
;;   - dd (!= CD)     --> Uncompressed raw byte
;;
;; Destroyed Register values: 
;;   AF, BC, DE, HL, IX
;;
;; Required memory:
;;   104 bytes (101 bytes routine + 3 bytes binding wrapper)
;;
;; Time Measures (Includes +10 us / +40 CPU cycles binding wrapper overhead):
;; (start code)
;;    Case / Decompression Operation            | microSecs (us) | CPU Cycles
;;   -------------------------------------------------------------------------
;;    Setup Overhead (routine + C binding)      | ~21            | ~84
;;    Raw Byte (Uncompressed pixel byte)        | 16             | 64
;;    RLE Repeated Byte (inner loop speed)      | 11             | 44
;;    Scanline Step (Intra-block +0x0700)       | ~20            | ~80
;;    Scanline Step (Row change +0xC050)        | ~25            | ~100
;;   -------------------------------------------------------------------------
;;    Average Decompression Speed               | ~12 - 14 /byte | ~48 - 56 /byte
;; (end code)
;;
;; Credits:
;;    * RLEWB encoder is inspired from Wonder Boy RLE <https://www.smspower.org/Development/Compression#WonderBoyRLE>
;;    * Original code by mvac7 <https://github.com/mvac7/Z80_RLEWB>
;;    * Optimization support <https://www.cpcwiki.eu/forum/programming/draw-spriterle-optimization/>
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CD = Control Digit = 0x80
RLEWB_CD=#0x80
;; ED = End Data Block = 0xFF
RLEWB_END=#0xFF

.macro ld__ixl_a
   .dw #0x6FDD                  ;; Opcode for ld ixl, a
.endm

.macro ld__c_ixl
   .dw #0x4DDD                  ;; Opcode for ld c, ixl
.endm

.macro ld__ixh_c
   .dw #0x61DD                  ;; Opcode for ld ixh, c
.endm

.macro ld__c_ixh
   .dw #0x4CDD                  ;; Opcode for ld c, ixh
.endm

.macro ld__a_ixh
   .dw #0x7CDD                  ;; Opcode for ld a, ixh
.endm

    push ix                     ;; [5] Preserve IX register on stack

    ld   a, c                   ;; [1] A = sprite width (bytes per line)
    ld__ixh_c                   ;; [2] IXH = width (stored for scanline reset)
    neg                         ;; [2] A = -width
    ld__ixl_a                   ;; [2] IXL = -width (stored for next line offset)

unRLEWBRAM:
    ld   a, (hl)                ;; [2] Read next byte from compressed stream
    cp   #RLEWB_CD              ;; [2] Compare with Control Digit (0x80)
    jr   nz, write_Byte2RAM     ;; [2/3] IF not 0x80 THEN treat as raw uncompressed byte

    inc  hl                     ;; [2] Advance source pointer
    ld   a, (hl)                ;; [2] Read control byte parameter
    or   a                      ;; [1] Check if parameter == 0x00
    jr   z, write_DC2RAM        ;; [2/3] IF 0x00 THEN write literal 0x80 control byte
    cp   #RLEWB_END             ;; [2] Check if End Marker (0xFF)
    jr   z, exit_drawSprite_RLE ;; [2/3] IF 0xFF THEN terminate decompression

    ;; --- RLE BLOCK: Repeat value dd (B times) ---
    ld   b, a                   ;; [1] B = repeat count (nn)
    inc  hl                     ;; [2] Advance to value byte
    ld   a, (hl)                ;; [2] A = value byte to repeat (dd)

RLEWBram_loop:
    ld   (de), a                ;; [2] Write repeated byte to VRAM
    inc  de                     ;; [2] Advance VRAM pointer

    dec  c                      ;; [1] Decrement line width counter
    jr   z, next_line_loop      ;; [2/3] IF end of scanline THEN jump next_line_loop
    
    djnz RLEWBram_loop          ;; [3/4] Loop until all RLE bytes written (B == 0)
    inc  hl                     ;; [2] Advance compressed data pointer
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

next_line_loop:
    ld   a, b                   ;; [1] Preserve remaining B counter in A
    ex   de, hl                 ;; [1] Swap VRAM pointer to HL
    ld   b, #0x07               ;; [2] High byte for intra-block step (+0x0700)
    ld__c_ixl                   ;; [2] C = -width (IXL)
    add  hl, bc                 ;; [3] HL = start of current scanline + 0x0800
    ld   b, a                   ;; [1] Restore B counter from A
    ld   a, h                   ;; [1] Load high byte of VRAM address
    and  #0x38                  ;; [2] Check 8-line character block boundary
    ld   a, b                   ;; [1] Restore A = B
    jr   nz, restore_loop       ;; [2/3] IF inside 8-line block THEN skip correction
    ld   bc, #0xC050            ;; [3] Character row correction offset (+0xC050)
    add  hl, bc                 ;; [3] Move HL to next character row

restore_loop:
    ex   de, hl                 ;; [1] Swap VRAM pointer back to DE
    ld   b, a                   ;; [1] Restore B counter
    ld__c_ixh                   ;; [2] Reset line width counter C = width (IXH)
    
    ld   a, (hl)                ;; [2] Reload value byte to repeat (dd)
    djnz RLEWBram_loop          ;; [3/4] Resume RLE repeat loop
    
    inc  hl                     ;; [2] Advance compressed data pointer
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

write_DC2RAM:
    ld   a, #RLEWB_CD           ;; [2] Load literal Control Digit (0x80)

write_Byte2RAM:
    ldi                         ;; [5] Copy raw byte (DE)=(HL), inc DE/HL, dec BC (C=width)
    jp   po, next_video_byte    ;; [2/3] IF C reached 0 (BC parity odd) THEN jump next_video_byte
	
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

next_video_byte:    
    ex   de, hl                 ;; [1] Swap VRAM pointer to HL
    ld   b, #0x07               ;; [2] High byte for intra-block step (+0x0700)
    ld__c_ixl                   ;; [2] C = -width (IXL)
    add  hl, bc                 ;; [3] HL = start of current scanline + 0x0800
    ld   a, h                   ;; [1] Load high byte of VRAM address
    and  #0x38                  ;; [2] Check 8-line character block boundary
    ld   a, b                   ;; [1] Restore A = B
    jr   nz, restore_Byte2RAM   ;; [2/3] IF inside 8-line block THEN skip correction
    ld   bc, #0xC050            ;; [3] Character row correction offset (+0xC050)
    add  hl, bc                 ;; [3] Move HL to next character row

restore_Byte2RAM:
    ld__c_ixh                   ;; [2] Reset line width counter C = width (IXH)
    ex   de, hl                 ;; [1] Swap VRAM pointer back to DE

    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

exit_drawSprite_RLE:
    pop  ix                     ;; [4] Restore IX register
    ret                         ;; [3] Return to caller