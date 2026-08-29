//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
//  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
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
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.ma
//------------------------------------------------------------------------------

#include <cpctelera.h>
#include "g_palette.h"

// Sprite raw
#include "winner.h"

// Sprite RLEWB compressed
#include "winner_rlewb.h"

// Constants
#define ONE_SEC_INTERRUPT   300
#define VIDEO_W_BYTES        80

// Global variables
u16 gTick;

// Interrupt Handler every 1/300s
void interruptHandler(void) 
{
    gTick++;
}

// Bench and test to see how many draw can be done in 1s
void main(void)
{
    // Set interrupt to count time
    cpct_setInterruptHandler(interruptHandler);
    
    // Set nice colors
    cpct_setPalette(g_palette, sizeof(g_palette));

    // Compress sprite to 0x2000 
    cpct_rlewb_compress(winner, (u8*)0x2000, WINNER_W*WINNER_H);
       
    // Show draw speed functions in 1s
    gTick = 0;
    
    // Move sprite on y 
    u8 y = 0;
    while(gTick <= ONE_SEC_INTERRUPT)        
    {
        // Get pointer of origin of screen
        u8* pvmem = cpct_getScreenPtr(CPCT_VMEM_START, 0, y++);
        
        // Draw sprite
        cpct_drawSprite(winner, pvmem, WINNER_W, WINNER_H);
    }

    gTick = 0;
    y = 0;
    while(gTick <= ONE_SEC_INTERRUPT)
    {
        // Get pointer of origin of screen
        u8* pvmem = cpct_getScreenPtr(CPCT_VMEM_START, (VIDEO_W_BYTES - WINNER_W) / 2, y++);
        
        // Draw RLEWB sprite without intermediate decompression
        cpct_rlewb_drawSprite(winner_rlewb, pvmem, WINNER_W);
    }    
    
    gTick = 0;
    y = 0;
    while(gTick <= ONE_SEC_INTERRUPT)
    {
        // Get pointer of origin of screen
        u8* pvmem = cpct_getScreenPtr(CPCT_VMEM_START, VIDEO_W_BYTES - WINNER_W, y++);
        
        // Decompress sprite RLEWB to 0x8000 
        cpct_rlewb_decrunch(winner_rlewb, (u8*)0x8000);
        
        // Draw sprite previoulsy decompressed at 0x8000
        cpct_drawSprite((u8*)0x8000, pvmem, WINNER_W, WINNER_H);
    }
    
    
   // Loop forever
    while (1);
}
