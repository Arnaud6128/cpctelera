# AKM (minimalist)

This format is made to generate very optimized music from Arkos Tracker 2. The goal is to beat CNG Soft music AND player. Overall, this is done, especially thanks to the Player Configuration. The format has also been honed to allow many optimizations.

- CNG Soft can encode its sounds with 4 bytes max. The difference is encoded on the fly when required, in the Tracks. This works well for simple songs (which is the target), but not for Tracks that would always switch instruments.
- He encodes a current "steps" on the fly, which make sequences like C/-/C/-/C/-... encoded efficiently (only the notes are encoded, not the "holes").
- This player may actually replace Lightweight!



## Limitations

- Only one PSG per Subsong.
- No "hard to soft" sounds.
- SoftAndHard more limited: hardware part is only with fixed hard period (allows "Ben Daglish" effects).
- No events.
- Only speed change at the start of a pattern are encoded.
- Arpeggio and Pitch values in the Expressions are limited in range: from -64 to 63.
- Arpeggio and Pitch Expressions are limited in size: 127 items only.
- Effects:
  - Reset with volume (0)
  - Set volume (1)
  - (fast)Pitch up/down (2)
  - Arpeggio table (inline will be converted) (3)
  - Pitch table (4)
  - Force Instrument Speed (5)
  - Force Arpeggio Speed (6)
  - Force Pitch Speed (7)


## Tracks

Contains the data of the notes, instruments, effects and waits (i.e. "holes").

Optimizations lie in simple but effective tricks:

- The two most instruments are stored ("primary" and "secondary").
- The same for the waits.
- Only 12 or 13 notes are referenced via an index. The others are "escaped".


Note that the end of the Track is marked as an escape wait with a large value. This way, there is no special flag to test. **TO IMPROVE?** There is still one byte used by it, too bad I can't optimize that.


```
For each Cell:
76543210
wwiinnnn

n = note or data.
  0-11 = note reference.
  12 = note and effects.
  	   If present, ALL the other flags are reset. Store a "force effect" flag in the player.
       Don't encode any following bytes.
       Then RE-ENCODE the SAME cell, with "data" being the note, as well as all the other bits normally. So we only lose one byte all in all. Don't forget to reset the "force effect" flag after reading the effects.

       Note: Important to have it first because it will be used as an additional note reference if there are no effects!
  13 = empty note, maybe effects.
  14 = new escape note (encoded below).
  15 = same escape note (not a primary/secondary one).

ii = instrument state.
  if data is NOT "empty note, maybe effects" or "note and effects":
    00 = same escape instrument (non primary/secondary instrument).
    01 = primary instrument used.
    10 = secondary instrument used.
    11 = new escape instrument (non primary/secondary instrument).
  if data is "empty note, maybe effects":
    00 = no effects.
    01 = effects present (bit 4 is 1).
    
ww = wait state.
  00 = same escape wait (non primary/secondary wait).
  01 = primary wait used.
  10 = secondary wait used.
  11 = new escape wait (non primary/secondary wait).

if escape note:
  db note
Note: it must be stored in the channel data, because reused if "same escape note".

if escape instrument:
  db instrument
Note: it must be stored in the channel data, because reused if "same escape instrument".

if escape wait:
  db wait
Note: it must be stored in the channel data, because reused if "same escape wait".
  
if effects, they are then encoded.
```

### Effects

```
76543210
ddddeeem
m = more effects?
e = effect index.
d = effect data, if needed.

+ More data if the effect requires it.
+ Plus more of this structure if more effects.
```

#### Reset effect with inverted volume

```
76543210
iiii000m

i = inverted volume (15 = lowest, 0 = highest)
```

#### Volume effect

```
76543210
iiii001m

i = inverted volume (15 = lowest, 0 = highest)
```

#### Pitch up/down effect

```
76543210
---s010m

s = 0 = stop pitch, 1 = pitch used.
if pitch used:
	  	dw positive pitch, bit 15 is sign (1 for negative).

```

#### Arpeggio table effect

```
76543210
aaaa011m

a = Arpeggio number (0 = stop arpeggio, 15 = escape)

If escape:
  db arpeggio number.
```

**The structure is the same for many of the effects, don't change it!**

#### Pitch table effect

The same as above, with code 100.

#### Force instrument speed

The same as above, with code 101.

#### Force Arpeggio speed

The same as above, with code 110.

#### Force Pitch speed

The same as above, with code 111.





## Instruments

**The Instrument format is the same as the Lightweight format, EXCEPT that the encoded ratio for the hardware sounds is NOT inverted.**





## Arpeggio tables

Arpeggio 0 is not encoded.

```
dw Arpeggio1
dw Arpeggio2
...
```

## Arpeggio

Their range is more limited than the generic format. The size is also limited to 64.

```
db speed (>=0)
```

For each Arpeggio:

```
76543210
vvvvvvvf

f = end?

if f = 0
	v = signed value (-64 : 63).
if f = 1,
	v is loop index (>=0).
```

## Pitch tables

Pitch 0 is not encoded.

```
dw Pitch1
dw Pitch2
...
```

## Pitch

Only 8 bits, signed. Exact same format as the Arpeggio.



# Song format

## Song

There is no specific start marker, as it would take memory.

```
dw instrumentIndexTable
dw arpeggioIndexTable - 2 (0 if there is none) -2 because the 0 arpeggio is not encoded.
dw pitchIndexTable - 2 (0 if there is none) -2 because the 0 arpeggio is not encoded.

dw subsong0Address
dw subsong1Address (if present)
...
```

Then are encoded (in any order):

- the Instrument index table.
- the Instruments.
- the Arpeggios (if any).
- the Pitches (if any).

# Subsongs

## Subsong Header

```
dw noteBlockIndexTable
dw trackIndexTable

db initialSpeed

db primaryInstrument (most used instrument)
db secondaryInstrument (second most used instrument)

db primaryWait (most used wait)
db secondaryWait (second most used wait)

db defaultStartNoteInTracks (should be different from referenced note)
db defaultStartInstrumentInTracks (should be different from primary instruments)
db defaultStartWaitInTracks (should be different from primary waits)

db areEffectsPresent (13 if not, 12 if present. Values used by Z80 CP instruction.)
```



## Linker

It must follow the Subsong header. This derives from the Lightweight format, but is more optimized.

For every position:

```
76543210
ctctcths

s = speed change or end of song?
	if end of song (the other bits are useless):
		db 0 (speed to 0, impossible value)
		dw loopAddress in the linker
	if speed change:
		db speed (>0).
h = height change?
	if height change:
		db lineCount (0-127)
t = transposition change for channel 1-3 (bit 2, 4, 6)?
	db transp1 (if bit 2 is set)
	db transp2 (if bit 3 is set)
	db transp3 (if bit 4 is set)
c = new tracks for channel 1-3 (bit 3, 5, 7)?
    for each different channel (from 1 to 3):
    	76543210
    	iddddddd
    	
    	i = reference?
    	if i = 1: d = index of track
    	if i = 0: d = MSB of track offset from $+2 (past where the offset is)
                    + db LSB of track offset from $+1 (past where the offset is)
```

Warning when encoding! If the transpositions and track indexes at the end of the song are not the same as at the beginning of the loop, the latter must be encoded.

## TrackIndexes

Table with the tracks that are referenced. Only the tracks that are worth indexed are put here (track with one or two use are not worth it).

Warning! There must be no 'holes" in this map, so the exporter must use a mapping between trackId (non linear) and "encoded Track id" (linear).



## Other data

The data, presented at the top, are encoded in any order.
