//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2026 Arnaud BOUCHE (@Arnaud6128)
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
//------------------------------------------------------------------------------

#include <cpctelera.h>

// Disk infos
#define WOLF_DAT_SIZE 	16336
#define WOLF_DAT_TRACK  5
#define DATA_DAT_TRACK  2
#define DATA_DAT_SECT   0xC2

// Temporay buffer size of one sector 512-Bytes
u8 _temp[CPCT_DISK_SECTOR_SIZE];

///////////////////////////////
//   Read tracks function to load large data very quickly
void ReadTracks(u8 track, u16 size, u8* dest)
{
	// Load from first sector 0xC1 (to 0xC9)
    u8 sector = CPCT_DISK_SECTOR_START;

	// Read full tracks to destination
    while (size >= CPCT_DISK_TRACK_SIZE)
    {
		// CPCT_DISK_TRACK_SIZE = NB_OF_SECTORS x SECTOR_SIZE = 9 x 512 = 4608-Bytes
		// This function read by sector by sector of 512-Bytes
		// ! BEWARE ! If destination is not multiple of 512-Bytes you can overwrite next memory.
		// In this case use temporary buffer.
        cpct_sectorRead(dest, track, CPCT_DISK_SECTOR_START, CPCT_DISK_NB_OF_SECTORS, CPCT_DISK_FACE_A);
		
		// Decrease full size to read of TRACK_SIZE
        size -= CPCT_DISK_TRACK_SIZE;
		// Move destination pointer of TRACK_SIZE
        dest += CPCT_DISK_TRACK_SIZE;
		// Next track number
        track++;
    }

	// If remaining sectors to read
    if (size >= CPCT_DISK_SECTOR_SIZE)
    {
		// Compute number of sectors to read
        u8 nbSectors = size / CPCT_DISK_SECTOR_SIZE;

        cpct_sectorRead(dest, track, sector, nbSectors, CPCT_DISK_FACE_A);
		// Decrease full size to read of nbSectors * SECTOR_SIZE
        size -= CPCT_DISK_SECTOR_SIZE * nbSectors;
		// Move destination pointer of of nbSectors * SECTOR_SIZE
        dest += CPCT_DISK_SECTOR_SIZE * nbSectors;
		// Next Sectors number
        sector += nbSectors;
    }

	// If remaining bytes then
	// read to last sector to temporary buffer and copy to destination
    if (size != 0)
    {
        cpct_sectorRead(_temp, track, sector, 1, CPCT_DISK_FACE_A);
        cpct_memcpy(dest, _temp, size);
    }
}

///////////////////////////////
//   Generate and write random numbers and read back
void SaveDataToDisk(void)
{
	// Generate 300 random number
	#define RANDOM_NB	300
	const u8 randomData[RANDOM_NB];
	
	u8* randData = randomData;
	for (u16 i = 0; i < RANDOM_NB; i++)
		*randData++ = cpct_getRandom_mxor_u8();
	
	// Write random data to track 2 sector 2 (0xC2) into one sector
	cpct_sectorWrite(randomData, DATA_DAT_TRACK, DATA_DAT_SECT, 1, CPCT_DISK_FACE_A);
	
	// Read 512-Bytes data from disk
	cpct_sectorRead(_temp, DATA_DAT_TRACK, DATA_DAT_SECT, 1, CPCT_DISK_FACE_A);
	
	// Compare 300 values
	u8 valueEquals = 1;
	for (u16 i = 0; i < RANDOM_NB; i++)
	{
		// If value different set valueEquals to false
		if (randomData[i] != _temp[i])
		{
			valueEquals = 0;
			break;
		}		
	}
	
	// If value different set border BRIGHT_RED (but it should't !!) or BLACK if OK
	cpct_setBorder(valueEquals ? HW_BLACK : HW_BRIGHT_RED);			
}

void main(void) 
{
	cpct_disableFirmware();

	// Set colors for image
	cpct_setBorder(HW_BLUE);
	cpct_setPALColour(0, HW_BLACK + 0x40);
	cpct_setPALColour(1, HW_WHITE + 0x40);
	cpct_setPALColour(2, HW_BRIGHT_WHITE + 0x40);
	cpct_setPALColour(3, HW_BRIGHT_CYAN + 0x40);

	// Read screen to video memory from disk
	ReadTracks(WOLF_DAT_TRACK, WOLF_DAT_SIZE, CPCT_VMEM_START);
	
	// Save and read data on disk
	SaveDataToDisk();

	// Loop forever
	while (1);
}
