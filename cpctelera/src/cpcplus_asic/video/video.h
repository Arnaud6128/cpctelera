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

#ifndef CPCT_VIDEO_ASIC_H
#define CPCT_VIDEO_ASIC_H

#include <types.h>

//
// Title: Macros (C)
//
//    Useful Asic related macros designed to be used in your C programs
//

//
// Macro: cpctm_asicColor
//
//    Convert component colors RGB in 12-bits format (0x0GRB)
//
// C Definition:
//    #define <cpctm_asicColor> (*R*, *G*, *B*) 
//
// ASM Call:
//    For asm programs, please refer to <cpct_asicColor_asm>
//
// Parameters:
//    R, G, B - Red, Green and Blue components (only 4-bits LSB are used)
// 
// Known limitations:
//    * This macro will produce no-code when used with constant values. If any of
// the given values is a variable, it will procuce calculation code. This code
// will be translated by C-compiler into ASM, and may be slow.
//

#define cpctm_asicColor(R,G,B)   (u16)(((u16)((G) & 0x0F) << 8) | (u16)(((R) & 0x0F) << 4) | (u16)((B) & 0x0F)) // 0x0GRB

#define cpctm_asicGetRed(RGB)    (u8)(RGB >> 4)
#define cpctm_asicGetGreen(RGB)  (u8)(RGB >> 8)
#define cpctm_asicGetBlue(RGB)   (u8)(RGB & 0x0F)

// Asic palette
extern u16  cpct_asicColor(u8 red, u8 green, u8 blue) __z88dk_callee;
extern void cpct_asicSetBorder(u16 rgb) __z88dk_fastcall;
extern void cpct_asicSetPalColour(u16 colour_index, u16 rgb) __z88dk_callee;
extern void cpct_asicSetPalette(const u16* rgb_array, u16 size) __z88dk_callee;

// Sprite Hardware palette
extern void cpct_asicSetSpritePalColour(u16 colour_index, u16 rgb) __z88dk_callee;
extern void cpct_asicSetSpritePalette(const u16* rgb_array, u16 size) __z88dk_callee;

#endif