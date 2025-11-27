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

// Structure of rectangle
typedef struct TRect
{
	u8 x, y;
	u8 w, h;
}
SRect;

// Global defines
#define BOOL			u8
#define TRUE			1
#define FALSE			0

#define	SCREEN_W		80
#define	SCREEN_H		200

#define BACK_COLOR		cpct_px2byteM1(0, 0, 0, 0)
#define YELLOW_COLOR	cpct_px2byteM1(1, 1, 1, 1)
#define CYAN_COLOR		cpct_px2byteM1(2, 2, 2, 2)
#define RED_COLOR		cpct_px2byteM1(3, 3, 3, 3)

// Demo defines
#define SPEED_X			1
#define SPEED_Y			4

#define NB_BOX			10

#define BOX_MOVE_W		1
#define BOX_MOVE_H		4

#define BOX_W			4
#define BOX_H			16

// List of boxes on screen
SRect _collideBoxes[NB_BOX];

// Moving box
SRect _moveRect;

///////////////////////////////////////
// Init color and boxes positions
void Init(void)
{
	 cpct_disableFirmware();
	 cpct_setBorder(0x54);
	
	// Init moving box
	_moveRect.x = 0;
	_moveRect.y = 0;
	_moveRect.w = BOX_MOVE_W;	
	_moveRect.h = BOX_MOVE_H;	
	
	// Init static boxes
	SRect* collideBox = _collideBoxes;
	for (u8 i = 0; i < NB_BOX; i++)
	{
		// Randomize position with step of size of box
		u8 x = cpct_rand8() % (SCREEN_W / BOX_W);		
		collideBox->x = x * BOX_W;
		
		u8 y = cpct_rand8() % (SCREEN_H / BOX_H);		
		collideBox->y = y * BOX_H;
		
		// Size is fixed
		collideBox->w = BOX_W;
		collideBox->h = BOX_H;
		
		// Last box is in right bottom corner
		if (i == NB_BOX - 2)
		{
			collideBox->x = (u8)(SCREEN_W - BOX_W);
			collideBox->y = (u8)(SCREEN_H - BOX_H);
		}
		
		collideBox++;
	}
}

///////////////////////////////////////
// Draw box with specific color
void DrawBox(SRect* box, u8 color)
{
	u8* vmem = cpct_getScreenPtr((u8*)CPCT_VMEM_START, box->x, box->y);
	cpct_drawSolidBox(vmem, color, box->w, box->h);    
}

///////////////////////////////////////
// Draw all boxes
void DrawBoxes(void)
{
	// Player box
	DrawBox(&_moveRect, RED_COLOR);
	
	// Other boxes
	for (u8 i = 0; i < NB_BOX; i++)
	{
		// If last box then fill cyan else yellow 
		DrawBox(&_collideBoxes[i], (i != NB_BOX - 2) ? YELLOW_COLOR : CYAN_COLOR);
	}
}
///////////////////////////////////////
// Check collide with all boxes
BOOL IsCollideBoxes(void)
{
	for (u8 i = 0; i < NB_BOX; i++)
	{
		SRect* collideBox = &_collideBoxes[i];
		if (cpct_checkCollisionBoxes(
		    _moveRect.x, _moveRect.w, _moveRect.y, _moveRect.h,
		    collideBox->x, collideBox->w, collideBox->y, collideBox->h))
		{
			// If collide last box (bottom/right corner) then return to start
			if (i == NB_BOX - 2)
			{
				_moveRect.x = 0;
				_moveRect.y = 0;				
				
				// Special case no collide
				return FALSE;
			}
			
			// Collide
			return TRUE;
		}                          	
	}
	
	// No collide
	return FALSE;	
}

///////////////////////////////////////
// Main function
void main(void) 
{
	Init();
	DrawBoxes();

    // Loop forever
	while(TRUE)
	{
		// Check if key pressed
		cpct_scanKeyboard();
		if (cpct_isAnyKeyPressed())
		{
			// Clear previous position
			DrawBox(&_moveRect, BACK_COLOR);
			
			// Save current position
			u8 x = _moveRect.x;
			u8 y = _moveRect.y;
			
			// Check key direction and collision with screen borders
			if (cpct_isKeyPressed(Key_CursorUp) && _moveRect.y >= SPEED_Y)
			{
				_moveRect.y-=SPEED_Y;
			}
			else if (cpct_isKeyPressed(Key_CursorDown) && _moveRect.y <= SCREEN_H - SPEED_Y - 1)
			{
				_moveRect.y+=SPEED_Y;
			}
			
			if (cpct_isKeyPressed(Key_CursorLeft) && _moveRect.x >= SPEED_X)
			{
				_moveRect.x-=SPEED_X;
			}
			else if (cpct_isKeyPressed(Key_CursorRight) && _moveRect.x <= SCREEN_W - SPEED_X - 1)
			{
				_moveRect.x+=SPEED_X;
			}
			
			// Is collide restore position
			if (IsCollideBoxes())
			{
				_moveRect.x = x;
				_moveRect.y = y;				
			}				
			
			// Draw moving box
			DrawBox(&_moveRect, RED_COLOR);
						
			// Slow down
			cpct_waitVSYNC();
			cpct_waitVSYNC();			
		}	
	}
}
