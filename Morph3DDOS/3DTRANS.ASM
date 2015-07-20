.MODEL tiny
.286
Ideal
Include "globals.3dt"


        global  color:word
        global  SHADOW3:abs,SHADOW2:abs,SHADOW:abs,POINTS:abs


        yaw     =       YawPtr + 1
        roll    =       RollPtr + 1
        pitch   =       PitchPtr + 1

        mx      =       MXptr + 1
        my      =       MYptr + 1
        mz      =       MZptr + 1
        sx      =       SXptr + 1
        sy      =       SYptr + 1
        mag     =       MAGptr + 1

        xa      =       word ptr XAptr + 1
        ya      =       word ptr YAptr + 1
        za      =       word ptr ZAptr + 1


UDATASEG
        rotate_srce     dw      ?               ;pointers
        rotate_dest     dw      ?               ;
        project_srce    dw      ?               ;
        project_dest    dw      ?               ;
        web_coor        dw      ?               ;
        web_link        dw      ?               ;

        rotinc          dw      ?
        destinc         dw      ?
        pixels          dw      ?
        rotateMX        dw      ?
        rotateMY        dw      ?
        rotateMZ        dw      ?

        z1              dw      ?
        rotate_cx       dw      ?


CODESEG
        org     0h


;-----------------------------------------------------------------------------;
;       3D rotation algorithm                                                 ;
;                                                                             ;
;       in :    rotate_srce     pointer to source coordinate integers (x,y,z) ;
;               rotate_dest     pointer to rotated coordinates (x,y,z)        ;
;               yaw,roll,pitch  rotation in 1/10 degrees [0,3600)             ;
;               cx              count of coordinates to rotate                ;
;                                                                             ;
;       out:    rotated coordinates (x,y,z) at rotate_dest                    ;
;                                                                             ;
;       routines used : sine, cosine                                          ;
;-----------------------------------------------------------------------------;
proc    rotate
        push    ax bx dx si di          ;save registers

        mov     si,[rotate_srce]        ;
        mov     di,[rotate_dest]        ;

        mov     [rotate_cx],cx          ;count of 3D points to rotate
    @@Loop:
       YawPtr:                  ;YAW: rotation around the y-axis
        mov     bx,0000h                ;   theta = yaw (pointer to this addr)
        sal     bx,1                    ;       sine table is in words

        mov     ax,[si]                 ;------------- SOURCE_X
        sal     ax,1                    ;       SINx (-1/2,1/2). Thus, double x
        mov     cx,ax                   ;       save ax in cx
        imul    [word ptr cos+bx]       ;       signed mul: ax * [cos] = dx
        mov     [xa],dx                 ;xa = x*cos(yaw)
        mov     ax,cx                   ;       resotre original ax
        imul    [word ptr sin+bx]       ;       signed mul: ax * [sin] = dx
        mov     [za],dx                 ;za = x*sin(yaw)

        mov     ax,[si+4]               ;------------- SOURCE_Z
        sal     ax,1                    ;       SINx (-1/2,1/2). Thus, double x
        mov     cx,ax                   ;       save ax in cx
        imul    [word ptr sin+bx]       ;       signed mul: ax * [sin] = dx
        sub     [xa],dx                 ;xa = x*cos(yaw) - z*sin(yaw)
        mov     ax,cx                   ;       restore original ax
        imul    [word ptr cos+bx]       ;       signed mul: ax * [cos] = dx
        add     [za],dx                 ;za = x*sin(yaw) + z*cos(yaw)

       RollPtr:                 ;ROLL: rotation around the z-axis
        mov     bx,0000h                ;   theta = roll (pointer to this addr)
        sal     bx,1                    ;       sine table in words

        mov     ax,[si+2]               ;------------- SOURCE_Y
        sal     ax,1                    ;
        mov     cx,ax                   ;
        imul    [word ptr sin+bx]       ;
        mov     [di],dx                 ; x = y*sin(roll)
        mov     ax,cx                   ;
        imul    [word ptr cos+bx]       ;
        mov     [ya],dx                 ;ya = y*cos(roll)

XAptr:  mov     ax,0000h                ;------------- XA
        sal     ax,1                    ;
        mov     cx,ax                   ;
        imul    [word ptr cos+bx]       ;
        add     [di],dx                 ; x = xa*cos(roll) + y*sin(roll)
        mov     ax,cx                   ;
        imul    [word ptr sin+bx]       ;
        sub     [ya],dx                 ;ya = y*cos(roll) - xa*sin(roll)

       PitchPtr:                ;PITCH: rotaion around the x-axis
        mov     bx,0000h                ;   theta = pitch (pointer to this addr)
        sal     bx,1                    ;       sine table in words

ZAptr:  mov     ax,0000h                ;------------- ZA
        sal     ax,1                    ;
        mov     cx,ax                   ;
        imul    [word ptr cos+bx]       ;
        mov     [di+4],dx               ; z = za*cos(pitch)
        mov     ax,cx                   ;
        imul    [word ptr sin+bx]       ;
        mov     [di+2],dx               ; y = za*sin(pitch)

YAptr:  mov     ax,0000h                ;------------- YA
        sal     ax,1                    ;
        mov     cx,ax                   ;
        imul    [word ptr sin+bx]       ;
        sub     [di+4],dx               ; z = za*cos(pitch) - ya*sin(pitch)
        mov     ax,cx                   ;
        imul    [word ptr cos+bx]       ;
        add     [di+2],dx               ; y = za*sin(pitch) + ya*cos(pitch)

        add     si,6                    ;Increment source array 3 words
        add     di,6                    ;Increment destination array 3 words

        dec     [word ptr rotate_cx]    ;code too large to LOOP
        jz      @@ExitLoop              ;  and CX is used as a temp register
        jmp     @@Loop                  ;So do the same thing with ROTATE_CX
    @@ExitLoop:                         ;and a few jumps

        pop     di si dx bx ax          ;restore registers
        ret                             ;return
endp    rotate



;-----------------------------------------------------------------------------;
;       3D projection algorithm                                               ;
;                                                                             ;
;       in :    project_srce    pointer to source coordinate integers (x,y,z) ;
;               project_dest    pointer to projected coordinates (x,y)        ;
;               mag             magnification                                 ;
;               cx              count of coordinates                          ;
;                                                                             ;
;       out:    projected screen coordinates (x,y) at project_dest            ;
;                                                                             ;
;       uses:   muldiv                                                        ;
;-----------------------------------------------------------------------------;
proc    project
        push    ax bx cx dx si di       ;faster that pusha (I beleive)

MAGptr: mov     bx,0000h                ;
        mov     si,[project_srce]       ;
        mov     di,[project_dest]       ;
    @@Loop:
        push    cx

 MZptr: mov     cx,0000h                ;       z-axis translation
        add     cx,[si+4]               ;cx = divisor (3D-z)

        xor     dx,dx                   ;       clear overflow
        mov     ax,[si]                 ;ax = coefficient (3D-x)
 MXptr: add     ax,0000h                ;       x-axis translation
        imul    bx                      ;       sign.mul mag
        idiv    cx                      ;       sign.div 3D-z
 SXptr: add     ax,0000h                ;       screen x-shift
        mov     [di],ax                 ;screen_x = (3Dx * dist) / 3Dz

        xor     dx,dx                   ;       clear overflow
        mov     ax,[si+2]               ;ax = coefficient (3D-y)
 MYptr: add     ax,0000h                ;       y-axis translation
        imul    bx                      ;       sign.mul mag
        idiv    cx                      ;       sign.div 3D-z
 SYptr: add     ax,0000h                ;       screen y-shift
        mov     [di+2],ax               ;screen_y = (3Dy * dist) / 3Dz

        add     si,6                    ;increment source 3 words
        add     di,4                    ;increment destination 2 words

        pop     cx                      ;
        loop    @@Loop                  ;

        pop     di si dx cx bx ax       ;restore
        ret                             ;return
endp    project



;-----------------------------------------------------------------------------;
;       Plot the points (not lines) of an object                              ;
;                                                                             ;
;       in :    web_coor        pointer to plotting coordinates               ;
;               project_srce    pointer to original 3D coordinates            ;
;               cx              number of points                              ;
;               dx              color for points                              ;
;               es              address of start of memory page               ;
;                                                                             ;
;       out:    points on screen, no registers modified                       ;
;-----------------------------------------------------------------------------;
proc    draw_points4
        push    ax bx dx si di

        mov     ax,[project_srce]
        add     ax,4
        mov     si,[web_coor]
  Draw4Loop:
        push    dx

        mov     bx,ax
        cmp     [word ptr bx],-160
        jg      Shade1
        add     dx,SHADOW3
        jmp     ShadeDone
      Shade1:
        cmp     [word ptr bx],0
        jg      Shade2
        add     dx,SHADOW2
        jmp     ShadeDone
      Shade2:
        cmp     [word ptr bx],160
        jg      ShadeDone
        add     dx,SHADOW
      ShadeDone:
        inc     dx

        mov     bx,[si]
        inc     si
        inc     si
        mov     di,[si]
        inc     si
        inc     si
                                ;setpoint
        or      bx,bx                   ;Quick negativity test for x-coor
        js      setpoint1               ;
        or      di,di                   ;Quick negativity test for y-coor
        js      setpoint1               ;
        cmp     bx,320                  ;Test for large x-coor
        jge     setpoint1               ;
        cmp     di,200                  ;test for large y-coor
        jge     setpoint1               ;

                                ;calulate position of point on graphics page
        imul    di,320                  ;y-coor multiple of 320
        mov     [byte ptr es:bx+di],dl  ;put the color into the graphics page
     setpoint1:
        pop     dx

        add     ax,6
  loop    Draw4Loop

        pop     di si dx bx ax
        ret
endp    draw_points4



;-----------------------------------------------------------------------------;
;       Plot the points of an object                                          ;
;                                                                             ;
;       in :    web_coor        pointer to plotting coordinates               ;
;               cx              number of points                              ;
;               dx              color for points                              ;
;               es              address of start of memory page               ;
;                                                                             ;
;       out:    points on screen, no registers modified                       ;
;-----------------------------------------------------------------------------;
proc    erase_points
        push    bx dx si di

        inc     dx
        mov     dh,dl
        mov     si,[web_coor]
  EDrawLoop:
        mov     bx,[si]
        inc     si
        inc     si
        mov     di,[si]
        inc     si
        inc     si
        mov     dl,dh
                                ;calulate position of point on graphics page
        imul    di,320

        sub     dl,[byte ptr es:bx+di]
        jz      Erase
        add     dl,SHADOW
        jz      Erase
        add     dl,SHADOW
        jz      Erase
        add     dl,SHADOW
        jnz     DontErase

      Erase:
        mov     [byte ptr es:bx+di],0
      DontErase:

        loop    EDrawLoop

        pop     di si dx bx
        ret
endp    erase_points



;-----------------------------------------------------------------------------;
;       Generates a lissajous figure (one axis only)                          ;
;          coordinate-axis = 320 * sin( ax*T + bx )                           ;
;                                                                             ;
;       in  :   si      pointer for array  200(x,y,z)                         ;
;                           it must be initially offset for the desired axis  ;
;               ax      coefficient of theta                                  ;
;               bx      offset in 1/10 degrees for lissajous                  ;
;               dx      maximum absolute value of sine                        ;
;                                                                             ;
;       out :   a set of x-, y-, OR z-coordinates for a lissajous at si       ;
;                                                                             ;
;       uses:   sine, cosine                                                  ;
;-----------------------------------------------------------------------------;
proc    makeliss
        push    ax bx cx dx si di       ;save regs

        push    dx
        mov     cx,18                   ;calculate theta increments
        mul     cx                      ;360.0 / 1.8 degrees = 200 points
        mov     di,ax                   ;       save in di
        pop     ax                      ;       max/min for sine
        mov     cx,200                  ;number of points
      @@Loop:
        call    sine                    ;sine
        mov     [si],dx                 ;into pointer
        add     si,6                    ;move to next set of coordinates
        sub     bx,di                   ;increment theta
        jns     @@ThetaOK
        add     bx,3600
       @@ThetaOK:
      loop    @@Loop

        pop     di si dx cx bx ax       ;restore regs
        ret                             ;return
endp    makeliss



;-----------------------------------------------------------------------------;
;       Generates a parametrically defined curve  --  r = a - b*sin(T)        ;
;                                                                             ;
;       in  :   si      pointer to destination for coordinates 200(x,y,z)     ;
;               ax      coefficient of sine(T)                                ;
;               cx      number of pixels                                      ;
;               di      constant "a"  ( a-b*sin(T)  )                         ;
;                                                                             ;
;       out :   x,y coordinates to array (does not write z-coordinate)        ;
;               x = r * cos(T) , y = r * sin(T)                               ;
;                                                                             ;
;       uses:   sine, cosine                                                  ;
;-----------------------------------------------------------------------------;
proc    makeparam
        push    bx cx dx si             ;save regs

        xor     dx,dx
        push    ax
        mov     ax,3600
        div     cx
        mov     [rotinc],ax
        pop     ax

        mov     bx,0                    ;starting theta (ax,di given)
  CalcPointP:
        push    ax                      ;save more regs (in loop)
        push    di                      ;

        call    sine                    ;ax*sin(bx)
        sub     di,dx                   ;r = di-ax*sin(bx)
        mov     ax,di                   ;
        call    sine                    ;x-coor =
        mov     [si],dx                 ;         r * sin(bx)
        call    cosine                  ;y-coor =
        mov     [si+2],dx               ;         r * cos(bx)
        mov     [word ptr si+4],0

        pop     di                      ;restore more regs
        pop     ax                      ;

        add     si,6                    ;increments
        add     bx,[rotinc]             ;
  loop    CalcPointP
        pop     si dx cx bx             ;restore regs
        ret                             ;return
endp    makeparam




;-----------------------------------------------------------------------------;
;       Generates coordinates for a sphere                                    ;
;                                                                             ;
;       in  :   si      pointer to array for coordinates (200x3 words)        ;
;               ax      radius of sphere                                      ;
;                                                                             ;
;       out :   3D coordinates to memory at si                                ;
;                                                                             ;
;       uses:   rotate, sine, cosine                                          ;
;-----------------------------------------------------------------------------;
proc    makesphere
        push    bx cx dx si                     ;save regs

        push    si

        mov     cx,10                           ;pixels per circle
        mov     bx,90                           ;theta starts at 90
      SphCircle:
        call    sine                            ;dx = ax*sin(bx)
        mov     [si],dx                         ;x-coordinate
        call    cosine                          ;dx = ax*cos(bx)
        mov     [si+2],dx                       ;y-coordinate
        mov     [word ptr si+4],0               ;z-coordinate = 0
        add     si,6                            ;increment array pointer
        add     bx,180                          ;theta + 18 degrees
        loop    SphCircle                       ;

        pop     si
        mov     bx,3600
        mov     cx,10
        mov     [rotateMX],0
        mov     [rotateMY],0
        mov     [rotateMZ],0
        call    near ptr rotate2Dfig

        pop     si dx cx bx                     ;restore regs
        ret                                     ;return
endp    makesphere




;-----------------------------------------------------------------------------;
;       Generates coordinates for a sphere                                    ;
;                                                                             ;
;       in  :   si      pointer to array for coordinates (200x3 words)        ;
;               ax      inner radius of torus                                 ;
;               di      outer radius of torus                                 ;
;                                                                             ;
;       out :   3D coordinates to memory at si                                ;
;                                                                             ;
;       uses:   rotate, sine, cosine                                          ;
;-----------------------------------------------------------------------------;
proc    maketorus
        push    bx cx dx si di                  ;save regs

        push    si

        mov     cx,20                           ;pixels per circle
        mov     bx,90                           ;theta starts at 90
      TorCircle:
        call    sine                            ;dx = ax*sin(bx)
        add     dx,di
        mov     [si],dx                         ;x-coordinate
        call    cosine                          ;dx = ax*cos(bx)
        mov     [si+2],dx                       ;y-coordinate
        mov     [word ptr si+4],0               ;z-coordinate = 0
        add     si,6                            ;increment array pointer
        add     bx,450                          ;theta + 36 degrees
        loop    TorCircle                       ;

        pop     si
        mov     bx,3600
        mov     cx,8
        call    near ptr rotate2Dfig

        pop     di si dx cx bx                  ;restore regs
        ret                                     ;return
endp    maketorus



;-----------------------------------------------------------------------------;
;       Rotate a figure specified degrees to make a solid                     ;
;                                                                             ;
;       in  :   bx      degrees rotation (in 1/10 increments)                 ;
;               cx      count of pixels in original 2D figure                 ;
;               si      source coordinate array                               ;
;                                                                             ;
;       out :                                                                 ;
;                                                                             ;
;       uses:                                                                 ;
;-----------------------------------------------------------------------------;
proc    rotate2Dfig
        push    ax bx cx dx
        push    [word ptr yaw]
        push    [word ptr roll]
        push    [word ptr pitch]
        push    [rotate_srce]
        push    [rotate_dest]

        mov     [word ptr yaw],0
        mov     [word ptr roll],0
        mov     [word ptr pitch],0
        mov     [rotate_srce],si
        mov     [rotate_dest],si
        mov     [pixels],cx

        mov     ax,200                          ;TotalPoints / pixels =
        xor     dx,dx                           ;Segments (ax)
        div     cx                              ;
        xchg    ax,bx                           ;TotalRotation / segments =
        div     bx                              ;RotationIncrement
        mov     [rotinc],ax                     ;
        push    bx

        mov     ax,cx                           ;PixelCount into multiplier
        mov     bx,2*3                          ;word(x,y,z) size coefficient
        mul     bx                              ;multiply
        mov     [destinc],ax                    ;increment for destination array

        pop     cx
        dec     cx
        mov     ax,[destinc]
        mov     bx,[rotinc]

      Rotate2D:
        push    cx
        add     [rotate_dest],ax
        add     [word ptr yaw],bx
        mov     cx,[pixels]
        call    rotate
        pop     cx
      loop    Rotate2D

        cmp     [rotateMX],0
        jz      Rot2Dtrans1
        mov     bx,0
        mov     dx,[rotateMX]
        call    rotate2Dtrans
      Rot2Dtrans1:
        cmp     [rotateMY],0
        jz      Rot2Dtrans2
        mov     bx,2
        mov     dx,[rotateMY]
        call    rotate2Dtrans
      Rot2Dtrans2:
        cmp     [rotateMZ],0
        jz      Rot2Dtrans3
        mov     bx,4
        mov     dx,[rotateMZ]
        call    rotate2Dtrans
      Rot2Dtrans3:

        pop     [rotate_dest]
        pop     [rotate_srce]
        pop     [word ptr pitch]
        pop     [word ptr roll]
        pop     [word ptr yaw]
        pop     dx cx bx ax
        ret
endp    rotate2Dfig

proc    rotate2Dtrans
        add     bx,[rotate_srce]
        mov     cx,POINTS
      @@RotTrans:
        add     [bx],dx
        add     bx,6
      loop    @@RotTrans
        ret
endp    rotate2Dtrans

        end

