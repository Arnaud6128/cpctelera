;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud)
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
.module cpct_asic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_asicCopySpriteEntrelacedData
;;
;;   Copies a 16x16 hardware sprite (256 bytes) from an interlaced source buffer
;;   to ASIC sprite memory, selecting frame 0 (low nibble) or frame 1 (high nibble)
;;
;; C Definition:
;;    void cpct_asicCopySpriteEntrelacedData(<u8> hardware_sprite_id, <u8> frame, const <u8>* src) __z88dk_callee;
;;
;; Assembly call:
;;   > call cpct_asicCopySpriteEntrelacedData_asm
;;
;; Input Parameters (4 Bytes):
;;   (1B A ) hardware_sprite_id - Hardware sprite identifier (0..15)
;;   (1B L ) frame              - Frame to load: 0 = low nibble, 1 = high nibble
;;   (2B DE) src                - Source buffer 256 bytes, interlaced
;;
;; Parameter Restrictions:
;;   * *hardware_sprite_id* hardware sprite identifier from 0 to 15
;;   * *frame* must be exactly 0 or 1. Any other value is not valid (the code only tests for 1, so
;; the frame 0 is loaded): beware of variables that are not initialized, or that hold a bool as 0x54/0x55
;;
;; Requirements and limitations:
;;
;;  * The functions *cpct_asicUnlock* and *cpct_asicPageConnect* must be called before using this function.
;;  * The Asic registers are paged from 0x4000 to 0x7FFF *beware* the code located in this area will be hidden.
;;  * Asic page can be disconnected with *cpct_asicPageDisconnect* function to recover code at 0x4000 to 0x7FFF.
;;  * Do not place *src* inside 0x4000..0x7FFF while the ASIC page is connected.
;;
;; Details:
;;   The CPC+ ASIC only renders the lower nibble (bits 0..3) of each byte in sprite
;;   memory. This function always writes bytes whose upper nibble (bits 4..7) is 0:
;;   frame 0 keeps the low nibble of each source byte (masked with 0x0F), frame 1
;;   moves the high nibble of each source byte down to the low nibble (rotation by
;;   4 bits followed by a 0x0F mask).
;;
;; Destroyed Register values:
;;    AF, BC, DE, HL
;;
;; Required memory:
;;     C-bindings - 35 bytes
;;   ASM-bindings - 32 bytes
;;
;; Time Measures:
;; (start code)
;; Case       | microSecs(us) | CPU Cycles
;; ----------------------------------------
;; Frame 0    |  2830 (C:2840) | 11320 (C:11360)
;; Frame 1    |  3855 (C:3865) | 15420 (C:15460)
;; ----------------------------------------
;; C binding  | +10            | +40
;; ----------------------------------------
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; Save frame and calculate destination: HL = 0x4000 + (hardware_sprite_id * 256)
    ld   c, l          ;; [1] C = frame (saved before L is overwritten)
    ld   b, #0x0F      ;; [2] B = nibble mask (1 NOP cheaper than "and #0x0F" in the loops)
    and  b             ;; [1] Mask ID to ensure it is in range 0..15
    add  a, #0x40      ;; [2] A = 0x40 + id -> High byte of sprite address
    ld   h, a          ;; [1] H = 0x40..0x4F
    ld   l, #0x00      ;; [2] L = 0x00 -> HL points to sprite origin (0x4X00)

    ;; 2. Select frame
    dec  c             ;; [1] Frame 1 -> Z set. Frame 0 -> Z clear (C = 0xFF)
    jr   z, load_frame_1 ;; [3/2] Frame 1 branch (3 taken, 2 fall-through)

    ;; Frame 0: keep low nibble, mask upper nibble
copy_loop_0:
    ld   a, (de)       ;; [2] Read interlaced byte: A = [Frame1 : Frame0]
    and  b             ;; [1] A = [0000 : Frame0]
    ld   (hl), a       ;; [2] Write to ASIC RAM
    inc  de            ;; [2] Next source byte
    inc  l             ;; [1] Next destination byte (HL is 256-aligned, so L only)
    jr   nz, copy_loop_0 ;; [3/2] Loop 256 times until L overflows to 0
    ret                ;; [3] Return to caller
    
	;; Frame 1: move high nibble to low nibble, mask upper nibble
load_frame_1:
copy_loop_1:
    ld   a, (de)       ;; [2] Read interlaced byte: A = [Frame1 : Frame0]
    rrca               ;; [1] Rotate right 4 times to bring the high nibble down
    rrca               ;; [1] |
    rrca               ;; [1] |
    rrca               ;; [1] A = [Frame0 : Frame1]
    and  b             ;; [1] A = [0000 : Frame1]
    ld   (hl), a       ;; [2] Write to ASIC RAM
    inc  de            ;; [2] Next source byte
    inc  l             ;; [1] Next destination byte
    jr   nz, copy_loop_1 ;; [3/2] Loop 256 times until L overflows to 0
    ret                ;; [3] Return to caller
