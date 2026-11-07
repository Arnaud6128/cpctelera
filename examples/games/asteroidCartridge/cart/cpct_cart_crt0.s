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
;  the program, linked at Z80CODELOC (RAM). The boot:
;    1. sets the CRTC (no firmware on a cartridge: standard 50 Hz screen at 0xC000)
;    2. copies the program from the ROM to the RAM and jumps to init, in the RAM
;  init, that is in the program, then:
;    3. unlocks the ASIC with cpct_asicUnlock (12 bits palette, see cpct_asic functions)
;    4. calls main. As in a classic CPCtelera project (no crt0), the global variables are NOT initialized:
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
	.globl	_cpct_asicUnlock

PROG_ROM = 0x0100               ;; the program in the bank 0
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
	ld	b, h
	ld	c, l
	ld	hl, #PROG_ROM           ;; the program, from the ROM to the RAM
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

	;; The ASIC is unlocked by the function of the library (it is in the RAM now). The function enables the
	;; interrupts at its end: the interrupt vector of the RAM (0x0038, the lower ROM is disabled) must be
	;; a valid handler (EI : RET) before, and the interrupts are disabled again after it, for main()
	ld	hl, #0xC9FB             ;; EI (0xFB) : RET (0xC9)
	ld	(0x0038), hl
	call	_cpct_asicUnlock
	di

	call	_main
	jp	_exit

_exit::
	di
1$:
	halt
	jr	1$

	;; End of the program (last area of the order above): one byte, its address is the end of the image
	.area   _ENDPROG
	.db	0
