//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
//  Use of Claude.ai - Opus 5.5
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//-------------------------------------------------------------------------------

#ifndef CPCT_CARTRIDGE_ASIC_H
#define CPCT_CARTRIDGE_ASIC_H

#include <types.h>

////////////////////////////////////////////////////////////////////////
// Group: Banks of the cartridge (CPC Plus / GX4000)
////////////////////////////////////////////////////////////////////////
//    A cartridge has up to 32 banks of 16 KB. The upper ROM (0xC000-0xFFFF) sees any of them, the
// lower ROM (0x0000-0x3FFF) the first 8. These functions only choose the bank: the ROMs are enabled
// and disabled with cpct_enableUpperROM, cpct_disableUpperROM, cpct_enableLowerROM and
// cpct_disableLowerROM (firmware/firmware.h), and the mode with cpct_setVideoMode.
//
//    With a ROM enabled, the same addresses are two different memories: the CPU READS the bank (ROM) and
// WRITES the RAM under it. That makes it possible to copy a bank of 16 KB on itself to the screen, with the
// upper ROM:
// (start code)
//    cpct_cartSetUpperRomBank(bank);
//    cpct_enableUpperROM();                              // reading 0xC000-0xFFFF gives the bank
//    cpct_memcpy((void*)0xC000, (void*)0xC000, 0x4000);  // reads the ROM, writes the RAM (the screen)
//    cpct_disableUpperROM();
// (end code)
//    Without the ROM enabled that call copies the RAM on itself and does nothing. The code that reads a ROM
// must not be in the addresses of that ROM (see each function).
//
// Constants:
//    CPCT_CART_BANK_SIZE - Size of a bank (16 KB)
//    CPCT_CART_NB_BANKS  - Banks of a cartridge (32)
//
#define CPCT_CART_BANK_SIZE  0x4000
#define CPCT_CART_NB_BANKS   32

extern void cpct_cartSetUpperRomBank(u8 bank);
extern void cpct_cartSetLowerRomBank(u8 bank);     // disables the interrupts: enable them again after cpct_disableLowerROM

#endif