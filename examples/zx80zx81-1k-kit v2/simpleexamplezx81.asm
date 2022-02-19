; Example assembler program for ZX81 that maximaze the available usable space
; by Stefano Marago' 2018-2022

; to be compiled with fasmg

; compilation utils
include 'includes/ez80.inc' ; Z80 instructions
assume adl = 0 ; no ez80 extended instructions (but simple z80 ones)
include 'includes/fasmgutils.inc' ; listing etc.
include 'includes/z80optmc.inc' ; jrp pseudo instruction
include 'includes/romadd81.inc' ; rom addresses
include 'includes/charst81.inc' ; zx81 characters
include 'includes/tokens81.inc' ; basic tokens
include 'includes/pgmprefix.inc' ; system variables

;==========================================================================



maincycle: ; <- the program will start here! (assuming no return to basic)

    ld a,(LAST_K)
    inc a
    jrp nz,maincycle ; MACRO that is using JR if inside jump limits, else JP

gotkey:
    ld bc,(LAST_K)
    ld a,c
    inc a
    jr z,gotkey
    call DECODEKEY
    jr nc,gotkey
    ld a,(hl)

    ld (chardisplay),a

    jrp maincycle ; main loop


    ; VIDEO MEMORY
dfile: ; collapsed display
  db $76 ; needed to start
chardisplay: db _iX ; a single character spacekeeper
  db 24 dup($76) ; just end lines in this example program


maxstackavailable: ; ! <---
; after this label all code is used just to start the program



;==========================================================================

include 'includes/pgmsuffix.inc' ; program initialization routine
