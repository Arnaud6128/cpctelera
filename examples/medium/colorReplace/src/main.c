//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2021 Bouche Arnaud (@Arnaud6128)
//  Copyright (C) 2021 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
//------------------------------------------------------------------------------

#include "declarations.h"

/////////////////////////////////////////////////////////////////////////////////
// Mask Table Definition for Mode 0
//
cpctm_createTransparentMaskTable(gMaskTable, MASK_TABLE_LOC, M0, 0);

///////////////////////////////////////////////////////
/// INITIALIZATION
/// 
//    Initializes the CPC and all systems before starting the main loop
//
void Initialization()
{
    // We need to disable firmware in order to set the palette and
    // to be able to use a second screen between 0x8000 and 0xBFFF
    cpct_disableFirmware();
    cpct_setPalette(g_palette, 16);  // Set the palette
	cpct_setVideoMode(1);  
}

///////////////////////////////////////////////////////
/// INITIALIZATION TEST MODE 0
/// 
//    Initializes the the next test in mode 0
//
void InitializationMode0Test()
{
	cpct_setVideoMode(0); 
    cpct_setBorder(HW_SKY_BLUE);     // Set the border color with Hardware color    
    InitializeVideoMemoryBuffers();  // Initialize video buffers    
    InitializeDrawing();             // Initialize drawing elements
}

///////////////////////////////////////////////////////
/// SMALL TEST FOR MODE1
/// 
void TestMode1()
{          
    // Calculate and return screen pointer
    u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, 0, 0);
	
	// No color replace
	cpct_drawSprite(g_baloon_m1, vmem + G_BALOON_M1_W, G_BALOON_M1_W, G_BALOON_M1_H);
	
	// Replace color while drawing sprite Masked aligned
	u16 replacePatColor = cpct_pens2pixelPatternPairM1(2, 3);
	cpct_drawSpriteMaskedAlignedColorizeM1(g_baloon_m1, vmem + (G_BALOON_M1_W + 1)*2, G_BALOON_M1_W, G_BALOON_M1_H, gMaskTable, replacePatColor);

	// Replace color while drawing sprite masked
	replacePatColor = CPCTM_PENS2PIXELPATTERNPAIR_M1(2, 3);
	cpct_drawSpriteMaskedColorizeM1(g_baloon_m1_masked, vmem + (G_BALOON_M1_W + 1)*3, G_BALOON_M1_W, G_BALOON_M1_H, replacePatColor);

	// Replace color in sprite
	cpct_spriteColourizeM1(replacePatColor, G_BALOON_M1_W*G_BALOON_M1_H, g_baloon_m1);
	cpct_drawSprite(g_baloon_m1, vmem + (G_BALOON_M1_W + 1)*4, G_BALOON_M1_W, G_BALOON_M1_H);
	
	// Wait for any key
	while(!cpct_isAnyKeyPressed()){
		cpct_scanKeyboard();
	}
}           

///////////////////////////////////////////////////////
/// MAIN PROGRAM
/// 
void main(void) 
{
    // Change stack location before any call. We will be using
    // memory from 0x8000 to 0xBFFF as secondary buffer, so
    // the stack must not be there or it will get overwritten
    cpct_setStackLocation((u8*)NEW_STACK_LOC);
    
	// Initialize everything
    Initialization();
	
	// Small test for mode1
	TestMode1();
	
	// Initialize next test in mode 0
	InitializationMode0Test();
	   
    // Main Loop
    while (TRUE)
    {
        UpdateBaloons();
        DrawSceneBaloons();
		DrawStars();
        
        // Flip buffers to display the present back buffer
        // and stop displaying the current video memory
        FlipBuffers();        
    }
}
