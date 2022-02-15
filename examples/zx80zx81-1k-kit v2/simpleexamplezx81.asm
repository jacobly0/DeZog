; Example assembler program for ZX81 that maximaze the available usable space
; by Stefano Marago' 2018-2022

; to be compiled with fasmg

; compilation utils
include 'ez80.inc'       ; Z80 instructions
assume adl = 0           ; no ez80 extended instructions (but simple z80 ones)
include 'fasmgutils.inc' ; listing etc.
include 'z80optmc.inc'   ; jrp etc.
include 'romadd81.inc'
include 'charst81.inc'
include 'tokens81.inc'


org $4000
MEMORYSTART:
MEMORY1KEND equ $4400

; SYSVARS which aren't saved on file
ERR_NR  equ $4000         ; usable memory after asm program start!
FLAGS   equ $4001         ;    /
ERR_SP  equ $4002         ;   /
RAMTOP  equ $4004         ;  /
MODE    equ $4006         ; /
PPC     equ $4007         ;/

org $4009 ; .p org (start of saved content on cassette)
; SYSVARS which are saved on .p file
VERSN    db $01           ; usable
E_PPC    dw $01           ; usable
D_FILE   dw dfile         ; !! not usable (if fixed to $4100 first byte will be 00)
DF_CC    dw $0101         ; usable if not using rst 10h or similar
VARS     dw $0101         ; usable if not using basic vars
DEST     dw $0101         ; usable
E_LINE   dw eline         ; ? usable after asm start?
CH_ADD   dw line1a4       ; ? usable after asm start?
X_PTR    dw eline         ; ? usable after asm start?
STKBOT   dw eline         ; ? usable after asm start?
STKEND   dw eline         ; ? usable after asm start?
BERG     db 0             ; ? usable if not floating point usage?
MEM      dw line1a4       ; ? usable after asm start?
NOTUSED  db $01           ; one byte free!
DF_SZ    db $01 ;2        ; usable
S_TOP    dw $0101         ; usable
LAST_K:                   ; last char pressed (not usable if slow mode used)
 .row    db $FF           ; !!
 .column db $FF           ; !!
DB_ST    db $FF           ; !x probably not usable
MARGIN   db 55            ; !! not usable
NXTLIN   dw line1a4 - 4   ; xx autorun (=dfile for no autorun), usable after asm start
OLDPPC   dw $0101         ; usable
FLAGX    db $01           ; usable
STRLEN   dw $0101         ; usable
T_ADDR   dw $0101         ; xx usable after asm start
SEED     dw $0101         ; usable
FRAMES   db $FF,$FF       ; !! not usable
COORDS   db $01,$01       ; usable
PR_CC    db $01           ; usable
S_POSN   db $01,$01       ; usable
CDFLAG   db 01000000B     ; ?? usable after program start?

assert $ eq $403c ; let's see if rom sysvars are ending correctly!

;---
;PRTBUF   db 33 dup (0)
;MEMBOT   db 30 dup (0)    
;NOTUSED2 dw 2
;=> 65 bytes! fully usable




;================================================================
;================================================================
;================================================================
; here is the usable space!...

maincycle:

    ld a,(LAST_K)
    inc a
    jr nz,maincycle

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
  db 24 dup($76) ; end lines
  db $76 ; needed to finish

; here is the usable space!...
;================================================================
;================================================================
;================================================================




maxstackavailable: ; ! <---
; after this label all code is used just to start the program
; (or in the initial phases if more stack needed later...)
  
;================================================================

system_init:

  ;if ~ VERYEXTREMESMALL
      ld sp,MEMORY1KEND ; stack will start from end of memory ($4400 = 1k end)
                        ; (will never use basic again)
                        ; +22 bytes more stack and for a 3 bytes instruction
                        ; (command should be run in fast mode for safety)
  ;end if

  ;optional (to move some data in the VARS area)
  ;---
  ; move data at $4000 address
  ;ld de,$4000
  ;ld hl,offset_vector ; where from
  ;ld bc,8 ; how many bytes
  ;ldir

  ; here more init and initial data
  ; ....

    jrp maincycle ; then let's start

;================================================================

    ; this basic instruction are re-usable after program start (e.g. putting stack here or other asm variables)! 
    ; avoiding using BASIC functions (e.g. VAL) will use less stack to start (and anyway will never return!)

    ; db $00,$53 ; line number (big endian)
    ; dw line1end-$-2 ; line length (little endian)
    ; commenting line numbers above take line number (quite ok) and lenght(attention!) from previous bytes
    
line1a4: ; AUTORUN here - 4 (line number and length are fictitious, "almost" every value will fit)
    db $F9,$D4 ; RAND USR
    ; then "minimal" FP notation to indicate starting point
    db $1c,$7e ; NR + FP indicator
    db $8f ; exp fixed for the 1k range
    STARTING_ADDRESS = system_init ; <- CHANGE HERE THE STARTING ADDRESS (moveable expression) <-
    MANTISSA1 = (STARTING_ADDRESS-16384)/128 ; note: only quotient is given back by FASMG
    db MANTISSA1
    db (STARTING_ADDRESS-16384)*2-MANTISSA1*256
    ; explanations: http://www.users.waitrose.com/~thunor/mmcoyzx81/chapter17.html
    ;               https://gzuliani.bitbucket.io/sinclair/scacchi-1k.html
    
    ; Note: there are certain restrictions on USR routines:
    ; 1. if program returns to BASIC, the iy & i registers must have the values 4000h & 1Eh
    ; 2. in SLOW MODE do not modify the a', f', ix, iy & r registers (not even read the af' pair)
    ; 3. in FAST MODE all possible
line1end:

vars2:
    db $80 ; end of vars flag
end_vars:

eline: ; edit line temporary area

endoftape: ;-- End of ".o" or ".p" -----------------

;================================================================

total_lenght = $ - MEMORYSTART
displayindecimal "Total lenght", total_lenght
assert total_lenght <= 958 ; 958-9 = 949 .p payload MAX (all included) that seems allowed by _standard_ BASIC loader!

;================================================================
