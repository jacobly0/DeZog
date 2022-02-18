#!/bin/bash
./fasmg simpleexamplezx81.asm simpleexamplezx81.p > simpleexamplezx81.lst
python3 makesld.py simpleexamplezx81.lst simpleexamplezx81.sld simpleexamplezx81.sym
