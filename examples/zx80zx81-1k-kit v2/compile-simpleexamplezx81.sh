#!/bin/bash

./fasmg simpleexamplezx81.asm simpleexamplezx81.p > simpleexamplezx81.lst
php makesym.php simpleexamplezx81.lst > simpleexamplezx81.sym
rm simpleexamplezx81.list 2> /dev/null
python3 lstprocess.py simpleexamplezx81.lst simpleexamplezx81.list simpleexamplezx81.asm
read -p "press a key to run or break to stop" -n 1
zesarux --machine ZX81 --tape simpleexamplezx81.p --gui-style ZX80/81 --realvideo
