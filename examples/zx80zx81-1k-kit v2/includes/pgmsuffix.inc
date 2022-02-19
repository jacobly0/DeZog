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
