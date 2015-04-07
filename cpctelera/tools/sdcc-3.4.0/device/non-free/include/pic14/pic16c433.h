/*
 * This declarations of the PIC16C433 MCU.
 *
 * This file is part of the GNU PIC library for SDCC, originally
 * created by Molnar Karoly <molnarkaroly@users.sf.net> 2014.
 *
 * This file is generated automatically by the cinc2h.pl, 2014-03-09 13:32:10 UTC.
 *
 * SDCC is licensed under the GNU Public license (GPL) v2. Note that
 * this license covers the code to the compiler and other executables,
 * but explicitly does not cover any code or objects generated by sdcc.
 *
 * For pic device libraries and header files which are derived from
 * Microchip header (.inc) and linker script (.lkr) files Microchip
 * requires that "The header files should state that they are only to be
 * used with authentic Microchip devices" which makes them incompatible
 * with the GPL. Pic device libraries and header files are located at
 * non-free/lib and non-free/include directories respectively.
 * Sdcc should be run with the --use-non-free command line option in
 * order to include non-free header files and libraries.
 *
 * See http://sdcc.sourceforge.net/ for the latest information on sdcc.
 */

#ifndef __PIC16C433_H__
#define __PIC16C433_H__

//==============================================================================
//
//	Register Addresses
//
//==============================================================================

#ifndef NO_ADDR_DEFINES

#define TRIS_ADDR               0xFFFFFFFFFFFFFFFF
#define INDF_ADDR               0x0000
#define TMR0_ADDR               0x0001
#define PCL_ADDR                0x0002
#define STATUS_ADDR             0x0003
#define FSR_ADDR                0x0004
#define GPIO_ADDR               0x0005
#define PCLATH_ADDR             0x000A
#define INTCON_ADDR             0x000B
#define PIR1_ADDR               0x000C
#define ADRES_ADDR              0x001E
#define ADCON0_ADDR             0x001F
#define OPTION_REG_ADDR         0x0081
#define TRISIO_ADDR             0x0085
#define PIE1_ADDR               0x008C
#define PCON_ADDR               0x008E
#define OSCCAL_ADDR             0x008F
#define ADCON1_ADDR             0x009F

#endif // #ifndef NO_ADDR_DEFINES

//==============================================================================
//
//	Register Definitions
//
//==============================================================================


//==============================================================================
//        TRIS Bits

#define _TRIS0                  0x01
#define _TRIS1                  0x02
#define _TRIS2                  0x04
#define _TRIS3                  0x08
#define _TRIS4                  0x10
#define _TRIS5                  0x20

//==============================================================================

extern __at(0x0000) __sfr INDF;
extern __at(0x0001) __sfr TMR0;
extern __at(0x0002) __sfr PCL;

//==============================================================================
//        STATUS Bits

extern __at(0x0003) __sfr STATUS;

typedef union
  {
  struct
    {
    unsigned C                  : 1;
    unsigned DC                 : 1;
    unsigned Z                  : 1;
    unsigned NOT_PD             : 1;
    unsigned NOT_TO             : 1;
    unsigned RP0                : 1;
    unsigned RP1                : 1;
    unsigned IRP                : 1;
    };

  struct
    {
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned LINRX              : 1;
    unsigned LINTX              : 1;
    };

  struct
    {
    unsigned                    : 5;
    unsigned RP                 : 2;
    unsigned                    : 1;
    };
  } __STATUSbits_t;

extern __at(0x0003) volatile __STATUSbits_t STATUSbits;

#define _STATUS_C               0x01
#define _STATUS_DC              0x02
#define _STATUS_Z               0x04
#define _STATUS_NOT_PD          0x08
#define _STATUS_NOT_TO          0x10
#define _STATUS_RP0             0x20
#define _STATUS_RP1             0x40
#define _STATUS_LINRX           0x40
#define _STATUS_IRP             0x80
#define _STATUS_LINTX           0x80

//==============================================================================

extern __at(0x0004) __sfr FSR;

//==============================================================================
//        GPIO Bits

extern __at(0x0005) __sfr GPIO;

typedef union
  {
  struct
    {
    unsigned GP0                : 1;
    unsigned GP1                : 1;
    unsigned GP2                : 1;
    unsigned GP3                : 1;
    unsigned GP4                : 1;
    unsigned GP5                : 1;
    unsigned LINRX              : 1;
    unsigned LINTX              : 1;
    };

  struct
    {
    unsigned GP                 : 6;
    unsigned                    : 2;
    };
  } __GPIObits_t;

extern __at(0x0005) volatile __GPIObits_t GPIObits;

#define _GP0                    0x01
#define _GP1                    0x02
#define _GP2                    0x04
#define _GP3                    0x08
#define _GP4                    0x10
#define _GP5                    0x20
#define _LINRX                  0x40
#define _LINTX                  0x80

//==============================================================================

extern __at(0x000A) __sfr PCLATH;

//==============================================================================
//        INTCON Bits

extern __at(0x000B) __sfr INTCON;

typedef union
  {
  struct
    {
    unsigned GPIF               : 1;
    unsigned INTF               : 1;
    unsigned T0IF               : 1;
    unsigned GPIE               : 1;
    unsigned INTE               : 1;
    unsigned T0IE               : 1;
    unsigned PEIE               : 1;
    unsigned GIE                : 1;
    };

  struct
    {
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned TMR0IF             : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned TMR0IE             : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    };
  } __INTCONbits_t;

extern __at(0x000B) volatile __INTCONbits_t INTCONbits;

#define _GPIF                   0x01
#define _INTF                   0x02
#define _T0IF                   0x04
#define _TMR0IF                 0x04
#define _GPIE                   0x08
#define _INTE                   0x10
#define _T0IE                   0x20
#define _TMR0IE                 0x20
#define _PEIE                   0x40
#define _GIE                    0x80

//==============================================================================


//==============================================================================
//        PIR1 Bits

extern __at(0x000C) __sfr PIR1;

typedef struct
  {
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned ADIF                 : 1;
  unsigned                      : 1;
  } __PIR1bits_t;

extern __at(0x000C) volatile __PIR1bits_t PIR1bits;

#define _ADIF                   0x40

//==============================================================================

extern __at(0x001E) __sfr ADRES;

//==============================================================================
//        ADCON0 Bits

extern __at(0x001F) __sfr ADCON0;

typedef union
  {
  struct
    {
    unsigned ADON               : 1;
    unsigned                    : 1;
    unsigned GO_NOT_DONE        : 1;
    unsigned CHS0               : 1;
    unsigned CHS1               : 1;
    unsigned                    : 1;
    unsigned ADCS0              : 1;
    unsigned ADCS1              : 1;
    };

  struct
    {
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned GO                 : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    };

  struct
    {
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned NOT_DONE           : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    };

  struct
    {
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned GO_DONE            : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    };

  struct
    {
    unsigned                    : 3;
    unsigned CHS                : 2;
    unsigned                    : 3;
    };

  struct
    {
    unsigned                    : 6;
    unsigned ADCS               : 2;
    };
  } __ADCON0bits_t;

extern __at(0x001F) volatile __ADCON0bits_t ADCON0bits;

#define _ADON                   0x01
#define _GO_NOT_DONE            0x04
#define _GO                     0x04
#define _NOT_DONE               0x04
#define _GO_DONE                0x04
#define _CHS0                   0x08
#define _CHS1                   0x10
#define _ADCS0                  0x40
#define _ADCS1                  0x80

//==============================================================================


//==============================================================================
//        OPTION_REG Bits

extern __at(0x0081) __sfr OPTION_REG;

typedef union
  {
  struct
    {
    unsigned PS0                : 1;
    unsigned PS1                : 1;
    unsigned PS2                : 1;
    unsigned PSA                : 1;
    unsigned T0SE               : 1;
    unsigned T0CS               : 1;
    unsigned INTEDG             : 1;
    unsigned NOT_GPPU           : 1;
    };

  struct
    {
    unsigned PS                 : 3;
    unsigned                    : 5;
    };
  } __OPTION_REGbits_t;

extern __at(0x0081) volatile __OPTION_REGbits_t OPTION_REGbits;

#define _PS0                    0x01
#define _PS1                    0x02
#define _PS2                    0x04
#define _PSA                    0x08
#define _T0SE                   0x10
#define _T0CS                   0x20
#define _INTEDG                 0x40
#define _NOT_GPPU               0x80

//==============================================================================


//==============================================================================
//        TRISIO Bits

extern __at(0x0085) __sfr TRISIO;

typedef union
  {
  struct
    {
    unsigned TRIS0              : 1;
    unsigned TRIS1              : 1;
    unsigned TRIS2              : 1;
    unsigned TRIS3              : 1;
    unsigned TRIS4              : 1;
    unsigned TRIS5              : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    };

  struct
    {
    unsigned TRIS               : 6;
    unsigned                    : 2;
    };
  } __TRISIObits_t;

extern __at(0x0085) volatile __TRISIObits_t TRISIObits;

#define _TRISIO_TRIS0           0x01
#define _TRISIO_TRIS1           0x02
#define _TRISIO_TRIS2           0x04
#define _TRISIO_TRIS3           0x08
#define _TRISIO_TRIS4           0x10
#define _TRISIO_TRIS5           0x20

//==============================================================================


//==============================================================================
//        PIE1 Bits

extern __at(0x008C) __sfr PIE1;

typedef struct
  {
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned ADIE                 : 1;
  unsigned                      : 1;
  } __PIE1bits_t;

extern __at(0x008C) volatile __PIE1bits_t PIE1bits;

#define _ADIE                   0x40

//==============================================================================


//==============================================================================
//        PCON Bits

extern __at(0x008E) __sfr PCON;

typedef struct
  {
  unsigned                      : 1;
  unsigned NOT_POR              : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  unsigned                      : 1;
  } __PCONbits_t;

extern __at(0x008E) volatile __PCONbits_t PCONbits;

#define _NOT_POR                0x02

//==============================================================================


//==============================================================================
//        OSCCAL Bits

extern __at(0x008F) __sfr OSCCAL;

typedef union
  {
  struct
    {
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned CALSLW             : 1;
    unsigned CALFST             : 1;
    unsigned CAL0               : 1;
    unsigned CAL1               : 1;
    unsigned CAL2               : 1;
    unsigned CAL3               : 1;
    };

  struct
    {
    unsigned                    : 4;
    unsigned CAL                : 4;
    };
  } __OSCCALbits_t;

extern __at(0x008F) volatile __OSCCALbits_t OSCCALbits;

#define _CALSLW                 0x04
#define _CALFST                 0x08
#define _CAL0                   0x10
#define _CAL1                   0x20
#define _CAL2                   0x40
#define _CAL3                   0x80

//==============================================================================


//==============================================================================
//        ADCON1 Bits

extern __at(0x009F) __sfr ADCON1;

typedef union
  {
  struct
    {
    unsigned PCFG0              : 1;
    unsigned PCFG1              : 1;
    unsigned PCFG2              : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    unsigned                    : 1;
    };

  struct
    {
    unsigned PCFG               : 3;
    unsigned                    : 5;
    };
  } __ADCON1bits_t;

extern __at(0x009F) volatile __ADCON1bits_t ADCON1bits;

#define _PCFG0                  0x01
#define _PCFG1                  0x02
#define _PCFG2                  0x04

//==============================================================================


//==============================================================================
//
//        Configuration Bits
//
//==============================================================================

#define _CONFIG1                0x2007

//----------------------------- CONFIG1 Options -------------------------------

#define _FOSC_LP                0x3FF8  // LP oscillator.
#define _LP_OSC                 0x3FF8  // LP oscillator.
#define _FOSC_XT                0x3FF9  // XT oscillator.
#define _XT_OSC                 0x3FF9  // XT oscillator.
#define _FOSC_HS                0x3FFA  // HS oscillator.
#define _HS_OSC                 0x3FFA  // HS oscillator.
#define _FOSC_EXTCLK            0x3FFB  // EC I/O.
#define _EXTCLK_OSC             0x3FFB  // EC I/O.
#define _FOSC_INTRCIO           0x3FFC  // INTRC, OSC2 is I/O.
#define _INTRC_OSC_NOCLKOUT     0x3FFC  // INTRC, OSC2 is I/O.
#define _INTRC_OSC              0x3FFC  // INTRC, OSC2 is I/O.
#define _FOSC_INTRCCLK          0x3FFD  // INTRC, clockout on OSC2.
#define _INTRC_OSC_CLKOUT       0x3FFD  // INTRC, clockout on OSC2.
#define _FOSC_EXTRCIO           0x3FFE  // EXTRC, OSC2 is I/O.
#define _EXTRC_OSC_NOCLKOUT     0x3FFE  // EXTRC, OSC2 is I/O.
#define _EXTRC_OSC              0x3FFE  // EXTRC, OSC2 is I/O.
#define _FOSC_EXTRCCLK          0x3FFF  // EXTRC, clockout on OSC2.
#define _EXTRC_OSC_CLKOUT       0x3FFF  // EXTRC, clockout on OSC2.
#define _WDTE_OFF               0x3FF7  // WDT disabled.
#define _WDT_OFF                0x3FF7  // WDT disabled.
#define _WDTE_ON                0x3FFF  // WDT enabled.
#define _WDT_ON                 0x3FFF  // WDT enabled.
#define _PWRTE_ON               0x3FEF  // PWRT enabled.
#define _PWRTE_OFF              0x3FFF  // PWRT disabled.
#define _CP_ALL                 0x009F  // All memory is code protected.
#define _CP_75                  0x15BF  // 0200h-07FEh code protected.
#define _CP_50                  0x2ADF  // 0400h-07FEh code protected.
#define _CP_OFF                 0x3FFF  // Code protection off.
#define _MCLRE_OFF              0x3F7F  // Internal.
#define _MCLRE_ON               0x3FFF  // External.

//==============================================================================

#define _IDLOC0                 0x2000
#define _IDLOC1                 0x2001
#define _IDLOC2                 0x2002
#define _IDLOC3                 0x2003

//==============================================================================

#ifndef NO_BIT_DEFINES

#define ADON                    ADCON0bits.ADON                 // bit 0
#define GO_NOT_DONE             ADCON0bits.GO_NOT_DONE          // bit 2, shadows bit in ADCON0bits
#define GO                      ADCON0bits.GO                   // bit 2, shadows bit in ADCON0bits
#define NOT_DONE                ADCON0bits.NOT_DONE             // bit 2, shadows bit in ADCON0bits
#define GO_DONE                 ADCON0bits.GO_DONE              // bit 2, shadows bit in ADCON0bits
#define CHS0                    ADCON0bits.CHS0                 // bit 3
#define CHS1                    ADCON0bits.CHS1                 // bit 4
#define ADCS0                   ADCON0bits.ADCS0                // bit 6
#define ADCS1                   ADCON0bits.ADCS1                // bit 7

#define PCFG0                   ADCON1bits.PCFG0                // bit 0
#define PCFG1                   ADCON1bits.PCFG1                // bit 1
#define PCFG2                   ADCON1bits.PCFG2                // bit 2

#define GP0                     GPIObits.GP0                    // bit 0
#define GP1                     GPIObits.GP1                    // bit 1
#define GP2                     GPIObits.GP2                    // bit 2
#define GP3                     GPIObits.GP3                    // bit 3
#define GP4                     GPIObits.GP4                    // bit 4
#define GP5                     GPIObits.GP5                    // bit 5
#define LINRX                   GPIObits.LINRX                  // bit 6
#define LINTX                   GPIObits.LINTX                  // bit 7

#define GPIF                    INTCONbits.GPIF                 // bit 0
#define INTF                    INTCONbits.INTF                 // bit 1
#define T0IF                    INTCONbits.T0IF                 // bit 2, shadows bit in INTCONbits
#define TMR0IF                  INTCONbits.TMR0IF               // bit 2, shadows bit in INTCONbits
#define GPIE                    INTCONbits.GPIE                 // bit 3
#define INTE                    INTCONbits.INTE                 // bit 4
#define T0IE                    INTCONbits.T0IE                 // bit 5, shadows bit in INTCONbits
#define TMR0IE                  INTCONbits.TMR0IE               // bit 5, shadows bit in INTCONbits
#define PEIE                    INTCONbits.PEIE                 // bit 6
#define GIE                     INTCONbits.GIE                  // bit 7

#define PS0                     OPTION_REGbits.PS0              // bit 0
#define PS1                     OPTION_REGbits.PS1              // bit 1
#define PS2                     OPTION_REGbits.PS2              // bit 2
#define PSA                     OPTION_REGbits.PSA              // bit 3
#define T0SE                    OPTION_REGbits.T0SE             // bit 4
#define T0CS                    OPTION_REGbits.T0CS             // bit 5
#define INTEDG                  OPTION_REGbits.INTEDG           // bit 6
#define NOT_GPPU                OPTION_REGbits.NOT_GPPU         // bit 7

#define CALSLW                  OSCCALbits.CALSLW               // bit 2
#define CALFST                  OSCCALbits.CALFST               // bit 3
#define CAL0                    OSCCALbits.CAL0                 // bit 4
#define CAL1                    OSCCALbits.CAL1                 // bit 5
#define CAL2                    OSCCALbits.CAL2                 // bit 6
#define CAL3                    OSCCALbits.CAL3                 // bit 7

#define NOT_POR                 PCONbits.NOT_POR                // bit 1

#define ADIE                    PIE1bits.ADIE                   // bit 6

#define ADIF                    PIR1bits.ADIF                   // bit 6

#define TRIS0                   TRISbits.TRIS0                  // bit 0
#define TRIS1                   TRISbits.TRIS1                  // bit 1
#define TRIS2                   TRISbits.TRIS2                  // bit 2
#define TRIS3                   TRISbits.TRIS3                  // bit 3
#define TRIS4                   TRISbits.TRIS4                  // bit 4
#define TRIS5                   TRISbits.TRIS5                  // bit 5

#endif // #ifndef NO_BIT_DEFINES

#endif // #ifndef __PIC16C433_H__