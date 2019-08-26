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

#ifndef CPCT_SPRITE_ASIC_H
#define CPCT_SPRITE_ASIC_H

#include <types.h>

//
// Title: Macros (C)
//
//    Useful Asic related macros designed to be used in your C programs
//

//
// Macro: cpctm_getSpriteDataPtr
//
//    Get pointer to sprite hardware definition
//
// C Definition:
//    #define <cpctm_getSpriteDataPtr> (*SPR*) 
//
// ASM Call:
//    For asm programs, please refer to <cpct_asicSetSpriteData_asm>
//
// Parameters:
//   SPR   - Hardware sprite identifier (0..15)
// 
// Known limitations:
//    * This macro will produce no-code when used with constant values. If any of
// the given values is a variable, it will procuce calculation code. This code
// will be translated by C-compiler into ASM, and may be slow.
//
#define cpctm_getSpriteDataPtr(SPR)    (u8*)(0x4000 + SPR*0x100)

//
// Macro: cpctm_getSpriteCoordPtrX
//
//    Get pointer to sprite hardware position X
//
// C Definition:
//    #define <cpctm_getSpriteCoordPtrX> (*SPR*) 
//
// ASM Call:
//    For asm programs, please refer to <cpct_asicSetSpritePosition_asm>
//
// Parameters:
//   SPR   - Hardware sprite identifier (0..15)
// 
// Known limitations:
//    * This macro will produce no-code when used with constant values. If any of
// the given values is a variable, it will procuce calculation code. This code
// will be translated by C-compiler into ASM, and may be slow.
//
#define cpctm_getSpriteCoordPtrX(SPR) (i16*)(0x6000 + SPR*0x08)

//
// Macro: cpctm_getSpriteCoordPtrY
//
//    Get pointer to sprite hardware position Y
//
// C Definition:
//    #define <cpctm_getSpriteCoordPtrY> (*SPR*) 
//
// ASM Call:
//    For asm programs, please refer to <cpct_asicSetSpritePosition>
//
// Parameters:
//   SPR   - Hardware sprite identifier (0..15)
// 
// Known limitations:
//    * This macro will produce no-code when used with constant values. If any of
// the given values is a variable, it will procuce calculation code. This code
// will be translated by C-compiler into ASM, and may be slow.
//
#define cpctm_getSpriteCoordPtrY(SPR) (i16*)(0x6000 + SPR*0x08 + 2)

// ASIC internal screen resolution
#define ASIC_SCREEN_WIDTH              640 // Mode 2 resolution
#define ASIC_SCREEN_HEIGHT             200 

// ASIC Hardware Sprite coordinates limits
#define HW_SPRITE_MIN_X               -256
#define HW_SPRITE_MAX_X                767

#define HW_SPRITE_MIN_Y               -256
#define HW_SPRITE_MAX_Y                255

// ASIC Hardware Sprite number and dimension
#define HW_SPRITE_NUMBER               16
#define HW_SPRITE_WIDTH                16
#define HW_SPRITE_HEIGHT               16
#define HW_SPRITE_SIZE                 (HW_SPRITE_WIDTH*HW_SPRITE_HEIGHT)

// ASIC Hardware Sprite Zoom corresponding to CPC Mode
#define HW_SPRITE_MODE_0_ZOOM_X        3
#define HW_SPRITE_MODE_0_ZOOM_Y        1
#define HW_SPRITE_MODE_1_ZOOM_X        2
#define HW_SPRITE_MODE_1_ZOOM_Y        1
#define HW_SPRITE_MODE_2_ZOOM_X        1
#define HW_SPRITE_MODE_2_ZOOM_Y        1

// Sprite Hardware definition
extern void cpct_asicSetSpriteData(u8 hardware_sprite_id, u8 value) __z88dk_callee;
extern void cpct_asicCopySpriteData(u16 hardware_sprite_id, const u8* sprite_array) __z88dk_callee;
extern void cpct_asicDrawToSpriteData(u8 hardware_sprite_id, u8 pos_x, u8 pos_y, const u8* sprite_array, u8 width, u8 height) __z88dk_callee;

// Sprite Hardware move and zoom
extern void cpct_asicSetSpritePosition(u16 hardware_sprite_id, i16 position_x, i16 position_y) __z88dk_callee;
extern void cpct_asicSetSpriteZoom(u16 hardware_sprite_id, u8 zoom_x, u8 zoom_y) __z88dk_callee;

#endif