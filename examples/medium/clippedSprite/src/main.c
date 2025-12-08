//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

/** Sprites includes */
#include "car_asphalt.h"
#include "car_roadblaster.h"
#include "camion.h"
#include "hud_right.h"
#include "level.h"

// Mask table location
#define MASK_TABLE_LOC		0x100

#define COLOR_ROAD			1
#define COLOR_BLUE			9

#define SCREEN_WIDTH		80
#define NB_CARS				3
#define SMALL_HUD_W			8
#define LARGE_HUD_W			10

// Declare mask table
cpctm_createTransparentMaskTable(gMaskTable, MASK_TABLE_LOC, M0, 0);

// Define structure for drawing car
typedef struct TCar
{
	i8 x;       // Position can be negative outside screen
	u8 y;       // Position Y always positive
	u8 w, h;    // Width and Height
	u8* sprite; // Sprite data
	
	u8 speed;   // Speed move
	u8 type;
}
SCar;

// List of cars to draw
const SCar gCars[NB_CARS] = 
{ 
	{ -G_CAR_ROADBLASTER_W - 5, 50, G_CAR_ROADBLASTER_W, G_CAR_ROADBLASTER_H, g_car_roadblaster, 1, 0},
	{ -G_CAR_ASPHALT_W - 4, 100 - G_CAR_ASPHALT_H / 2, G_CAR_ASPHALT_W, G_CAR_ASPHALT_H, g_car_asphalt, 1,0  },
	{ -G_CAMION_W - 2, 180 - G_CAMION_H, G_CAMION_W, G_CAMION_H, g_camion, 1,0 }
};

// Member variables
u8 _level;

/*****************************************************/
/*													 */
/*	Initialization									 */
/*												     */
/*****************************************************/
void Init(void)
{
	cpct_disableFirmware();
	cpct_setVideoMode(0);
	
	// Set colors
	cpct_setBorder(0x54); // Black
	cpct_setPalette(g_palette, sizeof(g_palette));
	
	// Fill background with road color
	cpct_memset((u8*)CPCT_VMEM_START, cpct_px2byteM0(COLOR_ROAD, COLOR_ROAD), 0x4000);
	
	// Init level
	_level = 1;
}

/*****************************************************/
/*													 */
/*	Draw car    									 */
/*												     */
/*****************************************************/
void DrawCar(SCar* car)
{
	// Set to local variable to more visibility
	const u8 w = car->w;
	const u8 h = car->h;
	const u8 y = car->y;
	const u8* sprite= car->sprite;
	
	if (car->x + w > 0 && car->x < SCREEN_WIDTH)
	{
		// Car enter from left
		// Clipped left -> Draw right part of Sprite			
		if (car->x < 0)
		{				
			u8 widthToDraw = car->x + w;
			
			u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, 0, y);
			cpct_drawSpriteClipped(widthToDraw, vmem, w, h, sprite + w - widthToDraw);							
		}
		// Car exit from right
		// Clipped right -> Draw left part of Sprite			
		else if (car->x + w >= SCREEN_WIDTH)
		{
			u8 widthToDraw = SCREEN_WIDTH - car->x;
			
			u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, car->x, y);
			cpct_drawSpriteClipped(widthToDraw, vmem, w, h, sprite);								
		}
		// Full sprite to draw
		else
		{
			u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, car->x, y);
			cpct_drawSprite(sprite, vmem, w, h);
		}					
	}
	// Car exit totally from right
	else if (car->x >= SCREEN_WIDTH)
	{
		// Set car at new start random position
		car->x = -w - (cpct_rand() % 8);
	}
	
	car->x += car->speed;
}

/*****************************************************/
/*													 */
/*	Draw HUD        								 */
/*												     */
/*****************************************************/
void DrawHUD(void)
{	
	// Draw first HUD at left part of sprite
	u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, 0, 0);
	cpct_drawSpriteClippedMasked(LARGE_HUD_W, vmem, G_HUD_RIGHT_W, G_HUD_RIGHT_H, g_hud_right);
	
		// Draw second HUD from right part of sprite
	vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, LARGE_HUD_W + 2, 0);
	
	// Apply offset of first sprites width multiply by two because it's a masked sprite (pixel = Color + Mask)
	cpct_drawSpriteClippedMasked(SMALL_HUD_W, vmem, G_HUD_RIGHT_W, G_HUD_RIGHT_H, g_hud_right + LARGE_HUD_W*2);
}

/*****************************************************/
/*													 */
/*	Update HUD        								 */
/*												     */
/*****************************************************/
void UpdateHUD(void)
{	
	// Draw levels indicator at left
	u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, 2, 4);
	
	// Clear background level
	cpct_drawSolidBox(vmem, cpct_px2byteM0(COLOR_BLUE, COLOR_BLUE), 5, G_LEVEL_H);
	
	// Level is divided by 15 to slow down change
	u8 level = _level / 15;
	
	// Sprites Level wisth to draw is from 0 to 4 + 1 - because sprite level is one byte width.
	cpct_drawSpriteClippedMaskedAlignedTable((_level % 5) + 1, vmem, G_LEVEL_W, G_LEVEL_H, g_level, gMaskTable);	

	// Draw levels indicator at right
	vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, LARGE_HUD_W + 4, 4);
	
	// Clear background level
	cpct_drawSolidBox(vmem, cpct_px2byteM0(COLOR_BLUE, COLOR_BLUE), 4, G_LEVEL_H);
	
	// Sprites Level width to draw is from 0 to 3 + 1 - because sprite level is one byte width.
	cpct_drawSpriteClippedMaskedAlignedTable((_level % 4) + 1, vmem, G_LEVEL_W, G_LEVEL_H, g_level, gMaskTable);
	
	// Increase level
	_level++;
}

/*****************************************************/
/*													 */
/*	Draw main routine								 */
/*												     */
/*****************************************************/
void main(void) 
{
	// Initialise demo
	Init();
	
	// Draw HUD once
	DrawHUD();
	
	while (1)
	{		
		// Draw and move all cars
		for (u8 i = 0; i < NB_CARS; i++) {
			DrawCar(&gCars[i]);
		}	
	
		// Update HUD values
		UpdateHUD();
	
		// Slow down to see clip effect
		cpct_waitVSYNC();		
	}
}
