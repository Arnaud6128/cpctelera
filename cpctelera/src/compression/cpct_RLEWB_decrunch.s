;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2022 mvac7 for original code for decrunch RLEWB (@mvac7)
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
.module cpct_compression

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_RLEWB_decrunch
;;
;;   Decompresses RLEWB-compressed data directly to RAM (linear memory array).
;;
;; C Definition:
;;   void cpct_RLEWB_decrunch(const u8* src, u8* dst) __z88dk_callee;
;;
;; Input Parameters (4 bytes):
;;   (2B HL) src   - Pointer to source (compressed data)
;;   (2B DE) dst   - Pointer to destination array
;;
;; Details:
;;   - Uses RLEWB format (Run-Length Encoding Wonder Boy).
;;   - Algorithm :
;;      CD = Control Digit = 0x80
;;      ED = End Data Block = 0xFF
;;
;;      CD + $0         --> for one 0x80 value
;;      CD + $FF        --> end of data block
;;      CD + nn + dd    --> repeat nn ($1-$FE) dd value
;;      dd (!= CD)      --> raw data    
;;
;; Destroyed Register values: 
;;   AF, BC, DE, HL
;
;; Required memory:
;;   33 bytes (33 bytes routine + 0 bytes binding wrapper)
;;
;; Time Measures:
;; (start code)
;;    Case / Decompression Operation            | microSecs (us) | CPU Cycles
;;   -------------------------------------------------------------------------
;;    Setup / Block Overhead                    | 21             | 84
;;    Raw Byte (Uncompressed byte)              | 16             | 64
;;    Literal 0x80 Byte                         | 25             | 100
;;    RLE Repeated Byte (inner loop speed)      | 7              | 28
;;   -------------------------------------------------------------------------
;;    Average Decompression Speed               | ~8 - 12 /byte  | ~32 - 48 /byte
;; (end code)
;;
;; Credits:
;;    * RLEWB encoder is inspired by Wonder Boy RLE <https://www.smspower.org/Development/Compression#WonderBoyRLE>
;;    * Original code by mvac7 <https://github.com/mvac7/Z80_RLEWB>
;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CD = Control Digit = 0x80
RLEWB_CD=#0x80
;;  ED = End Data Block = 0xFF
RLEWB_END=#0xFF

;; ASM and C bindings for <cpct_RLE_decrunch>
;;
;;  0 microSecs, 0 bytes
;;
_cpct_RLEWB_decrunch::
_cpct_RLEWB_decrunch_asm::

unRLEWBRAM:
    ld   a, (hl)                ;; [2] Read next byte from compressed stream
    cp   #RLEWB_CD              ;; [2] Compare with Control Digit (0x80)
    jr   nz, write_Byte2RAM     ;; [2/3] IF not 0x80 THEN write raw byte
  
    inc  hl                     ;; [2] Advance source pointer
    ld   a, (hl)                ;; [2] Read control byte parameter
    or   a                      ;; [1] Check if parameter == 0x00
    jr   z, write_DC2RAM        ;; [2/3] IF 0x00 THEN write literal 0x80 value
    cp   #RLEWB_END             ;; [2] Compare with End Marker (0xFF)
    ret  z                      ;; [1/3] IF 0xFF THEN return to caller
  
    ;; --- RLE BLOCK: Repeat value dd (nn times) ---
    ld   b, a                   ;; [1] B = repeat count (nn)
    inc  hl                     ;; [2] Advance to value byte
    ld   a, (hl)                ;; [2] A = value to repeat (dd)
  
RLEWBram_loop:
    ld   (de), a                ;; [2] Write repeated byte to destination RAM
    inc  de                     ;; [2] Advance destination pointer
    djnz RLEWBram_loop          ;; [3/4] Loop until all RLE bytes written (B == 0)
  
    inc  hl                     ;; [2] Advance compressed source pointer
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop

    ;; --- Output literal value equal to CD (0x80) ---
write_DC2RAM:
    ld   a, #RLEWB_CD           ;; [2] A = literal Control Digit (0x80)
  
write_Byte2RAM:
    ld   (de), a                ;; [2] Write raw byte to destination RAM
    inc  de                     ;; [2] Advance destination pointer
    inc  hl                     ;; [2] Advance source pointer
    jp   unRLEWBRAM             ;; [3] Continue main decompression loop