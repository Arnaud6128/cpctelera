# RAW Linear, format 1.0

There is no pattern or tracks, only a list of all the notes/effects of one subsong.
This is useful for fast player needed only the notes, such as sample players.

There is no header.

This is only a list of line of notes, or wait commands. There is no notion of speed.
Instruments are not encoded.

	db command
        if 255: end of frame (i.e. wait for 1 frame. More optimized than using the 254 command with 1 (2 bytes)).
        if 254: wait for X frames ("1" means the next commands must be read on the next frame)
            dw wait count (>0)
        if 253: end of stream
            dw goto address
        else: channel number

If channel number (>=0, 0 being the first channel):

    db note
        255 if none, in case there are only effects
    db instrument index
        255 if none (because no note). Legato is currently not supported
        0 = RST
Followed by the list of effects (always at least one, at least to mark the end):

    db effect number
        0 = no more effects
    dw effect value
        Only present if the effect requires it

It is important to note that if exporting only one type of instrument (PSG or Sample),
encountering a not-exported instrument type will encode a RST, so that the player knows
that it must stop the playing. Subsequent effects are ignored.
        