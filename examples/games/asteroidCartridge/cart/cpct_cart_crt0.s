;--------------------------------------------------------------------------
;  cpct_cart_crt0.s - crt0 for a cartridge of the CPC Plus / GX4000
;
;  Based on crt0.s of SDCC for the Z80 (sdcc/device/lib/z80):
;  Copyright (C) 2000, Michael Hope
;
;  This library is free software; you can redistribute it and/or modify it
;  under the terms of the GNU General Public License as published by the
;  Free Software Foundation, either version 2, or (at your option) any
;  later version.
;
;  This library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this library; see the file COPYING. If not, write to the
;  Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston,
;   MA 02110-1301, USA.
;
;  As a special exception, if you link this library with other files,
;  some of which are compiled with SDCC, to produce an executable,
;  this library does not by itself cause the resulting executable to
;  be covered by the GNU General Public License. This exception does
;  not however invalidate any other reasons why the executable file
;   might be covered by the GNU General Public License.
;--------------------------------------------------------------------------
;  Modifications for the cartridge: Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;--------------------------------------------------------------------------
;  The bank 0 of the cartridge is the lower ROM (0x0000-0x3FFF) at the reset. cpct_mkcart puts
;  there the first 256 bytes of the binary (this header: the reset and the boot) and, at PROG_ROM,
;  the program, linked at Z80CODELOC (RAM, at least PROG_ROM: checked by cfg/modules/cartridge.mk). The boot:
;    1. sets the CRTC (no firmware on a cartridge: standard 50 Hz screen at 0xC000)
;    2. copies the program from the ROM to the RAM and jumps to init, in the RAM. The bank 0 holds PROG_MAX
;       bytes of the program: if it is longer (the length is known at link time: s__ENDPROG - s__CODE) the
;       boot copies PROG_MAX bytes and keeps the rest (on the stack) for init
;  init, that is in the program, then:
;    3. unlocks the ASIC (the sequence of cpct_asicUnlock, that may be in the part not copied yet)
;    4. copies the rest of the program (if any) from the banks 1.. (CARTRIDGE PROGRAM_BANKS n in
;       cfg/cartridge.mk) through the UPPER ROM: the lower ROM would hide a program in 0x0100-0x3FFF
;    5. calls main. As in a classic CPCtelera project (no crt0), the global variables are NOT initialized:
;       there is no gsinit (the variables with an initial value must be set by the program)
;  The ROMs and the mode are then handled by the functions of CPCtelera (cpct_enableUpperROM, cpct_setVideoMode...),
;  and the banks are chosen with cpct_cartSetUpperRomBank / cpct_cartSetLowerRomBank.
;  This file is part of the project (cart/), not of the library: it is assembled and linked first (areas order)
;  by cfg/modules/cartridge.mk. cpct_mkproject --cartridge copies it from tools/scripts/templates/cartridge/cart/
;--------------------------------------------------------------------------

	.module cpct_cart_crt0
	.optsdcc -mz80 sdcccall(1)
	.globl	_main
	.globl	s__CODE
	.globl	s__ENDPROG

PROG_ROM = 0x0100               ;; the program in the bank 0 (same value as PROG_ROM of cpct_mkcart)
BANK_SIZE = 0x4000
PROG_MAX = BANK_SIZE - PROG_ROM ;; bytes of the program in the bank 0; the rest is in the banks 1.. (PROGRAM_BANKS)
CART_ROM_PORT = 0xDF00          ;; upper ROM select (value 128 + bank)
CRTC_SEL = 0xBC00               ;; CRTC register select (data: 0xBD00)

	.area	_HEADER (ABS)
	;; Reset vector
	.org 	0
	jp	boot

	;; In the ROM: the interrupts are served while the lower ROM is connected
	.org	0x08
	ei
	reti
	.org	0x10
	ei
	reti
	.org	0x18
	ei
	reti
	.org	0x20
	ei
	reti
	.org	0x28
	ei
	reti
	.org	0x30
	ei
	reti
	.org	0x38
	ei
	reti

	.org	0x40
boot:
	di
	im	1
	ld	sp, #0xC000             ;; stack in the RAM, below the screen

	ld	hl, #crtc_regs          ;; CRTC: registers R0-R13
	ld	e, #0
	ld	d, #14
crtc_loop:
	ld	b, #>CRTC_SEL
	out	(c), e
	inc	b
	ld	a, (hl)
	out	(c), a
	inc	hl
	inc	e
	dec	d
	jr	nz, crtc_loop

	ld	hl, #s__ENDPROG          ;; length of the program: from the start of the code to the end of
	ld	de, #s__CODE            ;; the last area (ENDPROG, one byte)
	or	a, a
	sbc	hl, de
	inc	hl
	ld	bc, #PROG_MAX           ;; the bank 0 holds PROG_MAX bytes of the program at most
	or	a, a
	sbc	hl, bc                  ;; HL = bytes left for the banks 1.., or negative (all in the bank 0)
	jr	nc, long_prog
	add	hl, bc                  ;; the program fits in the bank 0: all of it is copied
	ld	b, h
	ld	c, l
	ld	hl, #0                  ;; nothing left
long_prog:
	push	hl                      ;; bytes left for init (it takes them off the stack)
	ld	hl, #PROG_ROM           ;; the program (or its first PROG_MAX bytes), from the ROM to the RAM
	ldir
	jp	init

;; Standard 50 Hz screen, 40 columns x 25 lines of characters, display at 0xC000
crtc_regs:
	.db	0x3F, 0x28, 0x2E, 0x8E, 0x26, 0x00, 0x19, 0x1E, 0x00, 0x07, 0x00, 0x00, 0x30, 0x00

	;; The boot must end before PROG_ROM, where cpct_mkcart puts the program (it checks it)

	;; Ordering of segments for the linker.
	.area	_HOME
	.area	_CODE
	.area	_INITIALIZER
	.area   _GSINIT
	.area   _GSFINAL
	.area   _ENDPROG

	.area	_DATA
	.area	_INITIALIZED
	.area	_BSEG
	.area   _BSS
	.area   _HEAP

	.area   _CODE
init:
	;; Mode 1, lower and upper ROM disabled: the value of cpct_mode_rom_status (src/firmware), that the
	;; functions cpct_enableXXXROM and cpct_setVideoMode use. The program runs in the RAM from here
	ld	bc, #0x7F8D
	out	(c), c

	;; Unlock the ASIC (same sequence as cpct_asicUnlock, that may be in the part of the program not copied yet)
	ld	hl, #asic_code
	ld	d, #17
	ld	bc, #0xBC00
unlock:
	ld	a, (hl)
	out	(c), a
	inc	hl
	dec	d
	jr	nz, unlock

	;; The program is longer than the bank 0: the rest is in the banks 1.. and is copied after the first part
	;; (HL = bytes left, pushed by the boot). It is read through the UPPER ROM (0xC000-0xFFFF): the code is
	;; at Z80CODELOC, possibly in 0x0100-0x3FFF, that the lower ROM would hide. The stack is below 0xC000
	pop	hl
	ld	de, #s__CODE + PROG_MAX  ;; where the bank 1 goes
	ld	a, #1                   ;; next bank
more_banks:
	push	af
	ld	a, h
	or	a, l
	jr	z, banks_done
	pop	af
	push	af
	or	a, #0x80                ;; port 0xDF00: 128 + bank selects the bank of the upper ROM
	ld	b, #>CART_ROM_PORT
	ld	c, a
	out	(c), c
	ld	bc, #0x7F85             ;; RMR: mode 1, lower ROM disabled, upper ROM enabled
	out	(c), c
	ld	bc, #BANK_SIZE
	push	hl
	or	a, a
	sbc	hl, bc                  ;; left - 16 KB
	jr	nc, whole_bank          ;; at least 16 KB left: BC = 16 KB, left = HL
	pop	hl                      ;; the end of the program: what is left
	ld	b, h
	ld	c, l
	ld	hl, #0
	jr	copy_bank
whole_bank:
	inc	sp                      ;; the old value of HL is not needed
	inc	sp
copy_bank:
	push	hl                      ;; bytes left after this bank
	ld	hl, #0xC000             ;; the bank, seen by the upper ROM
	ldir
	ld	bc, #0x7F8D             ;; RMR: both ROMs disabled again
	out	(c), c
	pop	hl
	pop	af
	inc	a
	jr	more_banks
banks_done:
	pop	af

	;; The interrupt vector of the RAM (0x0038, the lower ROM is disabled) must be a valid handler (EI : RET)
	;; as soon as the interrupts are enabled (cpct_disableFirmware / cpct_setInterruptHandler change it)
	ld	hl, #0xC9FB             ;; EI (0xFB) : RET (0xC9)
	ld	(0x0038), hl

	call	_main
	jp	_exit

asic_code:
	.db	255, 0, 255, 119, 179, 81, 168, 212, 98, 57, 156, 70, 43, 21, 138, 205, 238

_exit::
	di
1$:
	halt
	jr	1$

	;; End of the program (last area of the order above): one byte, its address is the end of the image
	.area   _ENDPROG
	.db	0
