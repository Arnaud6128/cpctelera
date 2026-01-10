//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2025 Arnaud Bouche (@Arnaud6128) 
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
// Title: Asic video Macros (C)
//
//    Useful Asic video related macros designed to be used in your C programs
//

//
// Macro: cpctm_asicColor
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
// the given values is a variable, it will produce calculation code. This code
// will be translated by C-compiler into ASM, and may be slower.
//

#define cpctm_asicColor(R,G,B)   (u16)(((u16)((G) & 0x0F) << 8) | (u16)(((R) & 0x0F) << 4) | (u16)((B) & 0x0F)) // 0x0GRB

//
// Macro: cpctm_asicGet<RED/Green/Blue>
//    Extract color (R, G or B) component from 12-bits RGB format (0x0GRB)
//
// C Definition:
//    #define <cpctm_asicGetRed> (*RGB*) 
//    #define <cpctm_asicGetGreen> (*RGB*) 
//    #define <cpctm_asicGetBlue> (*RGB*) 
//
// Parameters:
//   RGB 12-bits format (0x0GRB)
// 
// Known limitations:
//    * This macro will produce no-code when used with constant values. If any of
// the given values is a variable, it will produce calculation code. This code
// will be translated by C-compiler into ASM, and may be slower.
//
#define cpctm_asicGetRed(RGB)    (u8)((u16)RGB >> 4)
#define cpctm_asicGetGreen(RGB)  (u8)((u16)RGB >> 8)
#define cpctm_asicGetBlue(RGB)   (u8)((u16)RGB & (u16)0x0F)

// Asic palette adress
#define ASIC_PALETTE_SIZE         16

// Constant: ASIC_PALETTE_LOC
//    <u16*> pointer to ASIC Palette
#define ASIC_PALETTE_LOC         (u16*)0x6400

// Constant: ASIC_BORDER_LOC
//    <u16*> pointer to ASIC Border color
#define ASIC_BORDER_LOC          (u16*)0x6420

// Constant: ASIC_SPRITE_PALETTE_LOC
//    <u16*> pointer to ASIC Sprite Hardware palette
#define ASIC_SPRITE_PALETTE_LOC  (u16*)0x6422

// Constant: ASIC_SSCR_ADRESS
//    <u8*> pointer to ASIC SSCR
#define ASIC_SSCR_ADRESS           (u8*)0x6804

//
// Macro: cpctm_asicSSCRHoriz
//    Apply horizontal offset to SSCR
//
// C Definition:
//    #define <cpctm_asicSSCRHoriz> (SSCR_VALUE, HORIZONTAL_VALUE) 
// 
#define cpctm_asicSSCRHoriz(S,V)    (u8)((u8)((S) & (u8)0b11110000) | ((u8)V))

//
// Macro: cpctm_asicSSCRVert
//    Apply vertical offset to SSCR
//
// C Definition:
//    #define <cpctm_asicSSCRVert> (SSCR_VALUE, VERTICAL_VALUE) 
// 
#define cpctm_asicSSCRVert(S,V)     (u8)((u8)((S) & (u8)0b10001111) | ((u8)(V << 4)))

//
// Macro: cpctm_asicSSCRBorder
//    Hide or show border during scrolling
//
// C Definition:
//    #define <cpctm_asicSSCRBorder> (SSCR_VALUE, HIDE_BORDER) 
// 
#define cpctm_asicSSCRBorder(S,V)   (u8)((u8)((S) & (u8)0b01111111) | ((u8)V))

// Constant: ASIC_SCROLL_MODE0
//    Pixel offset for pixel scroll horizontal in mode0
#define ASIC_SCROLL_MODE0           (u8)4

// Constant: ASIC_SCROLL_MODE1
//    Pixel offset for pixel scroll horizontal in mode1
#define ASIC_SCROLL_MODE1           (u8)2

// Constant: ASIC_SCROLL_MODE2
//    Pixel offset for pixel scroll horizontal in mode2
#define ASIC_SCROLL_MODE2           (u8)1

// Constant: ASIC_SCROLL_HIDE_BORDER
//    Hide border during scrolling to use with macro cpctm_asicSSCRBorder
#define ASIC_SCROLL_HIDE_BORDER     (u8)0x80

// Constant: ASIC_SCROLL_RESET_BORDER
//    Reset border during scrolling to use with macro cpctm_asicSSCRBorder
#define ASIC_SCROLL_RESET_BORDER    (u8)0x00

// Asic palette
extern u16  cpct_asicColor(u8 red, u8 green, u8 blue) __z88dk_callee;
extern void cpct_asicSetBorder(u16 rgb) __z88dk_fastcall;
extern void cpct_asicSetPalColour(u16 colour_index, u16 rgb) __z88dk_callee;
extern void cpct_asicSetPalette(const u16* rgb_array, u16 size) __z88dk_callee;

// Sprite Hardware palette
extern void cpct_asicSetSpritePalColour(u16 colour_index, u16 rgb) __z88dk_callee;
extern void cpct_asicSetSpritePalette(const u16* rgb_array, u16 size) __z88dk_callee;

// Asic Soft Scroll Control Register
extern void cpct_asicSetScrollBorder(u8 hide_border) __z88dk_fastcall;
extern void cpct_asicSetScrollHoriz(u8 scroll_horiz) __z88dk_fastcall;
extern void cpct_asicSetScrollVert(u8 scroll_vert) __z88dk_fastcall;

#endif