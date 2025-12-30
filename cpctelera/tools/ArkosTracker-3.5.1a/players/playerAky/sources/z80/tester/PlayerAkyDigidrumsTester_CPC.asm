        ;Tests the AKY player with digidrums.

        buildsna
        bankset 0

        org #100
Start   equ $

        di
        ld hl,#c9fb
        ld (#38),hl

        ld hl,#c000
        ld de,#c001
        ld bc,#1000
        ld (hl),l
        ldir

        ;Initializes the music.
        ld hl,MusicStart
        call PLY_AKY_Init

        ;Initializes the digidrums.
        ld hl,MusicEvents               ;Address of the events (digidrums).
        ld de,MusicSamples              ;Address of the sample table.
        ld a,DIGICHANNEL_INDEX          ;Channel (0, 1 (=middle), 2)
        call PLY_AKY_InitDigidrums

Sync:   ld b,#f5
        in a,(c)
        rra
        jr nc,Sync + 2
Sync2:  in a,(c)
        rra
        jr c,Sync2

        ld bc,#7f10
        out (c),c
        ld a,#4b
        out (c),a

        ;Plays a frame of the music. Digidrums are also triggered when necessary.
        call PLY_AKY_Play

        ld bc,#7f10
        out (c),c
        ld a,#54
        out (c),a

        jr Sync


        ;Uncomment to use this song...
;MusicStart:
;DIGICHANNEL_INDEX = 1
;        include "../resources/DigitestMusic_CPC_playerconfig.asm"       ;Includes the music.
;        include "../resources/DigitestMusic_CPC.asm"
;MusicEvents:
;        include "../resources/DigitestEvents.asm"                       ;Includes the events and samples.
;MusicSamples:
;        include "../resources/DigitestSamples.asm"
;MusicEnd:

        ;... or this one.
MusicStart:
DIGICHANNEL_INDEX = 0   ;Use channel 0 (left).
        include "../resources/Aganamemnon_CPC_playerconfig.asm"       ;Includes the music.
        include "../resources/Aganamemnon_CPC.asm"
MusicEvents:
        include "../resources/AganamemnonEvents.asm"                  ;Includes the events and samples.
MusicSamples:
        include "../resources/AganamemnonSamples.asm"
MusicEnd:


        ;... or this one.
;MusicStart:
;DIGICHANNEL_INDEX = 1
;        include "../resources/MusicSarkboteur_CPC_playerconfig.asm"    ;Includes the music.
;        include "../resources/MusicSarkboteur_CPC.asm"
;MusicEvents:
;        include "../resources/DigidrumSarkboteurEvents.asm"            ;Includes the events and samples.
;MusicSamples:
;        include "../resources/DigidrumSarkboteurSamples.asm"
;MusicEnd:




MainPlayerStart:
        PLY_AKY_HARDWARE_CPC = 1
        
        ;Include digidrums replay? This must be declared BEFORE the player.
        PLY_AKY_USE_DIGIDRUMS = 1
        ;PLY_AKY_DIGIDRUM_PSG_NUMBER = 1      ;Optional, default value is 1.
        
        ;Want a ROM player (a player without automodification)?
        ;PLY_AKY_ROM = 1     ;Must be set BEFORE the player is included.

        ;Declares the buffer for the ROM player, if you're using it.
        ;LIMITATION: the address of the buffer must be declared *before* including the player, but PLY_AKY_ROM_BufferSize is only known *after*.
        ;A bit annoying, but you can compile once, get the buffer size, and hardcode it to put the buffer wherever you want.
        IFDEF PLY_AKY_ROM
                PLY_AKY_ROM_Buffer = #c000                  ;Can be set anywhere.
        ENDIF

        ;The player itself. No need to insert the digidrum player, it is inserted by the AKY player.
        ;It must be included AFTER the "_playerconfig" files, else the player will not be optimized according to the song.
        include "../PlayerAkyMultiPsg.asm"      ;Only this AKY player version supports digidrums.

MainPlayerEnd:
        print "Size of player: ", {hex}(MainPlayerEnd - MainPlayerStart)
        print "Size of music + samples + events: ", {hex}(MusicEnd - MusicStart)
                IFDEF PLY_AKY_ROM
        print "Size of buffer in ROM: ", {hex}(PLY_AKY_ROM_BufferSize)
                ENDIF
        print "Total size (player and music): ", {hex}($ - MusicStart)

        ;Saves the binary in a DSK.
        ;SAVE 'digitest.bin', Start, MainPlayerEnd - Start, DSK, 'generated/digitest.dsk'
