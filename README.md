![CPCtelera Logo][CPCTLogo]

_**Astonishingly fast Amstrad CPC game engine for C and Assembler developers**_

---------------------------------------------------------------

_**CPCteleraNext**_ is a fork of cpctelera with new features, in order to install :
 * Update your Cygwin environmment with latest package version you have alread used for CPCtelera
 * If needed, manually update the directory <cygwin_path>\usr\include\boost with the latest boost include (cygwin boost package is not updated anymore on x86 setup)
   - Download ZIP from https://www.boost.org/releases/latest/ and extract only boost subdirectory from archive
 * Run setup.sh as usual

_**What's new ?**_
 * Full support of SDCC 4.6.0 with all functions migrated to new call convention _sdcccall(1)
 * ArkosTracker3 integrated (AKG and AKM players) (https://www.julien-nevo.com/arkostracker/)
 * ZX0/ZX0B and ZX1/ZX1B compressors integrated (Néstor Gracia)
 * New functions and examples :
   - CPC+ (Asic) functions
   - EasyOverscan functions
   - Sprite clipping / zoom functions
   - Collision functions
   - SpriteBuffer new functions
   - Disc file loader (https://www.julien-nevo.com/arkos/fdc-tools/)
   - Disc sector read and write with automatic file data import at specific location

_**CPCtelera**_ is an integrated development framework for creating _**Amstrad CPC**_ games and content which includes:
 * A low-level library with support for: graphics, audio, keyboard, firmware, strings, video hardware manipulation and memory management.
 * A complete set of programming examples to learn from.
 * An API for developing games and software in *C* and Assembler.
 * A complete multi-platform building system with support for building CDTs and DSKs automatically.
 * Tools for content authoring (audio, graphics and level editing)
 * Automatic installers and wrappers for third party tools (such us emulators or other low-level libraries)

_**CPCtelera**_ has been conceived with these aims in mind:
 * Delivering a convenient, usable and fast environment for developing games
 * Providing an up-to-date, detailed and easy to consult documentation
 * Giving technical details of the complete implementation for those curious
 * Easing the install and configuration process

**Starting with** _**CPCtelera**_ is very easy: 
 * [**How to install CPCtelera**](http://lronaldo.github.io/cpctelera/files/readme-txt.html#Installing_CPCtelera)
 * [**CPCtelera reference manual**](http://lronaldo.github.io/cpctelera/files/readme-txt.html) 
 
### Supported Platforms

 * Windows (with [Cygwin][Cygwin] 32/64 bits)
 * OS X
 * Linux

If you test it in any platform (listed here or not) and have problems, please feel free to report them to us. 

### Contact information and support

 * email:    cpctelera@cheesetea.com
 * twitter:  *[@FranGallegoBR](http://twitter.com/frangallegobr)*

### Authors and License

 * (C) Copyright 2014-2026 [CPCtelera's _awesome_ authors](http://lronaldo.github.io/cpctelera/files/authors-txt.html)
 * _**CPCtelera**_ low-level library, examples and scripts are distributed under [GNU Lesser General Public License v3](http://lronaldo.github.io/cpctelera/files/license-txt.html)
 * Content authoring tools included within _**CPCtelera**_ (under _cpctelera/tools_ folder) have their own licenses. Check each of them in their respective folders for more details.

[![Cheesetea Logo][CTLogo]](http://www.cheesetea.com) [![Fremos logo][FRLogo]](http://fremos.cheesetea.com)

[![ByteRealms Logo][BRLogo]](http://www.byterealms.com) [![Carlio Logo][CLLogo]](http://www.carlio.es)

[CTLogo]: http://lronaldo.github.io/cpctelera/images/logo_cheesetea_230.png
[FRLogo]: http://lronaldo.github.io/cpctelera/images/logo_fremos_230.png
[BRLogo]: http://lronaldo.github.io/cpctelera/images/logo_byterealms_230.png
[CLLogo]: http://lronaldo.github.io/cpctelera/images/logo_carlio_230.png
[CPCTLogo]: http://lronaldo.github.io/cpctelera/images/cpct_logo.png
[Cygwin]: http://www.cygwin.com
