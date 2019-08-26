//-----------------------------LICENSE NOTICE------------------------------------
//  This file is part of CPCtelera: An Amstrad CPC Game Engine
//  Copyright (C) 2019 Arnaud Bouche (@Arnaud6128)
//  Copyright (C) 2019 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

//------------------------------------------------------------------------------
// Game is located at 0x8000 because Asic page memory uses [0x4000..0x7FFF]
// thus no needs to connect and disconnect asic page when required
//------------------------------------------------------------------------------
// Hardware sprites generated with AkuSpriteEditor :
// https://www.chibiakumas.com/
// Asteroid Sprites adapted from :
// https://opengameart.org/content/shmup-ships
//------------------------------------------------------------------------------

#include <cpctelera.h>

// Add boolean type
#include "stdbool.h"

// Hardware sprites definitions
#include "sprites.h"
#include "explosions.h"
#include "moon.h"
#include "win.h"

// Software sprites definitions
#include "planet.h"
#include "stars.h"

#define STARS_AREA_HEIGHT		140

// Hardware Sprites in screen size according to sprite magnification Mode 1
#define SPRITE_WIDTH_SCREEN		(HW_SPRITE_WIDTH*HW_SPRITE_MODE_1_ZOOM_X)
#define SPRITE_HEIGHT_SCREEN	HW_SPRITE_HEIGHT

// Definition of Hardware Id of sprites
#define HW_SPRITE_SHIP_REAR		12
#define HW_SPRITE_SHIP_FRONT	13
#define HW_SPRITE_REACTOR		14
#define HW_SPRITE_MOON			15

// Define 4 colours of mode 1 in asic rgb
#define MODE_1_NB_COLORS		4

// cpctm_asicColor(R,G,B)
const u16 paletteTop[] =  
{ 
	cpctm_asicColor(0x0, 0x0, 0x0), 
	cpctm_asicColor(0x0, 0x0, 0x1), 
	cpctm_asicColor(0x0, 0x0, 0x2), 
	cpctm_asicColor(0xF, 0xF, 0x5)
};

const u16 paletteDown[] = 
{ 
	cpctm_asicColor(0x0, 0x0, 0x5), 
	cpctm_asicColor(0x0, 0x8, 0xF), 
	cpctm_asicColor(0x8, 0xF, 0xF), 
	cpctm_asicColor(0xF, 0xF, 0xF)
};

// Definition of position structure
typedef struct
{
	i16 x;		// Can be negative if left out of screen 
	u8 y;		// Always positive (stay in screen Y)
	u8 cx, cy;	// Game sprite size
} SPos;

// Definition of player ship
#define SHIP_OK					0
#define SHIP_DESTROYED			1
#define SHIP_EXPLOSIONS			4

#define START_SHIP_X			10
#define START_SHIP_Y			100
#define SHIP_SPEED_X			4
#define SHIP_SPEED_Y			1

#define SHIP_SPRITE_WIDTH		(3*SPRITE_WIDTH_SCREEN) // Ship uses 3 HWSprite width
#define SHIP_COLLISION_Y		4 // Center ship sprite for collision
#define SHIP_SPRITE_HEIGHT		7 // Ship sprite height do not fill whole HWSprite Height (16)

// Definition of ship structure
typedef struct
{
	SPos pos;
	u8 status;
} SShip;

SShip gShip;

////////////////////////////////////////////////////
// Definition of asteroids and Hardware Sprite number associated (0..15)
// Hardware number defines also the internal order of drawing
#define ASTEROID_NB				6
#define ASTEROID_WIDTH_LARGE	(SPRITE_WIDTH_SCREEN)
#define ASTEROID_HEIGHT_LARGE	(SPRITE_HEIGHT_SCREEN*2)

#define ASTEROID_LARGE			0
#define ASTEROID_MEDIUM			1
#define ASTEROID_SMALL			2

#define ASTEROID_SPEED_LARGE	6
#define ASTEROID_SPEED_MEDIUM	5
#define ASTEROID_SPEED_SMALL	4

#define ASTEROID_LIMIT_EXIT		-100
	
// Definition of asteroid structure
typedef struct
{
	SPos pos;
	u8 speed;
	u8 type;
	u8 hwSpriteId;
} SAsteroid;

const SAsteroid gAsteroids[ASTEROID_NB] = 
{
	{ {0, 0, ASTEROID_WIDTH_LARGE, ASTEROID_HEIGHT_LARGE}, ASTEROID_SPEED_LARGE,  ASTEROID_LARGE,   0 },
	{ {0, 0, ASTEROID_WIDTH_LARGE, ASTEROID_HEIGHT_LARGE}, ASTEROID_SPEED_LARGE,  ASTEROID_LARGE,   4 },
	{ {0, 0, SPRITE_WIDTH_SCREEN, SPRITE_HEIGHT_SCREEN},   ASTEROID_SPEED_MEDIUM, ASTEROID_MEDIUM,  8 },
	{ {0, 0, SPRITE_WIDTH_SCREEN, SPRITE_HEIGHT_SCREEN},   ASTEROID_SPEED_MEDIUM, ASTEROID_MEDIUM,  9 },
	{ {0, 0, SPRITE_WIDTH_SCREEN, SPRITE_HEIGHT_SCREEN},   ASTEROID_SPEED_SMALL,  ASTEROID_SMALL,   10 },
	{ {0, 0, SPRITE_WIDTH_SCREEN, SPRITE_HEIGHT_SCREEN},   ASTEROID_SPEED_SMALL,  ASTEROID_SMALL,   11 },	
};

////////////////////////////////////////////////////
// Distance counter before win game
#define DISTANCE_FOR_WIN	(ASIC_SCREEN_WIDTH*10)
#define SCROLL_SPEED		2
i16 gEscapeDistance;

// Pointer to Moon HWSprite coordinates
i16* gMoonPositionX;
i16* gMoonPositionY;

////////////////////////////////////////////////////
// Check if all asteroids are exited
bool gAllAsteroidsExit;

////////////////////////////////////////////////////
//	Compute gradient color according to line
//	
u16 GetGradientColor(u8 line)
{
	// Compute without float : val = val / 120 * 15 
	u16 val = line * 100 / 120 * 0x0F;
	u8 c = (u8)(val / 100);
	
	// Return color with Red and Green component
	if (line >= 60) 
		return cpct_asicColor(0x0D, 0x0F - c, 0);
	else
		return cpct_asicColor(0x0F - c, 0x0D, 0);
	
}

////////////////////////////////////////////////////
//	Interrupt function										 
//		
void InterruptFunction(u8 line) __z88dk_fastcall
{
	// Change palette of down part of screen
	if (line == (STARS_AREA_HEIGHT-2))
	{
		cpct_asicSetPalette(paletteDown, MODE_1_NB_COLORS);
	}
	else
	{				
		// Get pointer of palette to modify it
		u16* colour = paletteTop;
		
		// Star gradient color
		u16 col = GetGradientColor(line);
		
		// Scan keyboard every 200s
		if (line == ASIC_SCREEN_HEIGHT)	
		{
			cpct_scanKeyboard_if();	
			
			// Reset to space black
			*colour = cpctm_asicColor(0,0,0);	
		}
		else
		{
			// Keep only 3 LSB for darker blue to space gradient
			*colour = cpctm_asicColor(0,0,line>>5);	
		}
		
		// Add Blue component to colours (0x0GRB)
		colour[1] = col | cpctm_asicGetBlue(colour[1]);
		colour[2] = col | cpctm_asicGetBlue(colour[2]);	
		
		// Apply new palette with only the 3 first colours
		cpct_asicSetPalette(colour, MODE_1_NB_COLORS-1);
	}
}

////////////////////////////////////////////////////
//	Set interrupt handler										 
//		
void SetInterruptHandler()
{
	// Defines three lines of interruptions
	static const u8 lines[] = {1, 20, 60, 90, 120, STARS_AREA_HEIGHT-2, ASIC_SCREEN_HEIGHT};

	// Wait screen refresh is starting to top
	cpct_waitVSYNC();
	__asm
	halt
	halt
	__endasm;
	cpct_waitVSYNC();
	
	// Set lines interrupt
	cpct_asicSetLinesInterruptHandler(InterruptFunction, lines, sizeof(lines));
}

////////////////////////////////////////////////////
//	Initialize for CPC Plus	features
//		
void InitCpcPlus()
{
	cpct_disableFirmware(); // Disable firmware
	cpct_asicUnlock(); 		// Unlock asic
	cpct_asicPageConnect();	// Connect Asic memory page configuration (0x4000)
}

////////////////////////////////////////////////////
//	Set video mode and border color									 
//		
void InitVideo()
{
	// Set mode 1
	cpct_setVideoMode(1);
	
	// Set HWSprite palette 15 colours + border (colour 0)
	cpct_asicSetSpritePalette(sprite_palette, 16);
}

////////////////////////////////////////////////////
//	Set HWSprite Ship position on screen									 
//	
void UpdateShipPosition()
{
	if (gShip.status == SHIP_OK)
	{
		// Ship is composed of three parts
		cpct_asicSetSpritePosition(HW_SPRITE_REACTOR,    gShip.pos.x + SPRITE_WIDTH_SCREEN/2, gShip.pos.y);
		cpct_asicSetSpritePosition(HW_SPRITE_SHIP_REAR,  gShip.pos.x + SPRITE_WIDTH_SCREEN, gShip.pos.y);
		cpct_asicSetSpritePosition(HW_SPRITE_SHIP_FRONT, gShip.pos.x + 2*SPRITE_WIDTH_SCREEN, gShip.pos.y);
	}
	// Ship explosion
	else
	{
		// Not move when out of screen
		if (gShip.pos.x > ASTEROID_LIMIT_EXIT)
		{
			// Move explosion of ship to left 
			gShip.pos.x -= SCROLL_SPEED;
			
			// Update four parts explosion sprites at screen
			cpct_asicSetSpritePosition(HW_SPRITE_REACTOR,    gShip.pos.x, gShip.pos.y);
			cpct_asicSetSpritePosition(HW_SPRITE_SHIP_REAR,  gShip.pos.x + SPRITE_WIDTH_SCREEN, gShip.pos.y);
			cpct_asicSetSpritePosition(HW_SPRITE_SHIP_FRONT, gShip.pos.x, gShip.pos.y + SPRITE_HEIGHT_SCREEN);
			cpct_asicSetSpritePosition(HW_SPRITE_MOON,       gShip.pos.x + SPRITE_WIDTH_SCREEN, gShip.pos.y + SPRITE_HEIGHT_SCREEN);
		}
	}
}

////////////////////////////////////////////////////
//	Move asteroid HWSprite to screen position										 
//		
void MoveAsteroidSprite(SAsteroid* asteroid)
{
	// Copy to local variable
	i16 x = asteroid->pos.x;
	u8 y = asteroid->pos.y;
	u8 hwSpriteId = asteroid->hwSpriteId;

	// Set HWSprite id (0..15) at (x,y) coordinates
	cpct_asicSetSpritePosition(hwSpriteId, x, y);
	
	// Set three others sprites for large asteroid
	if (asteroid->type == ASTEROID_LARGE)
	{
		cpct_asicSetSpritePosition(hwSpriteId + 1, x + SPRITE_WIDTH_SCREEN, y);
		cpct_asicSetSpritePosition(hwSpriteId + 2, x, y + SPRITE_HEIGHT_SCREEN);
		cpct_asicSetSpritePosition(hwSpriteId + 3, x + SPRITE_WIDTH_SCREEN, y + SPRITE_HEIGHT_SCREEN);
	} 
}

////////////////////////////////////////////////////
//	Randomly set new asteroid coordinates									 
//		
void SetAsteroidInitPosition(SAsteroid* asteroid)
{
	#define ASTEROID_AREA_Y		150
	
	// Randomly chose new coordinates (right outside of screen for X position)
	asteroid->pos.x = ASIC_SCREEN_WIDTH + cpct_rand() % ASIC_SCREEN_WIDTH + asteroid->hwSpriteId*4;
	asteroid->pos.y = cpct_rand() % ASTEROID_AREA_Y;
}

////////////////////////////////////////////////////
//	Set HWSprite Ship explosions position on screen									 
//		
void SetShipExplosionSprites()
{
	#define NB_SPRITES_EXPLOSIONS	4
	
	// Compute explosion sprite position in all in one explosions sprite
	const u8* currentSpriteExplosion = sprite_explosions + ((NB_SPRITES_EXPLOSIONS - gShip.status) * HW_SPRITE_SIZE * NB_SPRITES_EXPLOSIONS);

	// Replace current sprites by explosion
	cpct_asicCopySpriteData(HW_SPRITE_REACTOR,    currentSpriteExplosion);
	cpct_asicCopySpriteData(HW_SPRITE_SHIP_FRONT, currentSpriteExplosion + HW_SPRITE_SIZE);
	cpct_asicCopySpriteData(HW_SPRITE_SHIP_REAR,  currentSpriteExplosion + 2*HW_SPRITE_SIZE);
	cpct_asicCopySpriteData(HW_SPRITE_MOON,       currentSpriteExplosion + 3*HW_SPRITE_SIZE);
	
	// Set explosion zoom 2x mode 1
	cpct_asicSetSpriteZoom(HW_SPRITE_REACTOR,    3, 2);
	cpct_asicSetSpriteZoom(HW_SPRITE_SHIP_FRONT, 3, 2);
	cpct_asicSetSpriteZoom(HW_SPRITE_SHIP_REAR,  3, 2);
	cpct_asicSetSpriteZoom(HW_SPRITE_MOON,       3, 2);
	
	// Set coordinates to explosion
	UpdateShipPosition();
}

////////////////////////////////////////////////////
//	Initialize Moon sprite								 
//		
void InitMoon()
{
	cpct_asicCopySpriteData(HW_SPRITE_MOON, moon);
}

////////////////////////////////////////////////////
//	Initialize player ship position and copy sprites to HWSprites										 
//		
void InitShip()
{
	// Set Ship start coordinates
	gShip.pos.x = START_SHIP_X;
	gShip.pos.y = START_SHIP_Y;
	
	// Set Ship size
	gShip.pos.cx = SHIP_SPRITE_WIDTH;
	gShip.pos.cy = SHIP_SPRITE_HEIGHT;

	// Copy array sprite data into HWSprite data
	cpct_asicCopySpriteData(HW_SPRITE_SHIP_REAR, allSprites[DATA_SPRITE_SHIP_REAR]);
	cpct_asicCopySpriteData(HW_SPRITE_SHIP_FRONT, allSprites[DATA_SPRITE_SHIP_FRONT]);
	
	// Clean Sprite Reactor with color 0 (Transparent)
	cpct_asicSetSpriteData(HW_SPRITE_REACTOR, 0);
	
	// Set ship position at screen
	UpdateShipPosition();
	
	// Reset moon position after ship explosion
	gEscapeDistance = DISTANCE_FOR_WIN;
	*gMoonPositionY = 0;
}

////////////////////////////////////////////////////
//	Initialize asteroid HWSprite data and position									 
//		
void InitAsteroids()
{
	#define ASTEROID_LARGE_SIZE	4
	
	SAsteroid* asteroidPtr = gAsteroids;
	
	u8 i, j;
	for (i = 0; i < ASTEROID_NB; i++)
	{
		u8 hwSpriteId = asteroidPtr->hwSpriteId;
	
		// Set HW sprite data according to asteroid type
		if (asteroidPtr->type == ASTEROID_LARGE)
		{
			// Set four parts of large asteroid
			for (j = 0; j < ASTEROID_LARGE_SIZE; j++)
				cpct_asicCopySpriteData(hwSpriteId + j, allSprites[DATA_SPRITE_ASTEROID_LARGE_0 + j]);
		}
		else if (asteroidPtr->type == ASTEROID_MEDIUM)
		{
			cpct_asicCopySpriteData(hwSpriteId, allSprites[DATA_SPRITE_ASTEROID_MEDIUM]);
		}
		else
		{
			cpct_asicCopySpriteData(hwSpriteId, allSprites[DATA_SPRITE_ASTEROID_SMALL]);
		}
		
		// Set initial asteroid position
		SetAsteroidInitPosition(asteroidPtr);
		
		// Set asteroid at screen coordinates
		MoveAsteroidSprite(asteroidPtr);
		
		// Next asteroid
		asteroidPtr++;
	}
}

////////////////////////////////////////////////////
//	Initialize all HWSprites zoom to equivalent Mode 1										 
//	
void SetHWSpriteZoom()
{
	// Set Zoom for Mode 1 for all 16 Hardware Sprites
	for (u8 i = 0; i < HW_SPRITE_NUMBER; i++)
		cpct_asicSetSpriteZoom(i, HW_SPRITE_MODE_1_ZOOM_X, HW_SPRITE_MODE_1_ZOOM_Y);
}

////////////////////////////////////////////////////
//	Initialize HW sprite with palette color and zoom Mode 1										 
//		
void InitHWSprites()
{
	// Initialize all game HWSprites
	InitShip();
	InitAsteroids();
	InitMoon();

	// Set Default HWSprite zoom
	SetHWSpriteZoom();
	
	// Get direct pointer to Moon HWSprite coordinates
	gMoonPositionX = cpctm_getSpriteCoordPtrX(HW_SPRITE_MOON);
	gMoonPositionY = cpctm_getSpriteCoordPtrY(HW_SPRITE_MOON);
}

////////////////////////////////////////////////////
//	Draw background with software sprites										 
//		
void DrawBackground()
{
	#define MODE_1_SCREEN_HEIGHT	200
	#define SCREEN_BYTES_WIDTH		80
	#define NB_OF_STARS_TO_DRAW		100
	#define NB_OF_DIFFERENTS_STARS	6

	// Compute video position of first planet sprite
	u8* vmem = cpctm_screenPtr(CPCT_VMEM_START, 0, MODE_1_SCREEN_HEIGHT - PRE_PLANET_H);
	
	// Fill bottom of the screen with planet sprite
	u8 i;
	for (i = 0; i < SCREEN_BYTES_WIDTH/PRE_PLANET_W; i++)
		cpct_drawSprite(pre_planet, vmem + i*PRE_PLANET_W, PRE_PLANET_W, PRE_PLANET_H);

	// Fill top of the screen with randomly stars
	for (i = 0; i < NB_OF_STARS_TO_DRAW; i++)
	{
		vmem = cpct_getScreenPtr(CPCT_VMEM_START, cpct_rand()%(SCREEN_BYTES_WIDTH - PRE_STARS_0_W), cpct_rand()%STARS_AREA_HEIGHT);
		cpct_drawSprite(pre_tileset[cpct_rand()%NB_OF_DIFFERENTS_STARS], vmem, PRE_STARS_0_W, PRE_STARS_0_H);
	}
}

////////////////////////////////////////////////////
//	Test collision between asteroid and ship
//
bool TestCollision(SAsteroid* asteroid)
{
	#define ValueInRange(value, min, max)	((value >= min) && (value <= max))

	// Local computation of Ship rectangle points
	u8 shipY = gShip.pos.y + SHIP_COLLISION_Y;
	u8 shipCY = shipY + gShip.pos.cy ;
	i16 ShipCX = gShip.pos.x + (i16)gShip.pos.cx;
	
	// Local computation of Asteroid rectangle points
	u8 asteroidCY = asteroid->pos.y + asteroid->pos.cy;
	i16 AsteroidCX = asteroid->pos.x + (i16)asteroid->pos.cx;
	
	// Test if rectangles collide
	return (ValueInRange(asteroid->pos.y, shipY, shipCY) || ValueInRange(shipY, asteroid->pos.y, asteroidCY)) 
			&& (ValueInRange(asteroid->pos.x, gShip.pos.x, ShipCX) || ValueInRange(gShip.pos.x, asteroid->pos.x, AsteroidCX));
}

////////////////////////////////////////////////////
//	Update Moon position to indicate remaining 
//  distance before winning game									 
//	
void UpdateMoon()
{
	if (gShip.status == SHIP_OK)
		*gMoonPositionX = (gEscapeDistance-= SCROLL_SPEED)/10;
}

////////////////////////////////////////////////////
//	Update asteroid : move and test collisions									 
//		
void UpdateAsteroids()
{
	SAsteroid* asteroidPtr = gAsteroids;
	u8 i;
	
	// Check if all asteroids exited
	gAllAsteroidsExit = true;
	
	for (i = 0; i < ASTEROID_NB; i++)
	{
		// If asteroid is in screen
		if (gShip.status == SHIP_OK && asteroidPtr->pos.x > 0 && asteroidPtr->pos.x < HW_SPRITE_MAX_X)
		{
			// Test collision with Ship
			if (TestCollision(asteroidPtr))
			{
				// Ship is destroyed
				gShip.status = SHIP_EXPLOSIONS;
				SetShipExplosionSprites();
			}
		}
		
		//  Test if it must be move to initial position
		if (asteroidPtr->pos.x < ASTEROID_LIMIT_EXIT)
		{
			// If game not win then reset asteroid position
			if (gEscapeDistance > 0 && gShip.status == SHIP_OK)
				SetAsteroidInitPosition(asteroidPtr);
		}
		else
		{
			// Move asteroid to left
			asteroidPtr->pos.x -= asteroidPtr->speed;
	
			// Move HWSprite asteroid according to game coordinates
			MoveAsteroidSprite(asteroidPtr);
			
			// All asteroids are not in screen
			gAllAsteroidsExit &= false;
		}
		
		// Next asteroid
		asteroidPtr++;
	}
}

////////////////////////////////////////////////////
//	Display Win Sprites									 
//	
void WinSequence()
{
	// Move Ship out of screen
	if (gShip.pos.x < ASIC_SCREEN_WIDTH)
	{
		gShip.pos.x += 2*SCROLL_SPEED;
	}
	// Display Win
	else
	{
		// Horizontal center Win sprites
		u16 posX = (ASIC_SCREEN_WIDTH - SPRITE_WIDTH_SCREEN * 2) / 2;

		// Replace Sprite Ship with Win Sprites
		cpct_asicCopySpriteData(HW_SPRITE_SHIP_REAR, win_1);
		cpct_asicCopySpriteData(HW_SPRITE_SHIP_FRONT, win_2);

		// Set position in screen center 
		cpct_asicSetSpritePosition(HW_SPRITE_SHIP_REAR, posX, (ASIC_SCREEN_HEIGHT - SPRITE_HEIGHT_SCREEN) / 2);
		cpct_asicSetSpritePosition(HW_SPRITE_SHIP_FRONT, posX + SPRITE_WIDTH_SCREEN, (ASIC_SCREEN_HEIGHT - SPRITE_HEIGHT_SCREEN) / 2);

		// Wait for key before ..
		while(!cpct_isAnyKeyPressed());
		
		// .. start again
		gEscapeDistance = DISTANCE_FOR_WIN;
		InitShip();		
	}
}

////////////////////////////////////////////////////
//	Ship in play									 
//		
void InPlay()
{
	#define REACTOR_SPEED_ANIMATION		3

	// Static reactor fire counter animation
	static u8 sFire = 0;

	// Static reactor sprite selector
	static bool sReactorSprite = true;

	// Test if time to change reactor sprite
	if (sFire++ > REACTOR_SPEED_ANIMATION)
	{
		// Copy reactor sprite to HWSprite data
		u8* spriteReactor = sReactorSprite ? allSprites[DATA_SPRITE_SHIP_REACTOR_1] :  allSprites[DATA_SPRITE_SHIP_REACTOR_2];
		cpct_asicDrawToSpriteData(HW_SPRITE_REACTOR, 0, 5, spriteReactor, SPRITE_REACTOR_WIDTH, SPRITE_REACTOR_HEIGHT);
		
		// Flip reactor sprites
		sReactorSprite = !sReactorSprite;			
		
		// Reset counter animation
		sFire = 0;
	}
}

////////////////////////////////////////////////////
//	Ship destroyed									 
//	
void Destroyed()
{
	#define EXPLOSION_SPEED_ANIMATION	10

	// Explosion counter animation
	static u8 sExplosion = 0;

	if (sExplosion++ > EXPLOSION_SPEED_ANIMATION)
	{
		// Reset explosion counter
		sExplosion = 0;

		// Update sprite explosion
		if (gShip.status != SHIP_DESTROYED)
		{
			gShip.status--;
			SetShipExplosionSprites();
		}
		// Ship re-enter game after being destroyed
		else if (gAllAsteroidsExit)
		{
			gShip.status = SHIP_OK;
			
			// Reset HWSprite Zoom and Position
			SetHWSpriteZoom();
			InitAsteroids();
			InitShip();
			InitMoon();

			UpdateShipPosition();
		}
	}
}

////////////////////////////////////////////////////
//	Update Ship sprite									 
//		
void UpdateShip()
{
	// If ship flying
	if (gShip.status == SHIP_OK)
	{
		// If game win
		if (gEscapeDistance < 0 && gAllAsteroidsExit)
			WinSequence();
		else
			InPlay();
	}
	// Ship destroyed
	else
		Destroyed();
}

////////////////////////////////////////////////////
//	Read player input										 
//											   
void ReadInput()
{
	#define LIMITE_UP		10
	#define LIMITE_DOWN		140
	
	// If play in progress and game not win
	if (gShip.status == SHIP_OK && !(gEscapeDistance < 0 && gAllAsteroidsExit))
	{
		// Right 
		if (cpct_isKeyPressed(Key_CursorRight) || cpct_isKeyPressed(Joy0_Right))
		{
			// Test right limit
			if (gShip.pos.x < (ASIC_SCREEN_WIDTH - SHIP_SPRITE_WIDTH))
				gShip.pos.x += SHIP_SPEED_X;
		}
		else
		// Left
		if (cpct_isKeyPressed(Key_CursorLeft) || cpct_isKeyPressed(Joy0_Left))
		{
			// Test left limit
			if (gShip.pos.x > START_SHIP_X)
				gShip.pos.x -= SHIP_SPEED_X;
		}
			
		// Up
		if (cpct_isKeyPressed(Key_CursorUp) || cpct_isKeyPressed(Joy0_Up))
		{
			// Test up limit */
			if (gShip.pos.y > LIMITE_UP)
				gShip.pos.y -= SHIP_SPEED_Y;
		}
		else
		// Down
		if (cpct_isKeyPressed(Key_CursorDown) || cpct_isKeyPressed(Joy0_Down))
		{
			// Test down limit */
			if (gShip.pos.y < LIMITE_DOWN)
				gShip.pos.y += SHIP_SPEED_Y;	
		}
	}

	// Update ship position with new coordinates
	UpdateShipPosition();
}

////////////////////////////////////////////////////
//	Main loop										 
//		
void main(void) 
{
	InitCpcPlus();
	InitVideo();
	
	DrawBackground();
	InitHWSprites();
	SetInterruptHandler();

	// Infinite game loop
	while (1)
	{
		// Wait VSync and slow down game
		cpct_waitVSYNC();
		
		UpdateAsteroids();
		UpdateShip();
		UpdateMoon();
		
		ReadInput();
	}
}
