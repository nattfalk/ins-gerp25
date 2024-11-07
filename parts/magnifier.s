************************************************************
Magnifier_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #((256<<6)+(320>>4)),d0
        moveq   #2-1,d7
.clear: jsr	BltClr
        adda.l  #320*256>>3,a0
        dbf     d7,.clear
	jsr	WaitBlitter

        move.l  DrawBuffer,a0
        lea     MainBplPtrs+2,a1
        move.l  #(320*256)>>3,d0
        moveq	#2-1,d1
        jsr     SetBpls

        move.l  DrawBuffer,a0

        ; Draw checker pattern
        REPT    256/16
        REPT    8
        REPT    320/32
        move.l  #$ff00ff00,(a0)+
        ENDR
        ENDR
        REPT    8
        REPT    320/32
        move.l  #$00ff00ff,(a0)+
        ENDR
        ENDR
        ENDR

    	move.l	#MainCopper,$80(a6) *
        rts

************************************************************
Magnifier_Run:

;         lea.l   Mag_Tab(pc),a0
;         move.w  #48*32-1,d7
; .loop:
;         move.w  (a0),d0
;         btst    #1,d0
;         beq.s   .skip
; .skip:  or.w    #$f0,d0
;         move.w  d0,(a0)
;         dbf     d7,.loop
; .done:

;         move.l  #10,d0 50                                                               
;         tst.b   d0
        
        lea.l   Magnifier_lut,a0
        move.l  DrawBuffer,a1   ; src
        lea.l   40*256(a1),a2   ; dest

        moveq   #0,d4           ; y dest

        moveq   #32-1,d7
.yl:
        moveq   #0,d3           ; x dest
        moveq   #32-1,d6
.xl:

        move.w  (a0)+,d0        ; x src
        move.w  (a0)+,d1        ; y src

        move.w  d0,d2
        lsr.w   #3,d0
        not     d2
        and.w   #7,d2
        mulu    #40,d1
        add.w   d0,d1

        move.b  (a1,d1.w),d1
        and.b   d2,d1

        lsr.b   d2,d1


        dbf     d6,.xl

        dbf     d7,.yl


        rts

************************************************************
Magnifier_Interrupt:

.skip:
        rts

************************************************************

; Mag_Tab:        dc.w    0
        include "data/magnifier-lut.s"
