
;====================================================

macro displayindecimal descr,value
    repeat 1, d:value
        display descr,`d
    end repeat
end macro

;macro displayinhex ....


;----------------------------------------------------

define Listing

define ldisplay 13,10,10,'LISTING',13,10,10

macro ldisplay args&
    local str
    virtual at 0
        db args
        load str : $ from 0
    end virtual
    define ldisplay. str
end macro

postpone
    irpv d, ldisplay
        display d
    end irpv
end postpone

namespace Listing
    base = $$
    offset = $
    macro disphex number*,digits:8
        repeat digits
            digit = ((number) shr ((%%-%) shl 2)) and 0Fh
            if digit < 10
                ldisplay '0'+digit
            else
                ldisplay 'A'+digit-10
            end if
        end repeat
    end macro
end namespace

macro ? line&
    line
    namespace Listing
        if ~ $$ eq base
            base = $$
            offset = $$
        end if
        bytes = $ - offset
        if $ - bytes < $$
            bytes = $ - $$
        end if
        offset = $
        disphex (offset scale 0)-bytes,8

        repeat 1, n:__line__
            ldisplay ' (',__file__,',',`n,'): '
        end repeat

        column = 0
        while bytes
            if column = 8
                column = 0
                ldisplay 13,10,'          '
            end if
            load data:byte from $ - bytes
            disphex data,2
            ldisplay ' '
            bytes = bytes - 1
            column = column + 1
        end while
        repeat 8-column
            ldisplay '   '
        end repeat
        ldisplay `line,13,10
    end namespace
end macro

;----------------------------------------------------

