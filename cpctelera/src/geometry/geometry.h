//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
// Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
//  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
//### MODULE: Geometry                                              ###
//#####################################################################
//### This module contains several functions and routines to manage ###
//### geometric primitives                                          ###
//#####################################################################
//

#ifndef CPCT_GEOMETRY_H
#define CPCT_GEOMETRY_H

// Mode 1
extern void cpct_geometryLineM1(u8* screen_start, u16 x0, u16 y0, u16 x1, u8 y1, u8 color) __z88dk_callee;
extern void cpct_geometryPlotM1(u8* screen_start, u16 x, u8 y, u8 color) __z88dk_callee;

#endif