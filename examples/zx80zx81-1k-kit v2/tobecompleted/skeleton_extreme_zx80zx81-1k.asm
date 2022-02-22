; Skeleton for a ZX80/ZX81 that maximaze the available usable space
; by Stefano Marago' 2018-2022

; ZX81 program autoload the mainloop without losign space
; to autoload ZX80 programs some space cannot be used
; also there is the skeleton display routine for flicker free ZX80 management

; To be compiled with fasmg

; compilation utils
include 'ez80.inc'       ; Z80 instructions
assume adl = 0           ; no ez80 extended instructions (but simple z80 ones)
include 'fasmgutils.inc' ; listing etc.
include 'z80optmc.inc'   ; jrp etc.
; general useful definitions
if ROMPLATFORM eq "ZX81"
    include 'romadd81.inc'
    include 'charst81.inc'
    include 'tokens81.inc'
else
    include 'charst80.inc'
end if


org $4000
MEMORYSTART:
MEMORY1KEND equ $4400

if ROMPLATFORM eq "ZX80"

;==================================================================

;- SYSVARS --------------------

ERR_NR db $FF                 ;  4000 ERR_NR   Error Number (one less than report code)
FLAGS  db $04 ; 4 ; 0D ; 80   ;  4001 FLAGS    Various Flags to control BASIC System
                              ;                 7  1-Syntax off        0-Syntax on
                              ;                 6  1-Numeric result    0-String result
                              ;                 5  1-Evaluating function (not used)
                              ;                 3  1-K cursor          0-L cursor
                              ;                 2  1-K mode            0-L mode
                              ;                 0  1-No leading space  0-Leading space
;PPC    dw linenumber1 + $8000 ;  4002 PPC      Line number which is to be executed next (bit15: 1=stopped)
PPC    dw $FFFE               ;  4002 PPC      Line number which is to be executed next (bit15: 1=stopped)
P_PTR  dw end_vars ;+ 1       ;  4004 P_PTR    Position in RAM of [K] or [L] cursor
E_PPC  dw 0 ;linenumber1      ;  4006 E_PPC    Line Number of current line with [>] cursor (for LIST)
VARS   dw vars                ;  4008 VARS     Address of start of variables area (end of BASIC Program)
E_LINE dw end_vars ; =eline   ;  400A E_LINE   Address of start of Edit Line (end of VARS) (-save area end-)
D_FILE dw end_vars + 2        ;  400C D_FILE   Start of Display File (VRAM) (end of Edit Line/Input Buffer)
DF_EA  dw end_vars + 3        ;  400E DF_EA    Address of the start of lower screen
DF_END dw end_vars + 4        ;  4010 DF_END   Display File End
DF_SZ  db 2                   ;  4012 DF_SZ    Number of lines in lower screen
S_TOP  dw linenumber1 ;1 ;0   ;  4013 S_TOP    The number of first line on screen
X_PTR  dw 0                   ;  4015 X_PTR    Address of the character preceding the [S] marker
OLDPPC dw 0 ;linenumber1      ;  4017 OLDPPC   Line number to which CONTINUE jumps
FLAGX  db 0 ;$A0 ; 0          ;  4019 FLAGX    More flags.
                              ;                 7  1-K mode            0-L mode
                              ;                 6  1-Numeric result    0-String result
                              ;                 5  1-Inputting         0-Editing
T_ADDR dw $7a2 ; 7b0,780,79c  ;  401A T_ADDR   Address of next item in syntax table
SEED   dw 0                   ;  401C SEED     The seed for the random number
FRAMES dw $7484 ; whatever    ;  401E FRAMES   Count of frames shown since start-up (incrementing)
DEST   dw $ffff ; vaddr?      ;  4020 DEST     Address of variable in statement
;---                          ;  ---Active/Basic:                                ;  ---Pause/Input:
RESULT dw $ffff               ;  4022 RESULT   Value of the last expression      ;  4022 -         Keyboard debounce
                              ;                                                  ;  4023 MARGIN    Screen border height
S_POSN dw $1721               ;  4024 S_POSN_X Column number for print position  ;  4024           ?
                              ;  4025 S_POSN_Y Line number for print position    ;
CH_ADD dw $ffff ;end_vars+1   ;  4026 CH_ADD   BASIC program pointer (nxt token) ;  4026 LAST_K    Keyboard last key pressed (4026=row, 4027=column)
 
assert $ eq $4028 ; let's see if rom sysvars are ending correctly!

;------------------------------

; Basic program (user has to RUN it) 
    linenumber1=53
    db 0,linenumber1 ; line 1 number
    db $EF,$3A,$38,$37 ; RANDOMISE USR
    db $DA,$1D ; "(1" range $4xxx
    db (system_init/1000)-((system_init/10000)*10) +_c0; thousands
    db (system_init/100)-((system_init/1000)*10) +_c0; hundreds
    db (system_init/10)-((system_init/100)*10) +_c0; tens
    db system_init-((system_init/10)*10) +_c0; units
    db $D9 ; ")" 
    db $76 ; N/L
    ;
    ;vars = vars1
    ;vars1: db 86 ; A$... (more space efficient but should predict how code is moved...)
    ;
    db $76 ; EOL doubled to not visualize REM instruction (with $76...)
    vars = vars2
    db $03,$e8 ; line 2 number
    db $FE ; REM...

;==================================================================
;==================================================================

elseif ROMPLATFORM eq "ZX80-autorun"

; from Martin "no-cash" trick!

ERR_NR   db $01   ; usable!
FLAGS    db $01   ; usable!
PPC      dw $01   ; usable!
P_PTR    dw $01   ; usable!
E_PPC    dw $01   ; usable!

VARS     dw $402c ; usable after pgm start
E_LINE   dw $433d ; usable after pgm start

D_FILE   dw $01   ; usable if custom display routine!
DF_EA    dw $01   ; usable
DF_END   dw $01   ; usable
DF_SZ    db $01   ; usable
S_TOP    dw 0     ; must be 0 at load, usable after pgm start
X_PTR    dw $01   ; usable
OLDPPC   dw $01   ; usable
FLAGX    db $01   ; usable
T_ADDR   dw $01   ; usable
SEED     dw $01   ; usable
FRAMES   dw $01   ; will be INCREMENTED by display, not usable
DEST     dw $01   ; usable
RESULT   dw $01   ; usable
S_POSN_X db $01   ; usable
S_POSN_Y db $01   ; usable
CH_ADD:  dw $01   ; usable

    db $00,$53 ; usable probably up to 9999 decimal - will be line number (big endian!)

assert $ eq $4028+2 ; let's see if rom sysvars are ending correctly! (here plus linenumber)

    ld h,l
    db EOL
    
vars:
    db $80 ; end of vars (required for basic start!)
    
    db 19 dup (0) ; fillers
    
L4040:
    di
    jrp system_init
    
;==================================================================
;==================================================================

else ; "ZX81"

; SYSVARS which aren't saved on file

ERR_NR  equ $4000         ; usable memory after asm program start!
FLAGS   equ $4001         ;    /
ERR_SP  equ $4002         ;   /
RAMTOP  equ $4004         ;  /
MODE    equ $4006         ; /
PPC     equ $4007         ;/

;--------------------------

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

end if

;================================================================

maincycle:


;---------------------------
; here is the MAIN PROGRAM!
;---------------------------



if ZX80_flickerfree
    OUT  ($FF),A
    LD   C,$38  ; MARGIN_TOP equ $-1
    LD   A,$E8
    LD   B,$19  ; B=1 'row' for top border (of C=MARGIN_TOP lines), + 24 ($18) rows of 8 lines
    LD   HL,dfile+$8000
    CALL $01B0

    LD   C,$37 ; MARGIN_BOTTOM equ $-1
    ;DEC  C    ; c is still $38 but instruction is 4 instead of 7 T-States)
    ;RET  Z    ; Delay 5 T-states to achieve perfect timing
    ;AND (HL)  ; Delay 7 T-States (and still 1 bytes) -> 7+5 almost 4+7 and 1 byte less
    LD   A,$EB
    INC  B     ; B=1 'row' for bottom border (of C=MARGIN_BOTTOM lines)
    DEC  HL    ; ?
    CALL $01B0
    IN   A,($FE) ; avoidable if input keyboard...


    ; 1200 T-States available for PGM
    ; (important that are more or less EXACTLY 1200 since is the vertical retrace timing)
    ; .......
    
    ; keyboard in() as in the ZX81 ...
    
elseif ZX80_displayandwaitkey

    call $013f

else

    ; ZX81 (slow/fast)
    
    ; key in LAST_K

end if


; here usable space for everything
;.................


    jrp maincycle ; main loop
    ;------------
    

; VIDEO MEMORY
;-------------

dfile: ; collapsed display
  db $76 ; needed to start
  db 24 dup($76) ; lines
  db $76 ; needed to finish


; also here usable space!...
;.................


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

  ;optional (if there is an internal dfile to show after load)
  ;---
  ;if ROMPLATFORM eq "ZX80"
  ;    ld hl,dfile
  ;    ld (D_FILE),hl
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

if ROMPLATFORM eq "ZX81"

    ; this basic instruction are re-usable after program start (e.g. putting stack here or other asm variables)! 
    ; avoiding using BASIC functions (e.g. VAL) will use less stack to start (and anyway will never return!)

    ; db $00,$53 ; line number (big endian)
    ; dw line1end-$-2 ; line length (little endian)
    ; commenting line numbers above take line number (quite ok) and length(attention!) from previous bytes
    
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

end if

vars2:
    db $80 ; end of vars flag
end_vars:

eline: ; edit line temporary area

if ROMPLATFORM eq "ZX80-autorun"
  db 0x433d-$ dup (0)
  ; length is important (should be $xx3d)
  assert $ = 0x433d
end if

endoftape: ;-- End of ".o" or ".p" -----------------

;================================================================

total_length = $ - MEMORYSTART
repeat 1, stringify: total_length
    display "Total length: ", `stringify, 10
end repeat
assert total_length <= 958 ; 958-9 = 949 .p payload MAX (all included) that seems allowed by _standard_ BASIC loader!

;================================================================

