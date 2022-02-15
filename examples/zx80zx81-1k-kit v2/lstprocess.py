#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
Transform a custom fasmg lst output in a "DeZog" list compatible to the current available assembler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Usage: fasmgez80processlst <src.lst> <dest.list> <mainFile.asm>
 Note: for safety <dest.list> is not overwritten
"""
import sys
import os
import re
import string  

"""
    DeZog recognized format:
    1. one single list file is used to specify multiple sources (included) and the source file name is being gathered by DeZog from the comment line "# file opened:"
    2. the format is using fixed lenght fields in this way:
      a. 4 chars: line number
      b. 3 chars: "+" for includes or "++" for includes of includes, etc, else spaces
      c: 4 chars: exadecimal address
      d: 14 chars: compiled code
      e: source text long as required (newline terminated)
"""
     
# Function checks if input string has only hexdigits or not  
def checkhex(value):  
    for letter in value:  
        if letter not in string.hexdigits:  
            return False
    return True
    
def main():

    if False: # for debugging
        # Check and retrieve command-line arguments
        if len(sys.argv) != 4:
            print(__doc__)
            sys.exit(1)   # Return a non-zero value to indicate abnormal termination
        fileIn  = sys.argv[1]
        fileOut = sys.argv[2]
        mainFile = sys.argv[3]
    else:
        fileIn  = "simpleexamplezx81.lst"
        fileOut = "simpleexamplezx81.list"
        mainFile = "simpleexamplezx81.asm"

    currentFilename = [""]*10

    # Verify source file
    if not os.path.isfile(fileIn):
        print("error: {} does not exist".format(fileIn))
        sys.exit(1)

    if os.path.isfile(fileOut):
        print("error: {} already exist".format(fileOut))
        sys.exit(1)
       # print("{} exists. Override (y/n)?".format(fileOut))
       # reply = input().strip().lower()
       # if reply[0] != 'y':
       #    sys.exit(1)

    # Process the file line-by-line
    with open(fileIn, 'r') as fpIn, open(fileOut, 'w') as fpOut:
        currentFilename[0]=mainFile
        currentFilenames=0
        status="Waiting for LISTING"
        fpOut.write("\n# file opened: {}".format(mainFile))
        for line in fpIn:
            line = line.rstrip()   # Strip trailing spaces and newline
            linetobewritten = False
            if status=="Waiting for LISTING":
                if line=="LISTING":
                    status = "Code"
            elif status=="Code":
                if line=="":
                    continue
                elif line.find("passes,")>0 and line.find("seconds")>0 and line.find("bytes.")>0:
                    status="End"
                elif checkhex(line[0:8]):
                    address = line[4:8]
                    filename, linenumber = line[10:line.find(")")].split(",")
                    codetext = line[line.find(":")+25:]
                    if filename!=currentFilename[currentFilenames]:
                        if currentFilenames==0:
                            fpOut.write("\n# file opened: {}".format(filename))
                            currentFilenames += 1
                            currentFilename[currentFilenames] = filename
                        elif currentFilenames>0 and filename==currentFilename[currentFilenames-1]:
                            fpOut.write("\n# file closed: {}".format(currentFilename[currentFilenames]))
                            currentFilenames -= 1
                        else:
                            # just one level of includes managed for now
                            fpOut.write("\n# file closed: {}".format(currentFilename[currentFilenames]))
                            fpOut.write("\n# file opened: {}".format(filename))
                            #currentFilenames += 1
                            currentFilename[currentFilenames] = filename
                    linetobewritten = True
                elif line[0:8].isspace():
                    # a continuation of a code line 
                    codetext = line[9+24:]
                    linetobewritten = True
                else:
                    print("unknown error in line reading")
                    sys.exit(1)
            if linetobewritten:
                codetext = codetext.strip()
                if codetext:
                    fpOut.write("\n{:>4}{:<3}{}              {}".format(linenumber, "+"*currentFilenames, address, codetext))


        fpOut.write("\n# file closed: {}\n".format(mainFile))

if __name__ == '__main__':
    main()
