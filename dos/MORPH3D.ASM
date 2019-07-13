

        ;------ This is really messy, but I don't feel like commenting it
        ;------ just yet.
        ;------
        ;------ This whole program is pretty much an ad hoc job, so keep
        ;------ in mind that it really has never been optimized or even
        ;------ sifted through to clean up crap.


.MODEL tiny
.286
Ideal
Include "globals.3dt"


        PALL    =       8
        PALETTES=       8
        POINTS  =       200
        LINES   =       200
        SHADOW  =       10
        FADELVL =       ( 91 *(0ffh))/100


        YAWINC          =       11
        ROLLINC         =       17
        PITCHINC        =       5
                               ;28;17;13;6
                               ;36;22;16;9
                               ;20;13;10;3
        DEPTHINC        =       3
        MOVExINC        =       2
        MOVEyINC        =       1

        SHADOW2         =       SHADOW*2
        SHADOW3         =       SHADOW*3
        POINTSXYZ       =       POINTS*3


UDATASEG
        object          dw      POINTS*3 dup(?)
        object2         dw      POINTS*3 dup(?)
        web             db      POINTS*3 dup(?)            ;(x,y,col)
        objrot          dw      POINTS*3 dup(?)
        proj            dw      POINTS*2*SHADOW dup(?)
        pal_srce1       dw      ?
        pal_srce2       dw      ?
        palmain         db      4*3 dup (?)
        palette         db      SHADOW*3*4 dup(?)
        starttime       dw      ?
        endtime         dw      ?
        temppal1        db      256*3 dup(?)
        temppal2        db      256*3 dup(?)
        defaultpal      db      256*3 dup(?)


DATASEG
        end_message     db      "Programmed by Courtney S. Sharp",10,13,"November 14, 1993",10,10,13,"$"

        framecount      dw      2 dup(0)
        framemsg1       db      " frames, $"
        framemsg2       db      " seconds.",10,13,"$"
        framemsg3       db      " frames per second.",10,10,13,"$"

        yawi            dw      0
        rolli           dw      0
        pitchi          dw      0
        depthi          dw      0
        shadowwait      dw      0 ;---
        palcounter      dw      MORPHDELAY
        paltheta        dw      0
        currpalset      db      0
        movextheta      dw      0
        moveytheta      dw      0
        fadelevel       dw      0

        pal_black       db      00,00,00, 00,00,00, 00,00,00, 00,00,00 ;black

        pal_sets        db      60,35,60, 52,28,52, 44,22,44, 36,15,36 ;purple
                        db      53,45,19, 47,40,15, 41,35,12, 35,30,10 ;yellow
                        db      30,60,60, 23,52,52, 17,44,44, 10,36,36 ;cyan
                        db      22,35,60, 20,33,52, 18,31,44, 16,29,36 ;blue
                        db      54,54,54, 46,46,46, 38,38,38, 30,30,30 ;grey
                        db      60,54,50, 45,42,37, 35,33,29, 30,29,26 ;dark
                        db      22,60,35, 20,52,33, 18,44,31, 16,36,29 ;green
                        db      60,40,20, 52,33,13, 44,27,07, 36,20,00 ;red1
                        db      50,50,60, 43,43,52, 37,37,44, 30,30,36 ;blue

CODESEG
        org     100h



proc    main
        mov     [word ptr sin],0
        call    InitSinCos
        call    InitData

        mov     ah,2ch                  ;DOS get time
        int     21h                     ;CH hrs CL min DH sec DL hsec
        xor     ax,ax                   ;clear ax
        xor     bx,bx                   ;clear bx
        mov     bx,60                   ;60 hrs/min & 60 min/sec
        mov     al,ch                   ;al = hours
        mul     bl                      ;ax (hours*60) = minutes
        xor     bx,bx                   ;
        mov     bl,cl                   ;
        add     ax,bx                   ;ax + minutes
        mov     cx,dx                   ;save sec:hsec in ch:cl
        mov     bx,60                   ;
        mul     bx                      ;ax (minutes*60) = seconds
        xor     bx,bx                   ;
        mov     bl,ch                   ;
        add     ax,bx                   ;ax + seconds
        mov     [starttime],ax          ;Tenths of seconds (<36000)

        mov     di,0
        mov     bx,0
        mov     cx,2
    ManyLoop:
        inc     [framecount]
        cmp     [framecount],0
        jne     @@FrameCountCarry
        inc     [framecount+2]
        @@FrameCountCarry:

        dec     cx
        cmp     cx,1
        je      StartMorph
        jg      EndMorph
        or      cx,cx
        js      NoMorph

        mov     cx,1
        add     bx,MORPHLENINC
        cmp     bx,1800
        jg      StopMorph
        jmp     EndMorph
      StopMorph:
        call    closemorph
        mov     cx,MORPHDELAY
        mov     bx,0
        jmp     EndMorph
      StartMorph:
        mov     cx,1
        call    initmorph
        jmp     EndMorph
      NoMorph:
        mov     cx,0
      EndMorph:
        call    domorph
        call    motion

        push    bx
        push    cx

        call    incrotation
        call    incproj

        cmp     [shadowwait],SHADOW
        jg      EraseShadow
        inc     [shadowwait]
        jmp     DoneShadow
      EraseShadow:
        mov     dx,di
        mov     dh,2
        mov     cx,POINTS
        call    erase_points
      DoneShadow:

            call    fadepal
            call    setnewcolor
            call    setpalblock

        mov     cx,POINTS
        call    rotate
        mov     cx,POINTS
        call    project

        mov     dx,di
        mov     cx,POINTS
        call    draw_points4

        jmp     $+2
        jmp     $+2

        call    checkforexit

        pop     cx
        pop     bx
        jmp     ManyLoop

        mov     ah,4ch
        int     21h


endp    main


proc    incrotation
        sub     [yawi],YAWINC/3
        jns     @@yawiOK
        add     [yawi],3600
      @@yawiOK:
        sub     [rolli],ROLLINC/3
        jns     @@rolliOK
        add     [rolli],3600
      @@rolliOK:
        sub     [pitchi],PITCHINC/3
        jns     @@pitchiOK
        add     [pitchi],3600
      @@pitchiOK:
        sub     [depthi],DEPTHINC
        jns     @@depthiOK
        add     [depthi],3600
      @@depthiOK:
        sub     [movextheta],MOVExINC
        jns     @@movexthetaOK
        add     [movextheta],3600
      @@movexthetaOK:
        sub     [moveytheta],MOVEyINC
        jns     @@moveythetaOK
        add     [moveytheta],3600
      @@moveythetaOK:

        mov     ax,1800
        mov     bx,[yawi]
        call    sine
        add     dx,1800
        mov     bx,dx
        mov     ax,YAWINC
        call    sine
        add     dx,YAWINC/2
        add     [word ptr yaw],dx
        cmp     [word ptr yaw],0
        jg      YawCont
        add     [word ptr yaw],3600
      YawCont:
        cmp     [word ptr yaw],3600
        jb      RealYawOK
        sub     [word ptr yaw],3600
      RealYawOK:

        mov     ax,1800
        mov     bx,[rolli]
        call    sine
        add     dx,1800
        mov     bx,dx
        mov     ax,ROLLINC
        call    sine
        add     dx,ROLLINC/2
        add     [roll],dx
        cmp     [word ptr roll],0
        jg      RollCont
        add     [word ptr roll],3600
      RollCont:
        cmp     [word ptr roll],3600
        jb      RealRollOK
        sub     [word ptr roll],3600
      RealRollOK:

        mov     ax,1800
        mov     bx,[pitchi]
        call    sine
        add     dx,1800
        mov     bx,dx
        mov     ax,PITCHINC
        call    sine
        add     dx,PITCHINC/2
        add     [word ptr pitch],dx
        cmp     [word ptr pitch],0
        jg      PitchCont
        add     [word ptr pitch],3600
      PitchCont:
        cmp     [word ptr pitch],3600
        jb      RealPitchOK
        sub     [word ptr pitch],3600
      RealPitchOK:

        mov     ax,150
        mov     bx,[movextheta]
        call    sine
        mov     [mx],dx

        mov     ax,150
        mov     bx,[moveytheta]
        call    sine
        mov     [my],dx

        mov     ax,800
        mov     bx,[depthi]
        call    sine
        add     dx,-1000-500
        mov     [mz],dx

        ret
endp    incrotation


proc    incproj
        push    ax
        push    bx
        push    dx

        inc     di
        cmp     di,SHADOW
        jl      ProjInBounds
        xor     di,di
      ProjInBounds:

        mov     ax,di
        mov     bx,POINTS*2*2
        mul     bx

        mov     [project_dest], offset proj
        add     [project_dest], ax

        mov     [web_coor], offset proj
        add     [web_coor], ax

        pop     dx
        pop     bx
        pop     ax
        ret
endp    incproj


proc    fadepal
        push    ax
        push    cx
        push    dx
        push    di
        push    si
        push    es

        mov     dx,ds
        mov     es,dx

        mov     di,offset palette
        mov     si,di

        mov     dl,FADELVL
        mov     cx,SHADOW*4*3
      FadeLoop:
        lodsb
        mul     dl
        mov     al,ah
        stosb
      loop    FadeLoop
        pop     es
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     ax
        ret
endp    fadepal

proc    setnewcolor
        push    ax bx cx dx si

        inc     [palcounter]
        cmp     [palcounter],MORPHDELAY
        jge     ModifyPal
        jmp     PalThetaEnd
      ModifyPal:
        mov     ax,MORPHLENINC
        sar     ax,1
        add     [paltheta],ax
        cmp     [paltheta],900
        jg      ResetPalMorph

        push    di
        xor     ax,ax
        mov     bx,[paltheta]
        mov     si,[pal_srce1]
        mov     di,offset palmain
        mov     cx,12
       PalSource1:
        mov     al,[si]
        call    cossq
        mov     [di],dl
        inc     si
        inc     di
       loop    PalSource1
        mov     si,[pal_srce2]
        mov     di,offset palmain
        mov     cx,12
       PalSource2:
        xor     ax,ax
        xor     dx,dx
        mov     al,[si]
        call    sinsq
        add     [di],dl
        inc     si
        inc     di
       loop    PalSource2
        pop     di

        jmp     PalThetaEnd
      ResetPalMorph:
        mov     [palcounter],0
        mov     [paltheta],0
        mov     ax,[pal_srce2]
        mov     [pal_srce1],ax

        mov     ax,MULTIPLIER
        mul     [rand_morph]
        dec     ax
        mov     bx,PALETTES
        xor     dx,dx
        div     bx
        mov     bx,dx
        mov     ax,3*4
        mul     bx
        add     ax,offset pal_sets
        mov     [pal_srce2],ax
    PalThetaEnd:
        mov     si,offset palmain
        mov     ax,di
        mov     bx,3
        mul     bx
        mov     bx,ax
        mov     dl,[si]
        mov     [palette+bx],dl
        mov     dl,[si+1]
        mov     [palette+bx+1],dl
        mov     dl,[si+2]
        mov     [palette+bx+2],dl

        mov     dl,[si+3]
        mov     [palette+SHADOW*3+bx],dl
        mov     dl,[si+4]
        mov     [palette+SHADOW*3+bx+1],dl
        mov     dl,[si+5]
        mov     [palette+SHADOW*3+bx+2],dl

        mov     dl,[si+6]
        mov     [palette+SHADOW*6+bx],dl
        mov     dl,[si+7]
        mov     [palette+SHADOW*6+bx+1],dl
        mov     dl,[si+8]
        mov     [palette+SHADOW*6+bx+2],dl

        mov     dl,[si+9]
        mov     [palette+SHADOW*9+bx],dl
        mov     dl,[si+10]
        mov     [palette+SHADOW*9+bx+1],dl
        mov     dl,[si+11]
        mov     [palette+SHADOW*9+bx+2],dl


        cmp     [fadelevel],0
        je      @@NoFadeOut

        add     [fadelevel],4

        mov     bx,[fadelevel]
        mov     cx,SHADOW*4*3
        mov     si,offset palette
       @@FadeLoop:
        xor     ax,ax
        lodsb
        call    cosine
        add     dx,ax
        sar     dx,1
        mov     [si-1],dl
       loop    @@FadeLoop

      @@NoFadeOut:


        pop     si dx cx bx ax
        ret
endp    setnewcolor


proc    setpalblock
        push    ax cx dx si

                                        ; AL is starting color value
                                        ; SI is RGB source pointer
                                        ; CX is count of RGB colors
        MOV     DX,3c8h                 ; Setup palette. (port 03c8h)
        MOV     AL,1
        OUT     DX,AL
        INC     DX
        MOV     CX,SHADOW*3*4
        MOV     SI,OFFSET palette       ; Prestored...

        rep outsb

;      @@pl1:
;         LODSB
;         OUT    DX,AL
;      LOOP   @@pl1

        pop     si dx cx ax
        ret
endp    setpalblock




proc    InitData
        push    ax cx dx di


        push    bx

        mov     ax,1017h
        mov     bx,1
        mov     cx,255
        mov     dx,offset defaultpal
        int     10h

        mov     ax,1201h
        mov     bl,31h
        int     10h
        mov     dl,0
        call    fadeoutin
        mov     ax,0013h                ;screen mode
        int     10h                     ;       320x200x256
        mov     ax,1200h
        mov     bl,31h
        int     10h
        pop     bx

        mov     ax,0a000h
        mov     es,ax

        mov     [word ptr mx],0
        mov     [word ptr my],0
        mov     [word ptr mz],-1550
        mov     [word ptr mag],300
        mov     [word ptr sx],160
        mov     [word ptr sy],100
        mov     [word ptr yaw],0
        mov     [word ptr roll],0
        mov     [word ptr pitch],0

        mov     [motion_dest],  offset objrot
        mov     [rotate_srce],  offset objrot
        mov     [rotate_dest],  offset objrot
        mov     [project_srce], offset objrot
        mov     [project_dest], offset proj
        mov     [web_coor],     offset proj
        mov     [web_link],     offset web
        mov     [morph_srce1],  offset object
        mov     [morph_srce2],  offset object2
        mov     [morph_dest],   offset motion_data

        mov     [pal_srce1],offset pal_black
        mov     [pal_srce2],offset pal_sets

        push    ax bx cx dx si di es
        mov     ax,ds
        mov     es,ax

        mov     ax,0
        mov     di,offset object
        mov     cx,POINTS*3
        rep     stosw
        mov     di,offset object2
        mov     cx,POINTS*3
        rep     stosw
        mov     di,offset objrot
        mov     cx,POINTS*3
        rep     stosw

        mov     di,offset palette
        mov     bx,0
        mov     cx,4
       fpsl1:
        push    cx
        mov     cx,SHADOW
       fillpalset:
        push    cx
        mov     si,offset pal_sets

        mov     ax,cx
        mov     cx,3
        xor     dx,dx
        div     cx
        mov     ax,dx
        mov     cx,12
        xor     dx,dx
        mul     cx
        add     si,ax

        add     si,bx
        mov     cx,3
        rep     movsb
        pop     cx
       loop    fillpalset
        add     bx,3
        pop     cx
       loop    fpsl1
        mov     ax,1012h
        mov     bx,1
        mov     cx,SHADOW*4
        mov     dx,offset palette
        int     10h

        pop     es di si dx cx bx ax


        mov     [rotate_srce],offset object
        mov     cx,POINTS
        call    rotate
        mov     cx,POINTS
        call    project
        mov     ax,[rotate_dest]
        mov     [rotate_srce],ax

        mov     ah,0
        int     1ah
        mov     [rand_morph],dx

        mov     [word ptr motion_counter],0

        pop     di dx cx ax
        ret
endp    InitData


proc    checkforexit
        cmp     [fadelevel],1800
        jge     @@FadeOutDone

        mov     ah,01h
        int     16h
        jz      NoKey
        mov     ah,00h
        int     16h
        cmp     al,27
        je      Exit
      NoKey:
        ret

      Exit:
        cmp     [fadelevel],180
        jge     @@FadeOutDone
        inc     [fadelevel]
        ret
      @@FadeOutDone:

        mov     ah,2ch                  ;DOS get time
        int     21h                     ;CH hrs CL min DH sec DL hsec
        xor     ax,ax                   ;clear ax
        xor     bx,bx                   ;clear bx
        mov     bx,60                   ;60 hrs/min & 60 min/sec
        mov     al,ch                   ;al = hours
        mul     bl                      ;ax (hours*60) = minutes
        xor     bx,bx                   ;
        mov     bl,cl                   ;
        add     ax,bx                   ;ax + minutes
        mov     cx,dx                   ;save sec:hsec in ch:cl
        mov     bx,60                   ;
        mul     bx                      ;ax (minutes*60) = seconds
        xor     bx,bx                   ;
        mov     bl,ch                   ;
        add     ax,bx                   ;ax + seconds
        sub     ax,[starttime]          ;;
        mov     [endtime],ax            ;;

        mov     ax,ds
        mov     es,ax
        mov     di,offset temppal1
        mov     cx,256*3
        mov     ax,0
        rep     stosb
        mov     dx,offset temppal1
        mov     ax,1012h
        mov     bx,1
        mov     cx,255
        int     10h
        mov     ax,1201h
        mov     bl,31h
        int     10h
        mov     ax,0003h
        int     10h
        mov     ax,1200h
        mov     bl,31h
        int     10h

        mov     dx,offset end_message
        mov     ah,09h
        int     21h

        mov     dx,[framecount]
        call    dec16out
        mov     ah,09h
        mov     dx,offset framemsg1
        int     21h

        mov     dx,[endtime]
        call    dec16out
        mov     ah,09h
        mov     dx,offset framemsg2
        int     21h

        xor     dx,dx
        mov     ax,[framecount+2]
        mov     bx,10
        mul     bx
        mov     cx,ax
        xor     dx,dx
        mov     ax,[framecount]
        mov     bx,10
        mul     bx
        add     dx,cx
        div     [endtime]
        xor     dx,dx
        mov     bx,10
        div     bx
        xchg    ax,dx
        call    dec16out
        mov     dh,al
        mov     dl,'.'
        mov     ah,02h
        int     21h
        mov     dl,dh
        add     dl,30h
        int     21h
        mov     ah,09h
        mov     dx,offset framemsg3
        int     21h

        mov     si,offset defaultpal
        mov     dl,1
        call    fadeoutin

        mov     ah,4ch                  ;terminate program
        int     21h                     ;
        ret
endp    checkforexit


;------ outputs 16-bit decimal using STDIO
;------ 16-bit in DX
;------ no registers are modified
proc    dec16out
        push    ax bx cx dx

        xor     cx,cx
        mov     bx,10
        mov     ax,dx
      @@dec16out1:
        xor     dx,dx
        div     bx
        push    dx
        inc     cx
        or      ax,ax
      jnz     @@dec16out1
        mov     ah,02h
      @@dec16out2:
        pop     dx
        add     dl,30h
        int     21h
      loop    @@dec16out2

        pop     dx cx bx ax
        ret
endp    dec16out


;------ dl : 0=fade out, 1=fade in
;------ si : offset of palette if dl=1
proc    fadeoutin
        push    ax bx cx dx si di es

        xor     dh,dh
        push    dx

        mov     ax,ds
        mov     es,ax
        mov     di,offset temppal2

      or      dl,dl
      jnz     @@DontLoadPal
        mov     si,offset temppal1
        mov     ax,1017h
        mov     bx,1
        mov     cx,255
        mov     dx,si
        int     10h
      @@DontLoadPal:

        pop     bx
        imul    bx,1800
        sub     bx,3
        mov     cx,600
    @@FadeLoop:
        add     bx,3
        mov     ax,900
        call    cosine
        add     dx,900

        push    bx cx si di

;        mov     bx,dx

        mov     cx,255*3
      @@PalLoop:
        xor     ax,ax
        lodsb
        call    cosine
;        neg     dx
        add     dx,ax
        sar     dx,1
        mov     ax,dx
        stosb
      loop    @@PalLoop

        mov     dx,3c8h
        mov     al,1
        out     dx,al
        inc     dx
        mov     cx,255*3
        mov     si,offset temppal2
      @@pl1:
         lodsb
         out    dx,al
      loop   @@pl1

        pop     di si cx bx
    loop    @@FadeLoop


        pop     es di si dx cx bx ax
        ret
endp    fadeoutin


        end     main
