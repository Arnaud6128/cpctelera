# 3.5.1 - XX/XX/25

## Tweaking
- Added more effect optimizations when exporting to AKG/AKM. You might save a few bytes and CPU cycles!
- AKM: The first Disark label has been added "Start" to match the first label, just like in the AKG player, and helps CPCTelera refers to it in the same way for both players.
- YM export: Vastly improved the speed of the interleaved YM export.

## Bugfixes
- Volume in/out was stopped when a legato note was used. This has been corrected, the legato does not stop the effect anymore. The AKG player already did the right behavior!
- AKM export: unknown effects were not correctly handled, possibly leading to crash on hardware. They are now well ignored (thanks Krusty!).
- UI only: on export to binary, the "generate a player configuration for players (as source)" option was disabled, which was not logical. It is now always enabled.
- Undo of Delete Subsong was broken.

# 3.5 - 11/12/25

## Features
- Added a new command-line tool, Z80 Profiler, to count how many NOPs are spent calling Z80 code. Yep, it can profile music player, or anything else! Check out the online doc for a complete example. Thanks to Krusty for the idea, and Roudoudou for the accurate NOP asm file and log!
- Added a new frequency viewer, visible when clicking on an icon in the meters view (hover the mouse over to show it).
- FAP:
    - Generated an asm file along the FAP binary file (called "..._fap_constants.asm"), to include it directly to your production instead of using hardcoded values (buffer size, etc.).
    - Allowed to force a PSG frequency when exporting (also on the command line tool).
    - Added an "Export YM to FAP" option to directly convert any YM to FAP.
    - The SongToFap command line tool can directly have an YM as an input.
    - Clearer report shown on export.
- YM: SongToYm command line tool can directly have an YM as an input. Useful to convert YM3 into YM6 (...or the opposite)!
- Source profiles: a "constant declaration" field is added (needed by FAP constants generation).
- Streamed Music Analyzer:
    - Now plays digidrums! Note that some digidrums may sound different from ST-Sound: the latter does not apply the logarithmic volume of the PSG!
    - Corrected the reading of badly encoded hardware envelope ("Warheads" from Turrican 2 and "Chinese Revolution" from Chambers of Shaolin now plays well).
- Pasting/duplicating an instrument/expression prompts for a rename (but only if there is one selected item) (thanks Giherem!).

## Tweaking
- Mac: Major UI performance can be done by setting using "OpenGl" in File > Setup > General (else the UI is constantly refreshed for some obscure low-level reason). It is now default on Mac.
- Added a new demo music, "Aganamemnon" straight from BND#5 party (first place, woohoo!) (original version in the digidrum folder, plus a digidrum-less version).
- Added ST-Sid music from Doclands (thanks!) (these SIDs can only be played using ggn player on Atari ST, no SID is actually heard in AT3. See the link in the songs comment).
- Added a music from Ok3anos (thanks!).
- AKY: Added a tester for MSX (FPGA PSG, 6 channels), with sound effects (PlayerAkyWithSoundEffectTester_FPGAPSG_MSX.asm).

# Bugfixes
- SongToAkg: corrected a regression: crash because of badly handled optional parameters (thanks Krusty!).
- Pattern Viewer: playing a single line without note would restart the possible arpeggio/pitch.
- Effect Context: on slower computer, some latency could be heard after entering a note in complex music. This has been optimized.
- AKG: Corrected a small configuration player bug, which could mess glides up (happens if Glide effect is used without Pitch being ever used) (thanks Giherem!).
- The amplification ratio for exported samples was not well applied (too harsh).
- SE: Added "DisarkGenerateExternalLabel" to the "PLY_SE_PlaySoundEffectsStream" label, for SDCC/CPCTelera to be able to see it (thanks SagaDS!).
- YM export:
    - Corrected a possible crash when exporting samples.
    - Only the used part of the samples are exported.

## Bugfixes

# 3.4 - 19/10/25

## Features
- Added a Merge Song option, to add a newly loaded song into the current song, as additional subsongs.
- Added an Export Songs to TXT. It actually follows the same structure as the AKS XML, with less overhead.
- Added support for Spectravideo SVI 318/328 for the AKG player (thanks NYYRIKKI!).
- Added support for PCW (thanks Kachorro!):
    - For the AKG player.
    - For the AKY player.
    - For the AKY MultiPsg (6-channel for the Turbosound).
- CHP'n'SFX:
    - Added instrument pitch/vibrato from the CHP file.
    - Improved noise and volume management.
    - Corrected some files that couldn't be loaded (thanks Arnaud!).

## Tweaking
- AKY: Added a PLY_AKY_Stop method to stops the sounds, if the PLY_AKY_ADD_STOP_SOUNDS flag is present.
- Z80 players: adaptation to Rasm 2.3.9 by removing ":" before EQUs.
- ROM players have their size in the comment of the player (using sound effects increased the buffer size, which wasn't always indicated) (thanks ZXJogv!).
- Added a choice is the Edit PSG dialog to select MSX frequency (thanks NYYRIKKI!).
- Added 60 Hz as a radio button in the Subsong Properties (thanks NYYRIKKI!).
- The behavior of option in the Audio/Midi Setup to add the current octave to all the MIDI input notes has changed: Octave 4 in AT is the reference, and means +0. 3 means -1, 5 means +1, etc.
- Creating an instrument or an expression opens the related panel.
- Amsdos headers are skipped when loading .SKS and .128 songs.
- Added optimizations on export for speed tracks. It may save a few bytes.

## Bugfixes
- AKG and AKM players:
    - Corrected a small player configuration bug when the SFX used hardware sounds, and not the song itself (thanks Arnaud!).
- The MSX frequency is now 1789773 Hz (thanks NYYRIKKI!).
    - AKG and AKM players have been updated accordingly.
- CHP'n'SFX:
    - Corrected some imports which could fail (thanks Arnaud!).

# 3.3 - 18/09/25

## Breaking changes
- Glide effect:
    - It now requires the instrument to be removed. This is to be more logical, but also to prevent mistakes from the user. Please review your songs! Use the new Error Checker :).
    - As a convenience, imported AT2 songs with note + instrument + glide will have their instrument removed. However, AT3 songs are not modified.

## Features
- New player "AKY SPL" to play one sample (on any channel - but one sample at a time) along with PSG. Check the AKY SPL player and the related page on the website (https://www.julien-nevo.com/arkostracker/index.php/samplepsg-player/)!
- Error Checker:
    - Added an Error Checker (in the Tools menu) to check whether any effect is malformed in your song.
    - A warning icon shows in every Export dialog if the song contains errors.
- Added a new "Export to RAW Linear", useful for the new sample player.
- Added a MIDI export (thanks Doclands for the testing!).
- Added a MOD export. Please bear in mind the harsh limitations of this format (see the related page on AT website)!
- Added a "Export instrument to WAV".
- Added an option in the Audio/Midi Setup to add the current octave to all the MIDI input notes. Useful if you have a tiny MIDI keyboard!
- YM export can now export to YM3 (for legacy projects or specific converters).
- Pattern Viewer:
    - Added "paste and move below" (shift + V), very useful to spread the clipboard around.
    - Added a "paste continuously" (ctrl + P) to spread the clipboard till the end of the position.

## Tweaking
- The MOD player now uses a new period table, more accurate (the same as the AKY+SPL player).
- Added a "Load instrument" option in the main menu.
- Mixed the Edit Subsong properties and Select Subsong menus into one.
- Pattern Viewer:
    - When an action is forbidden because Record is off (paste, insert, etc.), the Record button flickers for you to understand why.
    - Legato and glide are shown in the color of the first instrument above, if found.
    - Glide/pitch up/down with value 0 when a note and instrument are present is considered an error, because useless.
- Linker:
    - When hovering over a position, the small "+" icon can be right-clicked to clone the position.
- The color of the note and instrument for glide effects and legatos is the same as the above instrument, if any (was previously neutral). 
- In some CLI tools, removed the "exportPlayerConfig" which didn't make sense for them.
- Added demo songs from Doclands (thanks!): Pong Cracktro (3 and 6 channels), and Tiny Things (3, 6 channels, PSG or samples versions).
- Players:
    - In the Z80 players that use RASM mnemonic REPEAT, added a control to make sure "startingindex" is well set with default (thanks Roudoudou!).
    - In AKM and AKY, modified a case problem with one constant, problematic if you used BASM or other case-sensitive assemblers (thanks Krusty!).
- Stream music analyzer:
    - Right-click on the previous/next arrows to move faster.
    - Click on the progress button to type a specific frame to go to.
- Changed the font below the logo (shown in the splash screen) to the main software font.
- Replacing a sample keeps the amplification ratio.

# 3.2.7 - 08/07/25

## Breaking changes
- The maximum note that can be played is now 127 (was 119), to mimic the hardware players which handle 8-bit possible notes, just like AT2. As a consequence, some corner-case effects may sound different.
- The header of the sample format has been simplified. If you used the MOD player, the new player will require new exports!
- The PSGs now include a "sample player frequency" which indicate on what frequency to play samples. It will probably change how your samples sound! Please check the manual on how it works.

## Features
- FAP export, in both the main software and the command line tool (SongToFap)! Enjoy this new superfast player from Gozeur/Contrast and Hicks/Vanity!
- Digidrums player for CPC, Spectrum and MSX! Use the AKY player, check the tester and the online doc.
- Sample export option.
- Sample export command line tool.
- AKG and AKM exports can select which subsongs are exported, instead of all (note that the CLI already allowed that).
- In all the exports with samples, the samples are now resampled according to their "diginote".

## Bugfixes
- Corrected a big bug in the sample replay: if not using a 1Mz PSG, the samples would sound higher or lower.
- Exports:
    - Corrected an **important** bug that would duplicate instruments and expressions if exporting several subsongs! Nothing critical, but a bit of memory was wasted, so it is advised to export your song again if you were using multiple subsongs.
    - AKG: corrected an important bug that could cut the last line of 128-cell high patterns.
- Sample export: corrected the fade-out that was broken if mixed with an offset.
- Pattern Viewer: corrected a Cut problem which could bypass clearing the special tracks.

## Tweaking
- Added demos songs from:
    - Totta, using very cool hardware tricks (thanks!!).
    - Doclands, using samples (thanks!!).
- The default digichannel is now 2 (middle channel).
- Removed the content of the AKY 68000 player, replaced with a link to ggn's repository, as I preferred to link the latest player.

# 3.2.6 - 25/04/25

## Features
- The splash screen contains more tips, with images and videos.
- You can load any song via command-line: ArkosTracker3 <path to the song to load> (thanks Mr.Lou for the suggestion!).

## Bugfixes
- Corrected a big (but rare and random) bug creating desync between PSGs (thanks Jonah (Tasteful Mr) Ship!).
- Corrected a special case in the audio engine for hardware period 0.
- Raw export:
    - The samples were not exporting (thanks Ludo!).
    - Corrected minor mistakes on exporting (some already present in AT2!).
- Corrected a possible crash when editing several positions to change their color (thanks Doclands!).

## Tweaking
- Added demo songs from:
    - Doclands, including Timeless on 6 channels (thanks!!).
    - Jonah (Tasteful Mr) Ship, including one 6-channel (thanks!!)
    - Giherem (thanks !!)
- Bar Editor:
    - Modifying a cell (shift+up/down) or duplicating cells (shift+space) sets the loop end if the modified cells are after it.
- Added the replay frequency in the VGM export metadata.

# 3.2.5 - 06/03/25

## Features
- Generate instruments from selected blocks!
- Instrument Editor: Added a small highlight of what bar is being played.
- Lists: Added a "duplicate" option.
- Linker: Editing multiple positions is now possible, to modify their height and related pattern colors.
- Pattern Viewer: added a "swap channels" tool in the toolbox.
- The Export to WAV dialog has now independent parameters (mix, frequency, stereo separation).

## Tweaking
- Effect Context: when playing the song (as opposed to line/pattern/block), the loop does not use effect context, which is what would happen in the players.
- Windows:
    - Installer has a better icons and installation folder.
- Stream Music Analyzer: the loop management has been refined, UI slightly reorganized.
- Loading a song via "Open recent Song" updates the last folder to open when loading a song.
- Mac:
    - Save shortcut now uses Command, not Ctrl.
- Added more bass drum/snare instruments from famous Atari ST composers to the package.

## Bugfixes
- Corrected a big bug in the audio engine if using multiple PSGs and fast replay frequency (the audio could stutter, also in the WAV export) (thanks Jonah (Tasteful Mr) Ship!).
- A change in the replay frequency wasn't taken in account directly (thanks Jonah (Tasteful Mr) Ship!).
- Stream Music Analyzer: Improved the instrument export:
    - Noise could be wrong if the YM had too many bits encoded.
    - Noise and software period of 0 are set to 1 if used, as AT considers 0 "empty" (for noise) and "auto" (for period). This takes care of several Big Alec sounds.
- PV toolbox: on rare occasions, the Undo/Redo could fail if using multiple subsongs.
- Various minor fixes...

# 3.2.4 - 11/02/25

## Features
- Effect context in the Pattern Viewer! Playing will recover previous effects, the cursor follows them too.
- One or several instruments can be drag'n'dropped to load them.
- BPM is displayed along the speed.

## Tweaking
- Added four songs composed by Doclands (thanks!) to the package.
- Sample editor:
    - Samples now display the original file name.
    - Display of the static data is moved below the sample wave. 
- Space now plays the pattern from the top/block, everywhere in the software. Previous actions mapped to space has been remapped with shift.
- Pattern Viewer: a glide after a reset effect is considered an error.
- Play icons in the top bar are highlighted according to the play mode. 
- Added the "Gray" theme.
- Focusing on lists shows the right color in the background.

## Bugfixes
- AT2 instruments can now be loaded (thanks Haddhar!).
- Since AT2 (!), a Reset effect didn't stop a volume in/out! This was a critical mistake! Present in the editor only, not in the players.
- Mac:
    - All cut/copy/paste were wrongly mapped to Ctrl instead of Command (thanks Doclands!).
- Windows:
    - The YM exports could wrongfully be zipped (thanks Doclands!).
    - Corrected a possible crash when changing the keyboard layout.
- Pattern Viewer: improved/corrected the positioning of the toolbox and its icon when resizing the window.
- YM export: corrected a possible crash yet again.
- Loaded samples were using a default sample frequency, instead of the real one (thanks Doclands!).

# 3.2.3 - 23/12/24

## Features
- Tools:
    - Added a "Rearrange patterns" to sort the patterns in ascending order. 
    - "Rearrange patterns" can also remove useless patterns.
    - Added a "Clear patterns" to remove all the patterns and tracks of this subsong.

## Tweaking
- IE: The position height is now in decimal if the lines are shown in decimal (thanks Reset!). Improved the Set Height dialog.
- Bar editors:
    - Space to duplicate now fills the other values better, when out of bounds.

## Bugfixes
- The shift parameter in Expressions wasn't saved!
- Arkos Tracker 1 song couldn't be loaded unless unzipped (thanks Reset!).
- Linker:
    - Cannot cut all the patterns anymore (thanks Reset!). Cut and Delete contextual options are greyed out if the whole song is selected.
- YM Export:
    - Non-used hardware envelopes/periods aren't encoded as 0 anymore.
    - Corrected how simple event could produce a corrupted file.
    - Corrected a possible crash on export.

# 3.2.2 - 01/12/24

## Features
- Linux: The app icon is well set, as app is well declared to the OS and can be found (thanks Shalafi!).
- Mac: Run now on both Silicon and older Intel processors.
- Instrument Editor:
    - Most rows can now be hidden. The arrow is shown only on hovering. Empty rows are automatically hidden.
    - Moving from an instrument to another keeps its hidden/shrunk features.
    - Rows can also be shrunk according to their maximum values.
    - Shift/ctrl+F to toggle the visibility of the row above/below the cursor.
    - Shift/ctrl+G to grow/shrink the row where the cursor is.
    - Shift+H to hide all the empty rows and shrink all rows. Ctrl+H to also shrink to a maximum.
- Bar editors:
    - Backspace to reset the value where the cursor is.
    - Space now only duplicates the value where cursor is (shift+space to duplicate the whole column).
- Test area: the currently used expression is written below each icon.
- Streamed music analyzer:
    - Last loaded song and playing position are kept in memory for reopening.
    - Added a "lock length" icon for the loop end to follow the loop start.
- Press Tab to go from a panel to another, Shift+Tab to go reverse.
- Command line tools (AKG, AKM): added a "s" parameter to export only specific subsongs. As a convenience, if not present, all the subsongs are exported (different behavior from AT2 where only the first one was!).
- Selecting the instrument/pitch/arpeggio editor panel automatically opens the related list.

## Bugfixes
- Creating a new song wouldn't clear the path of the previous song, so saving it would overwrite it!
- Corrected the width of the caption background in the bars when there are 3 digits.
- The default song doesn't have a second empty arpeggio/pitch anymore.

# 3.2.1 - 21/10/24

## Tweaking
- PV: Changed how clone pattern would treat linked-to tracks: cloned tracks are linked.
- Some wording in contextual menus.

## Bugfixes
- LK: Corrected a few bugs when moving patterns (thanks Zik!).
- PV: Special track names were not saved (thanks Zik again!).
- WAV export: Corrected a wrong looping behavior (thanks Zik again again!).

# 3.2.0 - 21/09/24

## Features
- An instrument optimizer tool window allows to see what instruments are unused, and delete them.
- PV: Toolbox to transpose, map/remap instrument.

## Tweaking
- PV: Crt+T to select the whole track can also select several tracks according the current selection.
- PV: Crt+A to toggle between selecting the whole music tracks/tracks.
- PV: Space behavior changed: if there is no block, plays the whole pattern instead of creating a block.
- TA: Muted channels are now skipped in both monophony and polyphony.
- LK: Cloning a position doesn't duplicate the tracks names (to make the Link feature work better) and marker.
- LK: New shortcut to increase/decrease the pattern index (ctrl+shift+up/down).
- IE: New shortcuts to set/toggle the loop/auto-spread (Ctrl+I/O/P, add shift for auto-spread).

## Bugfixes
- PV: Corrected the MIDI record which failed.
- IE: Corrected a crash when moving the cursor to the start.
- TA: Corrected a crash when changing a toggle (regression).

# 3.1.0 - 15/06/24

## Breaking changes
- Due to the new Link feature, **songs created with 3.0.0 will NOT be compatible!**
- AKY export has been fixed for hardware+noise. **All AKY must be exported again with AT3 to sound correctly with the new player**.

## Features
- PV: Tracks can be linked/unlinked, Special Tracks too. Context menu possible.
- PV: Effect dropdown overhaul.
- PV: Capture the instrument is extended to capture effect and arp/pitch.
- PV: Red border when recording.
- PV: Reordering/adding/removing instruments/expressions does not erase illegal items in the patterns anymore.
- LK: Added hovering icons to add new/repeat positions.
- LK: Enter and double-click on a position now opens the Pattern Viewer.
- LK: Click on the color swatch to edit the position.
- IE: A cursor is now present. Use cursor, space to duplicate, Enter to edit. Insert/delete/generate actions perform from here.
- IE/PV: Alt+mouse wheel to scroll horizontally.
- Ability to import/export Themes from/to XML.
- Added changelog to the build.

## Bugfixes
- AKY: Hardware sound with noise was broken on exporter and player config change interpreted in the player (thanks Zik).

# 3.0.0 - 16/03/24

First release.