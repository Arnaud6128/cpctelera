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

//#####################################################################
//### MODULE: Sprites
//### SUBMODULE: Zoom Sprite
//#####################################################################
//### This module contains specialized functions to Zoom sprite
//#####################################################################
//

#ifndef CPCT_ZOOM_SPRITE_H
#define CPCT_ZOOM_SPRITE_H

// Double sprite size Width and Height
extern void cpct_doubleSpriteM0(const u8* spr, u8* mem, u8 width, u8 height) __z88dk_callee;
extern void cpct_doubleSpriteM1(const u8* spr, u8* mem, u8 width, u8 height) __z88dk_callee;

extern void cpct_drawDoubleSpriteM1(const u8* spr, u8* vmem, u8 width, u8 height) __z88dk_callee;
extern void cpct_drawDoubleSpriteM0(const u8* spr, u8* vmem, u8 width, u8 height) __z88dk_callee;

#endif