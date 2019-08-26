//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2019 Arnaud Bouche (@Arnaud)
//  Copyright (C) 2019 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

#ifndef CPCT_FIRMWARE_ASIC_H
#define CPCT_FIRMWARE_ASIC_H

#include <types.h>

// Asic unlock and connect/disconnect page
extern void cpct_asicUnlock();
extern void cpct_asicPageConnect();
extern void cpct_asicPageDisconnect();

// Setting a user defined lines interrupt handler routine
extern void cpct_asicSetLinesInterruptHandler(void(*intHandler)(u8 line) __z88dk_fastcall, u8* lines_interrupt, u16 nb_lines) __z88dk_callee;
extern u16 cpct_asicRemoveLinesInterruptHandler();

#endif