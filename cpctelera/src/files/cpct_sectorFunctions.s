;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128) 
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
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

.module cpct_dsk

.equ sector_nb_sector_by_track, 10 ;; Define constant: 10 sectors per track
.equ sector_id_sector_first, 0xc1  ;; Define constant: ID of the first sector (#0xc1)

;; ASM cpct_sector_read function
cpct_sector_read_asm::
    ld   a, b                      ;; [1] Get drive number from B register
    ld  (current_drive), a         ;; [4] Save the drive number into RAM variable 
    ld  (sector_read_buffer + 1), hl ;; [4] SMC: Write destination buffer pointer into code
    ld   a, d                      ;; [1] Copy sector ID to register A
    ld  (sector_read_sector + 1), a ;; [4] SMC: Write sector ID into code
    ld   a, e                      ;; [1] Copy track ID to register A
    ld  (sector_read_track + 1), a  ;; [4] SMC: Write track ID into code
    ld   a, c                      ;; [1] Copy number of sectors to register A
    ld  (sector_read_nb_sectors + 1), a ;; [4] SMC: Write sector count into code

    call sector_read_prg           ;; [5] Call the main read execution loop
    ret                            ;; [3] Return to caller

;; ASM cpct_sector_write function
cpct_sector_write_asm::
    ld   a, b                      ;; [1] Get drive number from B register
    ld  (current_drive), a         ;; [4] Save the drive number into RAM variable 
    ld  (sector_write_buffer + 1), hl ;; [4] SMC: Write source buffer pointer into code
    ld   a, d                      ;; [1] Copy sector ID to register A
    ld  (sector_write_sector + 1), a ;; [4] SMC: Write sector ID into code
    ld   a, e                      ;; [1] Copy track ID to register A
    ld  (sector_write_track + 1), a  ;; [4] SMC: Write track ID into code
    ld   a, c                      ;; [1] Copy number of sectors to register A
    ld  (sector_write_nb_sectors + 1), a ;; [4] SMC: Write sector count into code

    call sector_write_prg          ;; [5] Call the main write execution loop
    ret                            ;; [3] Return to caller

sector_read_prg:
    di                             ;; [1] Disable interrupts to guarantee precise FDC timing
    ld   a, (current_drive)        ;; [4] Load chosen drive ID from memory
    ld  (sector_msgreadst3 + 2), a ;; [4] Modify drive parameter in "read st3" command
    ld  (sector_msgmovetrack + 2), a ;; [4] Modify drive parameter in "move track" command
    ld  (sector_msgreadsect + 2), a ;; [4] Modify drive parameter in "read sector" command
    ld   a, #2                     ;; [2] Size code 2 equals 512 bytes per sector
    ld  (sector_msgreadsect + 6), a ;; [4] Set sector size parameter in FDC command
    call sector_startdrive         ;; [5] Turn on the floppy drive motor
sector_read_buffer:
    ld   hl, #00000                ;; [3] Target buffer address (Overwritten by SMC)
sector_read_track:
    ld   d, #00                    ;; [2] Target track index (Overwritten by SMC)
sector_read_nb_sectors:
    ld   b, #00                    ;; [2] Total remaining sectors to read (Overwritten by SMC)
sector_read_sector:
    ld   c, #00                    ;; [2] Current physical sector ID (Overwritten by SMC)
sector_readt2_2:
    push bc                        ;; [3] Save remaining sectors and current sector ID
    ld   a, b                      ;; [1] Load remaining sectors count into A
    cp   #sector_nb_sector_by_track ;; [2] Compare with total track capacity (10)
    jr   nc, sector_readt2_3       ;; [3/2] If more than 10 sectors left, jump to track cap
    ld   a, c                      ;; [1] Load current sector ID
    add  a, b                      ;; [1] Compute ending sector ID
    dec  a                         ;; [1] Adjust end boundary index
    cp   #0xcb                     ;; [2] Check if it exceeds maximum track sector limit
    jr   c, sector_readt2_4        ;; [3/2] If valid, proceed to read sectors
sector_readt2_3:
    ld   a, #0xca                  ;; [2] Cap the end sector to the last sector of the track
sector_readt2_4:
    push hl                        ;; [3] Save destination memory buffer pointer
    call sector_readsect           ;; [5] Execute physical sector reading command
    pop  bc                        ;; [3] Restore previous HL state into BC (dirty trick)
    ld   a, (sector_st0)           ;; [4] Read FDC Status Register 0
    and  #0x98                     ;; [2] Mask critical error bits
    jr   nz, sector_error          ;; [3/2] Jump to error handling if any bit is active
    ld   a, (sector_st1)           ;; [4] Read FDC Status Register 1
    and  #0x37                     ;; [2] Mask data/ID errors
    jr   nz, sector_error          ;; [3/2] Jump to error handling if error found
    ld   a, (sector_st2)           ;; [4] Read FDC Status Register 2
    and  #0x30                     ;; [2] Mask data consistency errors
    jr   nz, sector_error          ;; [3/2] Jump to error handling if error found
    ld   a, h                      ;; [1] Load high byte of updated buffer pointer
    sub  b                         ;; [1] Calculate differential bytes read
    sra  a                         ;; [2] Shift right to convert bytes to sectors (/512)
    pop  bc                        ;; [3] Restore real original BC state
    inc  d                         ;; [1] Step forward to the next disk track
    ld   c, #sector_id_sector_first ;; [2] Reset sector ID to the first one (#0xc1)
    sub  b                         ;; [1] Subtract processed sectors from remaining total
    neg                            ;; [2] Negate to get remaining sectors absolute value
    ld   b, a                      ;; [1] Update remaining sectors counter in B
    jr   nz, sector_readt2_2       ;; [3/2] Loop back if there are more sectors to read
    jr   sector_stopdrive          ;; [3] Turn off motor and finish execution cleanly

sector_write_prg:
    di                             ;; [1] Disable interrupts to protect timing-critical FDC execution
    ld   a, (current_drive)        ;; [4] Load active drive index from memory
    ld  (sector_msgreadst3 + 2), a ;; [4] Modify drive byte in "read st3" command string
    ld  (sector_msgmovetrack + 2), a ;; [4] Modify drive byte in "move track" command string
    ld  (sector_msgwritesect + 2), a ;; [4] Modify drive byte in "write sector" command string
    ld   a, #2                     ;; [2] Size code 2 equals 512 bytes per sector
    ld  (sector_msgwritesect + 6), a ;; [4] Set sector size parameter in write command
    call  sector_startdrive        ;; [5] Turn on the floppy drive motor
sector_write_buffer:     
    ld   hl, #0x0000               ;; [3] Source buffer address (Overwritten by SMC)
sector_write_track:      
    ld   d, #00                    ;; [2] Target track index (Overwritten by SMC)
sector_write_nb_sectors: 
    ld   b, #00                    ;; [2] Total remaining sectors to write (Overwritten by SMC)
sector_write_sector:     
    ld   c, #0x00                  ;; [2] Current physical sector ID (Overwritten by SMC)
sector_writet2_2:
    push bc                        ;; [3] Save remaining sectors and current sector ID
    ld   a, b                      ;; [1] Load remaining sectors count into A
    cp   #sector_nb_sector_by_track ;; [2] Compare with track capacity (10)
    jr   nc, sector_writet2_3      ;; [3/2] If writing more than a track, cap the target
    ld   a, c                      ;; [1] Load current sector ID
    add  a, b                      ;; [1] Calculate ending sector index
    dec  a                         ;; [1] Adjust end boundary
    cp   #0xcb                     ;; [2] Check if within valid track range
    jr   c, sector_writet2_4       ;; [3/2] If safe, proceed to write execution
sector_writet2_3:
    ld   a, #0xca                  ;; [2] Cap the end sector ID to track limit
sector_writet2_4:
    push hl                        ;; [3] Save source memory buffer pointer
    call sector_writesect          ;; [5] Execute physical sector writing command
    pop  bc                        ;; [3] Restore previous HL state into BC
    ld   a, (sector_st0)           ;; [4] Read FDC Status Register 0
    and  #0x98                     ;; [2] Check for critical execution errors
    jr   nz, sector_error          ;; [3/2] Branch to error handler on failure
    ld   a, (sector_st1)           ;; [4] Read FDC Status Register 1
    and  #0x37                     ;; [2] Check for hardware/media write errors
    jr   nz, sector_error          ;; [3/2] Branch to error handler on failure
    ld   a, (sector_st2)           ;; [4] Read FDC Status Register 2
    and  #0x30                     ;; [2] Check for data flow errors
    jr   nz, sector_error          ;; [3/2] Branch to error handler on failure
    ld   a, h                      ;; [1] Load high byte of updated buffer pointer
    sub  b                         ;; [1] Calculate differential bytes written
    sra  a                         ;; [2] Shift right to calculate written sector count
    pop  bc                        ;; [3] Restore actual remaining counters
    inc  d                         ;; [1] Step to next physical disk track
    ld   c, #sector_id_sector_first ;; [2] Reset sector target to first sector (#0xc1)
    sub  b                         ;; [1] Compute remaining count delta
    neg                            ;; [2] Negate to turn into positive balance
    ld   b, a                      ;; [1] Update remaining loop counter in B
    jr   nz, sector_writet2_2      ;; [3/2] Re-loop if additional sectors need writing
    jr   sector_stopdrive          ;; [3] Turn off motor and exit cleanly

sector_stopdrive:
    ld   bc, #0xfa7e               ;; [3] Port address for FDC Motor Control
    out (c), c                     ;; [3] Send command to turn off drive motor
    ei                             ;; [1] Re-enable system interrupts
    ret                            ;; [3] Return to caller

sector_error:
    pop  bc                        ;; [3] Clean up saved parameters from stack
    scf                            ;; [1] Set Carry Flag to notify error state to caller
    jr   sector_stopdrive          ;; [3] Stop motor and return

sector_startdrive:
    ld   bc, #0xfa7e               ;; [3] Port address for FDC Motor Control
    ld   a, #1                     ;; [2] Command value 1: turn motor ON
    out (c), a                     ;; [3] Write value to motor port
    inc  b                         ;; [1] Increment BC to point to status port (#0xfb7e)
sector_waitready:
    ld   hl, #sector_msgreadst3    ;; [3] Point to "read st3" command data block
    call sector_outdisc            ;; [5] Send the command bytes to the FDC
    call sector_indisc             ;; [5] Read status results back from FDC
    ld   a, (sector_st0)           ;; [4] Load updated Status Register 0 content
    and  #0x20                     ;; [2] Check bit 5 (Drive Ready Signal)
    jr   z, sector_waitready       ;; [3/2] Keep polling until the drive is fully ready
    ret                            ;; [3] Return to caller

sector_readsect:
    push hl                        ;; [3] Save destination buffer address
    ld  (sector_msgreadsect+7), a  ;; [4] Set dynamic end sector parameter
    ld   a, c                      ;; [1] Get current starting sector
    ld  (sector_msgreadsect+5), a  ;; [4] Set dynamic start sector parameter
    ld   a, d                      ;; [1] Get target track index
    ld  (sector_msgmovetrack+3), a ;; [4] Set track parameter in move command
    ld  (sector_msgreadsect+3), a  ;; [4] Set track parameter in read command
    ld   bc, #0xfb7e               ;; [3] Main FDC data port address
    ld   hl, #sector_msgmovetrack  ;; [3] Point to FDC "move track" structure
    call sector_outdisc            ;; [5] Write command sequence to FDC
sector_test_head_rd:
    in   a, (c)                    ;; [3] Sample FDC Main Status Register
    jp   p, sector_test_head_rd    ;; [3] Wait until Request for Master (RQM) bit goes active
sector_head_ok_rd:
    ld   hl, #sector_msgreadst0    ;; [3] Command block to request Status Register 0
    call sector_outdisc            ;; [5] Transmit query to FDC
    call sector_indisc             ;; [5] Receive data bytes from FDC
    ld   a, (sector_st0)           ;; [4] Load Status Register 0 byte
    bit  5, a                      ;; [2] Check Seek End bit (Head calibration confirmation)
    jr   z, sector_head_ok_rd      ;; [3/2] If seek not completed, re-check
    ld   hl, #sector_msgreadsect   ;; [3] Point to main "read sector" data command
    call sector_outdisc            ;; [5] Transmit reading command packet to FDC
    pop  hl                        ;; [3] Restore raw memory pointer for storage
sector_rdsect:
    in   a, (c)                    ;; [3] Sample FDC Main Status Register
    jp   p, sector_rdsect          ;; [3] Loop until FDC is ready to transfer data
    and  #0x20                     ;; [2] Check if execution phase is ongoing
    jr   z, sector_rdsect_end      ;; [3/2] If execution bit drops, transfer is done
    inc  c                         ;; [1] Target next port address byte part
    ini                            ;; [4] Stream byte from FDC port into (HL), increment HL
    inc  b                         ;; [1] Reset B counter updated by INI
    dec  c                         ;; [1] Re-align port address channel
    jr   sector_rdsect             ;; [3] Repeat until entire sector payload is copied
sector_rdsect_end:
    push hl                        ;; [3] Preserve updated memory pointer
    call sector_indisc             ;; [5] Pull trailing status bytes from FDC to clear phase
    pop  hl                        ;; [3] Restore current memory pointer
    ret                            ;; [3] Return to sequence manager

sector_writesect:
    push hl                        ;; [3] Save source buffer address
    ld  (sector_msgwritesect + 7), a ;; [4] Set dynamic end sector target parameter
    ld   a, c                      ;; [1] Get current starting sector
    ld  (sector_msgwritesect + 5), a ;; [4] Set dynamic start sector target parameter
    ld   a, d                      ;; [1] Get target track index
    ld  (sector_msgmovetrack + 3), a ;; [4] Set track parameter in move command
    ld  (sector_msgwritesect + 3), a ;; [4] Set track parameter in write command
    ld   bc, #0xfb7e               ;; [3] Main FDC data port address
    ld   hl, #sector_msgmovetrack  ;; [3] Point to FDC "move track" structure
    call sector_outdisc            ;; [5] Write command sequence to FDC
sector_test_headwr:
    in   a, (c)                    ;; [3] Check FDC Main Status Register
    jp   p, sector_test_headwr     ;; [3] Wait until FDC is ready for transmission
sector_head_okwr:
    ld   hl, #sector_msgreadst0    ;; [3] Command block to check Status Register 0
    call sector_outdisc            ;; [5] Send command packet
    call sector_indisc             ;; [5] Fetch internal execution status
    ld   a, (sector_st0)           ;; [4] Read updated Status Register 0
    bit  5, a                      ;; [2] Verify Seek End status bit
    jr   z, sector_head_okwr       ;; [3/2] Retry tracking check if not ready
    ld   hl, #sector_msgwritesect  ;; [3] Point to main "write sector" instruction block
    call sector_outdisc            ;; [5] Commit write operation packet to controller
    pop  hl                        ;; [3] Restore raw source data block pointer
sector_wrsect:
    in   a, (c)                    ;; [3] Check FDC Main Status Register
    jp   p, sector_wrsect          ;; [3] Wait until hardware request bit clears
    and  #0x20                     ;; [2] Is execution phase still active?
    jr   z, sector_wrsect_end      ;; [3/2] If execution phase finishes, close write pipe
    inc  c                         ;; [1] Adjust port address pointer
    inc  b                         ;; [1] Pre-increment B counter for OUTI safety
    outi                           ;; [4] Output data byte from (HL) to port, increment HL
    dec  c                         ;; [1] Restore original port baseline
    jr   sector_wrsect             ;; [3] Loop until all data written
sector_wrsect_end:
    push hl                        ;; [3] Save data block index reference
    call sector_indisc             ;; [5] Read status results from FDC to end operation
    pop  hl                        ;; [3] Restore current data block index reference
    ret                            ;; [3] Return to caller

sector_indisc:
    ld  hl, #sector_st0            ;; [3] Target RAM address to store FDC status bytes
sector_ind1:
    in  a,(c)                      ;; [3] Read FDC Main Status Register
    add a, a                       ;; [1] Shift bit 7 (RQM) into Carry
    jr  nc, sector_ind1            ;; [3/2] Wait until RQM is active (1)
    add a, a                       ;; [1] Shift bit 6 (DIO) into Carry
    ret nc                         ;; [3/2] If DIO is 0, FDC expects data (End of Result Phase)
    inc c                          ;; [1] Point to FDC Data Register
    ini                            ;; [4] Read byte from FDC into (HL), increment HL
    inc b                          ;; [1] Balance B register modification from INI
    dec c                          ;; [1] Point back to FDC Status Register
    jr  sector_ind1                ;; [3] Loop for next result bytes

sector_outdisc:
    ld  e, (hl)                    ;; [2] Load number of command bytes to transmit
    inc hl                         ;; [1] Point to the first command byte
sector_outdiscready:
    in  a, (c)                     ;; [3] Read FDC Main Status Register
    add a, a                       ;; [1] Shift bit 7 (RQM) into Carry
    jr  nc, sector_outdiscready    ;; [3/2] Loop until FDC is ready
    add a, a                       ;; [1] Shift bit 6 (DIO) into Carry
    ret c                          ;; [3/2] If DIO is 1, FDC wants to send data (Abort command)
    inc c                          ;; [1] Point to FDC Data Register
    inc b                          ;; [1] Pre-bias B for OUTI command logic
    outi                           ;; [4] Write command byte from (HL) to FDC, increment HL
    dec c                          ;; [1] Point back to FDC Status Register
    ld  a, #10                     ;; [2] Set up small delay loop counter
sector_outd2:
    dec a                          ;; [1] Decrement delay counter
    jr  nz, sector_outd2           ;; [3/2] Wait loop to let the hardware process the byte
    dec e                          ;; [1] Decrement remaining command bytes counter
    jr  nz, sector_outdiscready    ;; [3/2] Continue sending if bytes remain
    ret                            ;; [3] Return from command transmission

current_drive:
    .db 0                          ;; Selected Drive Storage (0 = Drive A, 1 = Drive B)

sector_msgreadst3:
    .db 2,0x04,0x00                ;; FDC structure: length, command code, drive parameter

sector_msgmovetrack:
    .db 3,0x0f,0x00,0x00           ;; FDC structure: length, command code, drive, track

sector_msgreadst0:
    .db 1,8                        ;; FDC structure: length, command code

sector_msgreadsect:
    .db 9,0x46,0x00,0x00,0x00,0x00,0x00,0x00,0x2a,0xff ;; FDC read sector parameter pack
    
sector_msgwritesect:
    .db 9,0x45,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x00 ;; FDC write sector parameter pack

;; status fdc (7 bytes read in status phase)
sector_st0:      .db 0             ;; Status Register 0
sector_st1:      .db 0             ;; Status Register 1
sector_st2:      .db 0             ;; Status Register 2
sector_cylinder: .db 0             ;; Current Cylinder/Track ID
sector_head:     .db 0             ;; Current Head ID
sector_sector:   .db 0             ;; Current Sector ID
sector_size:     .db 0             ;; Sector Size code