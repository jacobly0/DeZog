                SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
                DEVICE ZXSPECTRUM48
 
Code_Start:     EQU 0x8000
                ORG Code_Start
                EI              ; Optional, if you require interrupts to be enabled on start
 
                include "demo_scroll.z80"
 
                SAVESNA "sample.sna", Code_Start
