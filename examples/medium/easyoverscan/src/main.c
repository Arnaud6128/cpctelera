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
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//------------------------------------------------------------------------------

#include <cpctelera.h>
#include "g_palette.h"
#include "winner.h"

// Sets the transparent mask table for color 0, mode 1
cpctm_createTransparentMaskTable(g_masktable, 0x0100, M1, 0);

u8 winnerCopy[WINNER_H*WINNER_W];

// Start program
void main(void) 
{
	cpct_disableFirmware();
	cpct_setPalette(g_palette, 4);
	
	// Stack location must be changed because overscan memory layout uses 
	// 0x8200 to 0xFFFF and stack is located by default at 0xBFFF and decreases
	cpct_setStackLocation((u8*)0x100);
	
	// Configure overscan :
	// - resolution 96-Bytes x 272-Lines
	// - start video memory at 0x8200
	// - use 32-KBytes video memory area
	cpct_configureOverscan();
	
	// Fill both area to see Lower and upper video memory to see limits
	cpct_memset((u8*)CPCT_OVERSCAN_VMEM_START, 0x00, 0x4000);
	cpct_memset((u8*)CPCT_VMEM_START, 0xFF, 0x4000);
	
	// Draw sprite in middle of 32-Kbytes screen at right
	u8* vmem = cpct_getScreenPtrOverscan(SCREEN_OVERSCAN_WIDTH - WINNER_W, SCREEN_OVERSCAN_LOW_LIMIT_Y - WINNER_H/2 );
	cpct_drawSpriteMatOverscan(winner, vmem, WINNER_W, WINNER_H, g_masktable);
	
	// Draw sprite with masked aligned table in middle of 32-Kbytes screen at left
	vmem = cpct_getScreenPtrOverscan(0, SCREEN_OVERSCAN_LOW_LIMIT_Y - WINNER_H/2);
		
	// Flip sprite
	cpct_hflipSpriteM1(WINNER_W, WINNER_H, winner);
	
	// Draw sprite with masked aligned table
	cpct_drawSpriteMatOverscan(winner, vmem, WINNER_W, WINNER_H, g_masktable);
	
	// Copy sprite on screen into buffer
	cpct_getOverscanScreenToSprite(vmem, winnerCopy, WINNER_W, WINNER_H);
	
	// Draw sprite from buffer at to/left
	vmem = cpct_getScreenPtrOverscan(0, 0);
	cpct_drawSpriteOverscan(winnerCopy, vmem, WINNER_W, WINNER_H);
		
	// Move sprite loop
	u16 y = 0;
	while (1)
	{
		// Draw box to clear trails
		vmem = cpct_getScreenPtrOverscan((SCREEN_OVERSCAN_WIDTH - WINNER_W*2) / 2, y);
		
		// Select background color according y position
		cpct_drawSolidBoxOverscan(vmem, (y >= SCREEN_OVERSCAN_LOW_LIMIT_Y) ? 0xFF : 0x00, WINNER_W*2, 2);
		
		// Move to bottom
		y += 2;
		vmem = cpct_getScreenPtrOverscan((SCREEN_OVERSCAN_WIDTH - WINNER_W*2) / 2, y);
		
		// Draw doubled sprite
		cpct_drawDoubleSpriteM1Overscan(winner, vmem, WINNER_W, WINNER_H);
		
		// Clear sprite background and restart to top
		if (y >= (SCREEN_OVERSCAN_HEIGHT - (u16)(WINNER_H*2)))
		{
			cpct_drawSolidBoxOverscan(vmem, 0xFF, WINNER_W*2, WINNER_H*2);
			y = 0;
		}
	}
}
