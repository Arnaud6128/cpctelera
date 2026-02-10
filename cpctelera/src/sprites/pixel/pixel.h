//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
//  Copyright (C) 2026 Arnaud BOUCHE (@Arnaud6128)
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
//### MODULE: Sprites                                               ###
//### SUBMODULE: Pixel                                              ###
//#####################################################################
//### This module contains several functions and routines to manage ###
//### pixels in Amstrad CPC environment.                            ###
//#####################################################################
//

#ifndef CPCT_PIXEL_H
#define CPCT_PIXEL_H

// Functions to transform PEN colours into 4-pixel screen format values
#define cpct_pens2pixelPatternPairM1(OldPen, NewPen) cpct_pens2pixelPatternPairM1_real((NewPen), (OldPen))
extern  u16 cpct_pens2pixelPatternPairM1_real   (u8 NewPen, u8 OldPen)  __z88dk_callee;
extern   u8 cpct_pen2pixelPatternM1             (u16 pen)               __z88dk_fastcall;

// Functions to transform PEN colours into 2-pixel screen format values
#define cpct_pens2pixelPatternPairM0(OldPen, NewPen) cpct_pens2pixelPatternPairM0_real((NewPen), (OldPen))
extern  u16 cpct_pens2pixelPatternPairM0_real   (u8 NewPen, u8 OldPen)  __z88dk_callee;
extern   u8 cpct_pen2pixelPatternM0             (u16 pen)               __z88dk_fastcall;

// Functions to transform firmware colours for a group of pixels into a byte in screen pixel format
extern   u8 cpct_px2byteM0 (u8 px0, u8 px1) __z88dk_callee;
extern   u8 cpct_px2byteM1 (u8 px0, u8 px1, u8 px2, u8 px3) __sdcccall(0);

#endif
