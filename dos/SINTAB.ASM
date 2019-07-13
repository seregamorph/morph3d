.MODEL tiny
.286
Ideal
Include "globals.3dt"


UDATASEG
sin     dw      3600+900 dup(?)
cos     =       sin+900*2


CODESEG
        org     0h


;-----------------------------------------------------------------------------;
;       Initialize the sine/cosine table with values generated using a        ;
;       Taylor expansion of sine to the first four non-zero terms :           ;
;                                                                             ;
;               sin(t) = t - t^3/3! + t^5/5! - t^7/7!                         ;
;                                                                             ;
;       In the algorythm, 2^14 (16384) is equivalent to one; thus PI is       ;
;       equivalent to 2^14 * 3.141592654 = 51471.  This value was not         ;
;       reduced to minimize rounding error.                                   ;
;                                                                             ;
;       The are 3600 values to a period of sine (or cosine) thus 90 degress   ;
;       is equivalent to 900, 180 degrees to 1800, etc.                       ;
;                                                                             ;
;       The routine need only be called once, no registers are destroyed.     ;
;-----------------------------------------------------------------------------;
proc    InitSinCos
        pusha                           ;save registers (for the hell of it)

        mov     cx,0                    ;cx IS theta (it's buff)
    @@ThetaLoop:
        xor     dx,dx                   ;
        mov     ax,51471                ;2^14 * 3.141592654 = 51471
        mul     cx                      ;  ==(important ^14)
        mov     bx,1800                 ;wow, its a ratio of cx [0,1800)
        div     bx                      ;to 51471
        xor     dx,dx                   ;

        mov     si,ax                   ;SI will be sine value (starts at t)
        mov     bx,ax                   ;BX is for t^2, t^3, etc. purposes
        mov     di,1                    ;DI is factorial incrementaion

        call    isc_mul                 ;      ax = t^2/2!
        call    isc_mul                 ;      ax = t^3/3!
        sub     si,ax                   ;si - ax
        call    isc_mul                 ;      ax = t^4/4!
        call    isc_mul                 ;      ax = t^5/5!
        add     si,ax                   ;si + ax
        call    isc_mul                 ;      ax = t^6/6!
        call    isc_mul                 ;      ax = t^7/7!
        sub     si,ax                   ;si - ax

        sal     si,1                    ;fills si to use 15 bits (+ sign bit)

        mov     bx,cx                   ;(bx=)cx is currrent theta count
        sal     bx,1                    ;data in words (table offset)
        add     bx,offset sin           ;add location of table
        mov     [bx],si                 ;store value

        mov     bx,1800                 ;180 degrees
        sub     bx,cx                   ;- theta (varries up to 90 degrees)
        sal     bx,1                    ;
        add     bx,offset sin           ;
        mov     [bx],si                 ;store mirror of sin value

        inc     cx                      ;increment theta
        cmp     cx,900                  ;check if still less than 90 degrees
    jle     @@ThetaLoop

        mov     ax,ds                   ;load extended stack with data stack
        mov     es,ax                   ;for stosw purposes

        mov     si,offset sin           ;source        [ds:si]
        mov     di,offset sin+1800*2    ;destination   [es:di]
        mov     cx,1800                 ;count
    @@WaveNegate:
        lodsw                           ;second half of sine wave
        neg     ax                      ;is a negation of the
        stosw                           ;first half of the wave
    loop      @@WaveNegate

        mov     si,offset sin           ;copy 90 degrees onto the end
        mov     di,offset sin+3600*2    ;for speed optimization
        mov     cx,900                  ;of cosine
        rep     movsw                   ;

        popa                            ;restore registers
        ret                             ;return
endp    InitSinCos

proc    isc_mul
        xor     dx,dx                   ;clear overflow
        mul     bx                      ;multiply by t
        shl     ax,1                    ;  rotate top three bits
        rcl     dx,1                    ;  of ax into bottom three of dx
        shl     ax,1                    ;  ( originally a 14 bit in 16 bit num,
        rcl     dx,1                    ;    now a 28 bit in a 32 bit num,
                                        ;    reorient the top 14 bits to fill
                                        ;    16 bits )
        mov     ax,dx                   ;and store the value back into ax
        xor     dx,dx                   ;
        inc     di                      ;increment factorial value
        div     di                      ;and divide
        ret                             ;return
endp    isc_mul




;-----------------------------------------------------------------------------;
;       Multiply a number in ax by a sin in bx          dx = ax * sin(bx)     ;
;               ax = max height of sine wave                                  ;
;               bx = theta [0,3600) == one full period                        ;
;       Returns modified number in dx                                         ;
;-----------------------------------------------------------------------------;
proc    sine
        push    ax bx                   ;save registers

        sal     ax,1                    ;double the coef,  -0.5 <= sin <= 0.5
        sal     bx,1                    ;table in words
        imul    [word ptr sin+bx]       ;imul, signed binary multiplication

        pop     bx ax                   ;restore registers
        ret                             ;return
endp    sine


;-----------------------------------------------------------------------------;
;-----------------------------------------------------------------------------;
proc    sinsq
        push    ax bx                   ;save registers

        sal     ax,1                    ;
        sal     bx,1                    ;
        imul    [word ptr sin+bx]       ;
        mov     ax,dx                   ;
        sal     ax,1                    ;
        imul    [word ptr sin+bx]       ;

        pop     bx ax                   ;restore registers
        ret                             ;return
endp    sinsq




;-----------------------------------------------------------------------------;
;       Multiply a number in ax by a cos in bx          dx = ax * cos(bx)     ;
;               ax = max height of cosine wave                                ;
;               bx = theta [0,3600) == one full period                        ;
;       Returns modified number in dx                                         ;
;-----------------------------------------------------------------------------;
proc    cosine
        push    ax bx                   ;save original theta

        sal     ax,1                    ;Duplicate of SINE funtion
        sal     bx,1                    ;       it's not very large in size
        imul    [word ptr cos+bx]       ;       and it makes COSINE faster

        pop     bx ax                   ;restore original theta
        ret                             ;return
endp    cosine



;-----------------------------------------------------------------------------;
;-----------------------------------------------------------------------------;
proc    cossq
        push    ax bx                   ;save original theta

        sal     ax,1                    ;Duplicate of the SINSQ function
        sal     bx,1                    ;
        imul    [word ptr cos+bx]       ;       it's not very large in size
        mov     ax,dx                   ;       and it somewhat optimizes
        sal     ax,1                    ;       for speed
        imul    [word ptr cos+bx]       ;

        pop     bx ax                   ;restore original theta
        ret                             ;return
endp    cossq

end
