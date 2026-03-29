//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
//  Copyright (C) 2026 Arnaud Bouche
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

//
// Title: EasyOverscan
//

#ifndef CPCT_EASYOVERSCAN_H
#define CPCT_EASYOVERSCAN_H

#include <types.h>

// EasyTilemaps defines
#define CPCT_OVERSCAN_VMEM_START    (u8*)0x8200
#define SCREEN_OVERSCAN_LOW_LIMIT_Y (u8)128
#define SCREEN_OVERSCAN_WIDTH       (u8)96
#define SCREEN_OVERSCAN_HEIGHT      (u16)(34*8) // 272

// EasyTilemaps managing functions
void cpct_configureOverscan(void);
void cpct_restoreCRTC(void);
u8* cpct_getScreenPtrOverscan(u8 x, u16 y) __z88dk_callee;

void cpct_drawSpriteMatOverscan(const u8* sprite, u8* videomem, u8 width, u8 height, const u8* pmasktable0) __z88dk_callee;
void cpct_drawSpriteOverscan(const u8* sprite, u8* videomem, u8 x, u8 y) __z88dk_callee;
void cpct_drawSolidBoxOverscan(u8* memory, u16 colour_pattern, u8 width, u8 height) __z88dk_callee;

// EasyTilemaps zoom functions
#include "./zoomSprite/zoomSprite.h"

#endif