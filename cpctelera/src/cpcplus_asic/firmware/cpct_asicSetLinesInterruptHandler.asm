
;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2019 Arnaud Bouche (@Arnaud)
;;  Copyright (C) 2019 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------
.module cpct_asic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_asicSetLinesInterruptHandler
;;
;;    Define lines raster interrupt with a user provided function as new interrupt handler.
;;
;; C Definition:
;;    void <cpct_asicSetLinesInterruptHandler> ( void (*intHandler)(u8 line), <u8*> *lines_interrupt*, <u16> *nb_lines*) __z88dk_callee
;;
;; Input Parameters (2 Bytes):
;;   (2B BC) intHandler      - A pointer to the function that will handle interrupts from now on
;;   (2B HL) lines_interrupt - Array with the line number (1..200) where the interruptions will occured
;;   (1B A)  nb_lines        - Size of the array
;; 
;; Assembly call:
;;    > call cpct_asicSetLinesInterruptHandler_asm
;;
;; Parameter Restrictions:
;;    * *intHandler* (HL) can theoretically be any 16-bit value. However, it must point to 
;; the start of a function that will be called at each interrupt. If it points to somewhere else, 
;; undefined behaviour will happen. Most probably, the program will crash as random code will 
;; be executed (that placed at the provided address). User defined function (*intHandler*)
;; must not return any value and have *u8 line* parameters to indicate on which line the interrupt occurs.
;; * *lines_interrupt* Define all raster lines number (1..200) where the interrupter handler will be executed.
;; A value of 0 will reset the interrupt to default 300hz.
;; * *nb_lines* Size of the array corresponding of number of raster lines interrupt
;;
;; Details:
;;    Adapted from *cpct_setInterruptHandler* see for more informations
;;
;;    It modifies the interrupt vector to establish a new interrupt handler that calls
;; user provided function. The user must provide a pointer to the function (*intHandler*) 
;; that will handle interrupts. This function does not call *intHandler* or check it
;; in any way. It just sets it for being called at the next interrupts. Provided *intHandler*
;; function must not return any value and have *u8 line* parameters to indicate on which line the interrupt occurs.
;;
;;    This function creates wrapper code to safely call user provided *intHandler*. This
;; code saves registers on the stack (AF, BC, DE, HL and IX) and restores them after 
;; user code from *intHandler* finishes. Therefore, user does not have to worry about
;; saving registers. However, *be very careful if you modify the alternate set of 
;; registers* (AF', BC', DE', HL') as they will not be saved by default. User is 
;; responsible for saving and restoring the values on the alternate register set
;; whenever they are modified. Otherwise, behaviour is undefined when returning from 
;; the function.
;;
;; Destroyed Register values: 
;;    A, BC, DE, HL
;;
;; Required memory:
;;    C-binding   - 82 bytes (6 C-binding + 17 bytes function + 59 bytes for safe interrupt wrapper code)
;;    ASM-binding - 76 bytes (17 bytes function + 59 bytes for safe interrupt wrapper code)
;;    
;; Time Measures:
;;  * This first measure is the time required for cpct_asicSetLinesInterruptHandler to 
;; execute: that is, the time for setting up the hook for the system to call
;; user defined code and store interrupt array informations.
;; (start code)
;; Case       | microSecs (us) | CPU Cycles
;; -----------------------------------------
;; Any        |      70        |    280
;; Asm saving |     -17        |    -68
;; -----------------------------------------
   
;; (end code)
;;  * This second measure is the time overhead required for safely calling user defined function. 
;; That is, time required by the wrapper code to save registers and read the current line interrupt to set, 
;; call user's *intHandler*, program the next interrupt line and restoring the registers and returning.
;; This overhead is to be assumed each time interrupt handler is called, before the user's *intHandler* call.
;; (start code)
;; Overhead         | microSecs (us) | CPU Cycles
;; ------------------------------------------------
;; Before call      |      34        |    136
;; In total         |      88        |    352
;; In total (reset) |      95        |    380
;; ------------------------------------------------
;;    - Before call: Overhead time that occurs since interrupt is produced until save registers and call 
;;      to user-defined interrupt-handler takes place (including call instruction time)
;;    - In total: Total time the wrapper adds as overhead to the call to the user interrupt handler. This
;;      is the general case, when no reset is required.
;;    - In total (reset): Same as 'In total', but requiring the reset of the interrupt array sequence. This
;;      includes reseting counters and pointers to start issuing interrupt raster lines from the first one.
;; (end code)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.equ firmware_RST_jp, 0x38    ;; Memory address were a jump (jp) to the firmware code is stored.
.equ GA_port_byte,    0x7F    ;; 8-bit Port of the Gate Array
.equ byte_ph,         0x00    ;; Byte-sized placeholder
.equ word_ph,         0x0000  ;; Word-sized placeholder
.equ JP_opcode,       0xC3    ;; Opcode for JP instruction

   ld (safeInterruptHandlerCall), bc           ;; [6] Place the pointer to the user interrupt handler function
   ld (total_raslines), a                      ;; [4] Store size of array of lines interrupt
   ld (remaining_rasline_counter), a           ;; [4] And store the same value in the counter to initiate it with the total number of raster lines (it counts downwards)
   ld (raslines_array_ptr), hl                 ;; [5] Save the pointer to the start of the raster lines array
   ld (ptr_next_rasline_val), hl               ;; [5] And save same pointer as the pointer to the next raster line to be used by interrupts (the first)
   ld a, (hl)                                  ;; [2] A = First raster line number from array
   ld (next_rasline), a                        ;; [4] Save this rasterline number for the time when the interrupt occurs (it will be passed to user interrupt handler)
   
   ;; Modify interrupt vector to call save interrupt handler hook (code below)
   di                                          ;; [1] Disable interrupts  
   ld (#ASIC_RASTER_INT), a                    ;; [4] Setting the first interrupt line value
   ld  a, #JP_opcode                           ;; [2] 0xC3 = JP instruction, that may have been removed by other functions                                       
   ld (firmware_RST_jp), a                     ;; [4] Add JP at the start of interrupt vector's code
   ld hl, #cpct_asicSafeInterruptHandlerHook   ;; [3] HL = pointer to safe interrupt handler hook
   ld (firmware_RST_jp + 1), hl                ;; [5] Place interrupt handler hook pointer after JP in the interrupt vector's code
   ei                                          ;; [1] Reenable interrupts
   ret                                         ;; [3] Return
  
;; Counter of the remaining raster lines in this frame
remaining_rasline_counter: .db #byte_ph

;; Interrupt Handler Safe Wrapper Code. This is the code that
;; will be called at the start of the interrupt, and this code 
;; will call user defined function, after saving registers. It 
;; also returns using reti for user comfortability.
;;  Overhead: 106 microSecs
;;
cpct_asicSafeInterruptHandlerHook:
   di       ;; [1] Disable interrupts
   
   push  af ;; [4] /
   push  bc ;; [4] |  Save all 
   push  de ;; [4] |  standard registers 
   push  hl ;; [4] |  on the stack
   push  ix ;; [5] |
   push  iy ;; [5] \

   ;;
   ;; Call user Interrupt-Handler function
   ;;
   ;; BEWARE: Function called here must be defined __z88dk_fastcall 
   ;; if it is a C-function. Otherwise it will fail to retrieve parameter L
   ;;
next_rasline = .+1
   ld    l, #byte_ph          ;; [2] L = Next rasterline number
safeInterruptHandlerCall = .+1   
   call  #word_ph             ;; [5] Call Interrupt Handler (_z88dk_fastcall, it expects parameters in HL)

   ;;
   ;; Set up next raster interrupt line
   ;;
   ld    hl, #remaining_rasline_counter    ;; [3] HL Points to the remaining raster lines counter variable
   dec  (hl)                               ;; [2] --Remaining_raslines_counter
   jr    z, restore_raslines_counter       ;; [2/3] A==0 ? Then we have finished delivering all raster lines, restart again from first

   ;; A!=0 : There are still some raster line interrupts to be delivered
   ;; Point to next one and set variables for next call to this interrupt routine
ptr_next_rasline_val = .+1
   ld    hl, #word_ph                     ;; [3] HL Points to present item in the line-index array
   inc   hl                               ;; [2] HL points to next raster line value
   ld    a, (hl)                          ;; [2] A = Next ASIC raster line in which to launch an interrupt
   jr    exit                             ;; [3] Exit routine without restoring raster line counter
                                          ;; (This should only be done when no more raster lines are available on the array)
;;
;; Restore the raster line counter to restart issuing raster line interrupts
;; from the first one again. This must be called every time all raster line
;; interrupts have been launched to cicle them.
;;
restore_raslines_counter:
total_raslines = .+1
   ld   a, #byte_ph                       ;; [2] A = total number of raster line interrupts
   ld  (remaining_rasline_counter), a     ;; [4] Save this number for next interrupt call
raslines_array_ptr = .+1
   ld   hl, #word_ph                      ;; [3] HL = Pointer to the start of the raster lines array
   ld  (ptr_next_rasline_val), hl         ;; [5] Save this pointer for next interrupt call
   ld   a, (hl)                           ;; [2] A = first raster line number

exit:
   ;; Program next raster interrupt line
   ;;
   ld  (next_rasline), a                  ;; [4] Save next raster line number as parameter for next user-interrupt-handler call
   ld  (#ASIC_RASTER_INT), a              ;; [4] Program next raster interrupt line   
   ld  (ptr_next_rasline_val), hl         ;; [5] Save this pointer for next call

   pop  iy  ;; [4] / 
   pop  ix  ;; [4] | Restore all 
   pop  hl  ;; [3] | standard registers
   pop  de  ;; [3] | from the stack
   pop  bc  ;; [3] |
   pop  af  ;; [3] \
   
   ei       ;; [1] Reenable interrupts
   reti     ;; [3] Return to main program
