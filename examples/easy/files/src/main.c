//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2018 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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
#include <stdio.h>

// Table sector must be 256-Bytes
u8 _tableSector[256];

// Filename must be 11 characters uppercase
char const _fileName[12] = "WOLF    SCR";

// Load file directly to Video Memory
void main(void) 
{
	cpct_disableFirmware();
	
	// First start motor
	cpct_fdcOn();
	
	// Read files needed
	for (u8 i = 0; i < 10; i++)
	{
		cpct_memset((u8*)CPCT_VMEM_START, 0, 0x4000); 
		cpct_loadFile(_fileName, (u8*)CPCT_VMEM_START, _tableSector);		
	}
	
	// Stop motor
	cpct_fdcOff();
	
	// Do stuff
	
	// Restart motor
	cpct_fdcOn();
	
	// Read another files needed
	for (u8 i = 0; i < 10; i++)
	{
		cpct_memset((u8*)CPCT_VMEM_START, 0, 0x4000);
		cpct_loadFile(_fileName, (u8*)CPCT_VMEM_START, _tableSector);		
	}
	
	// Stop motor
	cpct_fdcOff();
	
	// Ending
	cpct_memset((u8*)CPCT_VMEM_START, 0, 0x4000);
	printf("Load successfully");
	while(1);
}
