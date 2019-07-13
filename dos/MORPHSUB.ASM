.MODEL tiny
.386
Ideal
Include "globals.3dt"


        MOTION_TICKS    = 57
        MORPHDELAY      = 500
        MORPHLENINC     = 8
        MULTIPLIER      = 65497


UDATASEG
        motion_data     dw      200*3 dup(?)
        motion_temp     dw      3 dup(?)
        morph_srce1     dw      ?
        morph_srce2     dw      ?
        morph_dest      dw      ?
        motion_dest     dw      ?
        rand_morph      dw      ?

DATASEG
        motion_counter  dw      0
        motion_max      dw      MOTION_TICKS

        lissomega       dw      1,5,3
        lissomega2      dw      5,3,6;3,1,4
        lissomega3      dw      5,5,6
        lissomega4      dw      4,4,7
        lissomega5      dw      11,1,9
        lissomega6      dw      2,1,3
        lissomega7      dw      3,2,4
        lissomega8      dw      10,1,9
        lissomega9      dw      5,1,3
        lissoffset      dw      0,900,0
        cylinderdata    dw       50,    350,    0
                        dw      150,    350,    0
                        dw      250,    350,    0
                        dw      250,    250,    0
                        dw      250,    150,    0
                        dw      250,    50,     0
                        dw      250,    -50,    0
                        dw      250,    -150,   0
                        dw      150,    -150,   0
                        dw       50,    -150,   0
        conedata        dw      0,      140,    0
                        dw      54,     220,    0
                        dw      108,    300,    0
                        dw      162,    380,    0
                        dw      216,    460,    0
                        dw      270,    540,    0
                        dw      324,    620,    0
                        dw      220,    620,    0
                        dw      120,    620,    0
                        dw      81,     710,    0
                        dw      81,     800,    0
        diskdata        dw      150,    0,      0
                        dw      180,    0,      0
                        dw      210,    0,      0
                        dw      240,    0,      0
                        dw      270,    0,      0
                        dw      300,    0,      0
                        dw      330,    0,      0
                        dw      360,    0,      0


CODESEG
        org     0h



;----------------------------------------------------------------------------;
;  Do The Morph :: Sinusoidal Morph (as bx varies linearly)                  ;
;                                                                            ;
;  This routine will morph between two arrays into a third.  The procedure   ;
;  is simple.  Given an input between 0 and 1800, it will calculate          ;
;  a fractional coefficient to multply all the source points by.  This       ;
;  number is (in essence) between 0 and 1/2.  For the destination points,    ;
;  it substracts the coeffieicnt from 1/2.  All points are doubled before    ;
;  opperated on, so the final sumnation will always have an effective        ;
;  coefficient of 1 with a varying emphasis on the two source arrays.  Wow.  ;
;                                                                            ;
;  Input : bx           morph level [0,1800];  (0)no morph, (1800)full morph ;
;        : morph_dest   pointer to destination array                         ;
;        : morph_srce1  pointer to original array of points                  ;
;        : morph_srce2  pointer to array of points to be morphed into        ;
;        : POINTSXYZ    absolute constant defining array size in words       ;
;                                                                            ;
;  Uses  : cosine (SINTAB.ASM)                                               ;
;                                                                            ;
;  Output: morphed array of points into memory area pointer to by morph_dest ;
;        : no registers are modified or destroyed                            ;
;----------------------------------------------------------------------------;
proc    domorph
        push    ax bx cx dx si di es

        mov     ax,ds                           ;load ds
        mov     es,ax                           ;into es

        mov     ax,16383                        ;resolution of morph
        call    cosine                          ;  cosine : bx=theta(0,3600)
        mov     bx,dx                           ;           dx=output
        add     bx,16384                        ;multiplier [0,32767]

        mov     cx,POINTSXYZ                    ;POINTSXYZ = POINTS*3
        mov     di,[morph_dest]                 ;morph_dest : dest array
        mov     si,[morph_srce1]                ;morph_srce1: original array
      Morph2:
        lodsw                                   ;load point (si)
        sal     ax,1                            ;  double point
        imul    bx                              ;multiply by bx (0,32767)
        mov     ax,dx                           ;move overflow into ax
        stosw                                   ;store point (di)
      loop    Morph2

        neg     bx                              ;bx = 32768-bx
        add     bx,32768                        ;bx (32767,0)

        mov     cx,POINTSXYZ                    ;...
        mov     di,[morph_dest]                 ;morph_dest : dest array
        mov     si,[morph_srce2]                ;morph_srce2: morph-to array
      Morph1:
        lodsw                                   ;load point
        sal     ax,1                            ;  double
        imul    bx                              ;multiply by bx (32767,0)
        add     [di],dx                         ;add it to dest_array
        inc     di                              ;increment di
        inc     di                              ;"         "
      loop    Morph1

        pop     es di si dx cx bx ax
        ret
endp    domorph


;----------------------------------------------------------------------------;
;  Motion :: cause the points to rotate within the figure -- Linear Movement ;                 ;
;                                                                            ;
;  It's the same priciple as the morph with a morph between two points in    ;
;  sequence in the array (rather than a morph between two unique arrays).    ;
;  The only other difference is that this is a straight up linear movement   ;
;  instead of a sinusoidal movement.                                         ;
;                                                                            ;
;  Input :  absolute value MOTION_TICKS determines how the number of         ;
;        :  subdivisions between two points (the speed and resolution).      ;
;        :                                                                   ;
;        :  morph_dest  pointer to source array of points                    ;
;        :  motion_dest pointer to destination array of points               ;
;        :                                                                   ;
;        :  morph_srce1 | When a single morph is completed between two       ;
;        :  morph_srce2 | points, the array values are shifted.              ;
;        :                                                                   ;
;        :  POINTSXYZ   size of arrays in words                              ;
;                                                                            ;
;  Uses  :  word motion_couter ... tracks position of motion morph           ;
;                                                                            ;
;  Output:  motioned points into array pointed to by motion_dest             ;
;        :  nothing else is modified or destroyed                            ;
;----------------------------------------------------------------------------;
proc    motion
        push    ax bx cx dx si di es

        mov     ax,ds
        mov     es,ax

        inc     [word ptr motion_counter]
        cmp     [motion_counter],MOTION_TICKS
        jge     @@motion_3

        mov     bx,[motion_counter]
        neg     bx
        add     bx,MOTION_TICKS

        mov     si,[morph_dest]
        mov     di,[motion_dest]
        mov     cx,POINTSXYZ
        sub     cx,3
      @@motion_1:
        xor     dx,dx
        mov     ax,[si+6]
        imul    [word ptr motion_counter]
        idiv    [word ptr motion_max]
        stosw

        xor     dx,dx
        lodsw
        imul    bx
        idiv    [word ptr motion_max]
        add     [word ptr di-2],ax
      loop    @@motion_1


        mov     cx,(1)*3
      @@motion_2:
        xor     dx,dx
        mov     ax,[si - ( (200-1) * 3) *2]
        imul    [word ptr motion_counter]
        idiv    [word ptr motion_max]
        stosw

        xor     dx,dx
        lodsw
        imul    bx
        idiv    [word ptr motion_max]
        add     [word ptr di-2],ax
      loop    @@motion_2

        jmp     @@motion_end


    @@motion_3:
        mov     [word ptr motion_counter],0

        mov     bx,offset motion_temp
        mov     si,[morph_srce1]
        mov     di,[morph_srce1]
        add     si,6
        mov     ax,[di]
        mov     [bx],ax
        mov     ax,[di+2]
        mov     [bx+2],ax
        mov     ax,[di+4]
        mov     [bx+4],ax
        mov     cx,POINTSXYZ
        sub     cx,3
        rep     movsw
        mov     ax,[bx]
        mov     [di],ax
        mov     ax,[bx+2]
        mov     [di+2],ax
        mov     ax,[bx+4]
        mov     [di+4],ax

        mov     si,[morph_srce2]
        mov     di,[morph_srce2]
        add     si,6
        mov     ax,[di]
        mov     [bx],ax
        mov     ax,[di+2]
        mov     [bx+2],ax
        mov     ax,[di+4]
        mov     [bx+4],ax
        mov     cx,POINTSXYZ
        sub     cx,3
        rep     movsw
        mov     ax,[bx]
        mov     [di],ax
        mov     ax,[bx+2]
        mov     [di+2],ax
        mov     ax,[bx+4]
        mov     [di+4],ax

        mov     si,[morph_dest]
        mov     di,[motion_dest]
        mov     cx,POINTSXYZ
        rep     movsw

    @@motion_end:
        pop     es di si dx cx bx ax
        ret
endp    motion


;----------------------------------------------------------------------------;
;  Initialize a new figure to morph into using a psuedo-random number        ;
;----------------------------------------------------------------------------;
proc    initmorph
        push    ax bx cx dx si di es

        mov     ax,MULTIPLIER
        mul     [rand_morph]
        inc     ax
        mov     [rand_morph],ax
        xor     dx,dx
        mov     bx,19
        div     bx

        mov     si,[morph_srce2]
        
      MorphSet0:
        cmp     dx,0
        jg      MorphSet1
        mov     ax,50
        mov     di,300
        mov     [rotateMX],150
        mov     [rotateMY],0
        mov     [rotateMZ],0
        call    maketorus
        jmp     MorphEnd

      MorphSet1:
        cmp     dx,1
        jg      MorphSet2
        lea     di,[lissomega]
        jmp     GenLiss

      MorphSet2:
        cmp     dx,2
        jg      MorphSet3
        lea     di,[lissomega2]
        jmp     GenLiss

      MorphSet3:
        cmp     dx,3
        jg      MorphSet4
        lea     di,[lissomega3]
        jmp     GenLiss

      MorphSet4:
        cmp     dx,4
        jg      MorphSet5
        lea     di,[lissomega4]
        jmp     GenLiss

      MorphSet5:
        cmp     dx,5
        jg      MorphSet6
        lea     di,[lissomega5]
        jmp     GenLiss

      MorphSet6:
        cmp     dx,6
        jg      MorphSet7
        lea     di,[lissomega6]
        jmp     GenLiss

      MorphSet7:
        cmp     dx,7
        jg      MorphSet8
        lea     di,[lissomega7]
        jmp     GenLiss

      MorphSet8:
        cmp     dx,8
        jg      MorphSet9
        lea     di,[lissomega8]
        jmp     GenLiss

      MorphSet9:
        cmp     dx,9
        jg      MorphSet10
        lea     di,[lissomega9]
        jmp     GenLiss

      MorphSet10:                               ;sphere
        cmp     dx,10
        jg      MorphSet11
        mov     ax,450
        call    makesphere
        jmp     MorphEnd

      MorphSet11:                               ;cylider
        cmp     dx,11
        jg      MorphSet12
        push    si
        push    ds
        pop     es
        mov     di,si
        mov     si,offset cylinderdata
        mov     cx,10*3
        rep     movsw
        pop     si
        mov     bx,3600
        mov     cx,10
        mov     [rotateMX],60
        mov     [rotateMY],60
        mov     [rotateMZ],60
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet12:                               ;christmas tree
        cmp     dx,12
        jg      MorphSet13
        push    si
        push    ds
        pop     es
        mov     di,si
        mov     si,offset conedata
        mov     cx,10*3
        rep     movsw
        pop     si
        mov     bx,3600
        mov     cx,10
        mov     [rotateMX],150
        mov     [rotateMY],-400
        mov     [rotateMZ],0
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet13:
        cmp     dx,13
        jg      MorphSet14
        mov     di,100
        mov     ax,200
        mov     cx,40
        call    makeparam
        push    si
       CartLoop1:
        sub     [word ptr si],50
        add     si,6
       loop    CartLoop1
        pop     si
        mov     bx,3600
        mov     cx,40
        mov     [rotateMX],110
        mov     [rotateMY],110
        mov     [rotateMZ],110
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet14:
        cmp     dx,14
        jg      MorphSet15
        mov     di,50
        mov     ax,300
        mov     cx,40
        call    makeparam
        push    si
        add     si,4
        mov     ax,1
        mov     bx,900
        mov     dx,200
        call    makeliss
        pop     si
        mov     bx,3600
        mov     cx,40
        mov     [rotateMX],110
        mov     [rotateMY],110
        mov     [rotateMZ],110
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet15:
        cmp     dx,15
        jg      MorphSet16
        push    si
        push    ds
        pop     es
        mov     di,si
        mov     si,offset diskdata
        mov     cx,8*3
        rep     movsw
        pop     si
        push    si
        add     si,2
        mov     ax,10
        mov     bx,0
        mov     dx,200
        call    makeliss
        add     si,2
        call    makeliss
        pop     si
        mov     bx,3600
        mov     cx,8
        mov     [rotateMX],60
        mov     [rotateMY],60
        mov     [rotateMZ],60
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet16:
        cmp     dx,16
        jg      MorphSet17
        push    si
        push    ds
        pop     es
        mov     di,si
        mov     si,offset cylinderdata
        mov     cx,10*3
        rep     movsw
        pop     si
        push    si
        add     si,4
        mov     ax,24
        mov     bx,600
        mov     dx,200
        call    makeliss
        pop     si
        mov     bx,3600
        mov     cx,10
        mov     [rotateMX],0
        mov     [rotateMY],0
        mov     [rotateMZ],0
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet17:
        cmp     dx,17
        jg      MorphSet18
        push    ax
        push    cx
        push    si
        mov     ax,255
        mov     cx,18
       BoxLoop1:
        mov     [word ptr si],255
        add     si,2
        mov     [word ptr si],ax
        add     si,2
        mov     [word ptr si],255
        add     si,2
        sub     ax,30
       loop    BoxLoop1
        mov     ax,255-30
        mov     cx,16
       BoxLoop2:
        mov     [word ptr si],ax
        mov     [word ptr si+16*2*3],ax
        add     si,2
        mov     [word ptr si],255
        mov     [word ptr si+16*2*3],-255
        add     si,2
        mov     [word ptr si],255
        mov     [word ptr si+16*2*3],255
        add     si,2
        sub     ax,30
       loop    BoxLoop2
        pop     si
        pop     cx
        pop     ax
        mov     bx,3600
        mov     cx,50
        mov     [rotateMX],0
        mov     [rotateMY],0
        mov     [rotateMZ],0
        call    rotate2Dfig
        jmp     MorphEnd

      MorphSet18:                               ;18: fountain
        cmp     dx,18
        jg      MorphSet19

        mov     ax,ds
        mov     es,ax
        mov     di,si

        mov     cx,40
      @@MS_18:
        xor     dx,dx
        mov     ax,1800*5+900
        mul     cx
        mov     bx,40
        div     bx
        xor     dx,dx
        mov     bx,3600
        div     bx
        mov     bx,dx
        mov     ax,cx
        sal     ax,3
        call    sine
        add     dx,ax
        neg     ax
        add     ax,40*8
        sal     ax,1
        stosw
        mov     ax,dx
        stosw
        xor     ax,ax
        stosw
      loop    @@MS_18
        mov     bx,3600
        mov     cx,40
        mov     [rotateMX],0
        mov     [rotateMY],0
        mov     [rotateMZ],0
        call    rotate2Dfig
        jmp     MorphEnd


      MorphSet19:
        jmp     MorphEnd

      GenLiss:
        mov     dx,320
        mov     ax,[di]
        mov     bx,[lissoffset]
        call    makeliss
        add     si,2
        mov     ax,[di+2]
        mov     bx,[lissoffset+2]
        call    makeliss
        add     si,2
        mov     ax,[di+4]
        mov     bx,[lissoffset+4]
        call    makeliss

      MorphEnd:
        pop     es di si dx cx bx ax
        ret
endp    initmorph


;----------------------------------------------------------------------------;
;  Close morphing -- all it does is toggle active rotation/morph set         ;
;----------------------------------------------------------------------------;
proc    closemorph
        push    ax dx

        mov     ax,[morph_srce1]
        mov     dx,[morph_srce2]
        mov     [morph_srce1],dx
        mov     [morph_srce2],ax

        pop     dx ax
        ret
endp    closemorph


        end
