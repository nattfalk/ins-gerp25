************************************************************
        SECTION Logo, CODE_P

Logo_Init:
	lea.l	$dff000,a6

	; move.l	DrawBuffer,a0
        ; move.l  #(256<<6)+(320>>4),d0
        ; jsr	BltClr
	; jsr	WaitBlitter

        ; move.l  DrawBuffer,a0
        lea.l   L_Logo,a0
        lea.l   L_BplPtrs,a1
        moveq   #5-1,d7
.setBpls:
        move.l  a0,d0
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        adda.l  #320*64>>3,a0
        adda.l  #8,a1
        dbf     d7,.setBpls

    	move.l	#L_Copper,$80(a6)

        jsr     InitFade

;         lea.l   L_LogoPal,a0
;         lea.l   L_CopCols,a1
;         moveq   #32-1,d7
; .setCols:
;         move.w  (a0)+,2(a1)
;         addq.l  #4,a1
;         dbf     d7,.setCols

        rts

************************************************************
Logo_Run:

        cmp.w   #0,L_FadeStage
        bne.s   .nextFade
        lea.l   L_LogoFromPal(pc),a0
        lea.l   L_LogoPal(pc),a1
        lea.l   L_CopCols,a2
        moveq   #64,d0
        moveq   #32-1,d1
        jsr     Fade
        bra.s   .done

.nextFade:
        lea.l   L_LogoPal(pc),a0
        lea.l   L_LogoFromPal(pc),a1
        lea.l   L_CopCols,a2
        moveq   #64,d0
        moveq   #32-1,d1
        jsr     Fade

.done:  rts

************************************************************
Logo_Interrupt:
        addq.l  #1,L_LocalFrameCounter

        cmp.l   #100,L_LocalFrameCounter
        bmi.s   .skip
        cmp.l   #250-64,L_LocalFrameCounter
        bgt     .skip
        jsr     InitFade
        move.w  #1,L_FadeStage
.skip:
        rts

************************************************************
        even
L_LocalFrameCounter:    dc.l    0
L_FadeStage:            dc.w    0

L_LogoFromPal:  dcb.w   32,$fff
L_LogoPal:      incbin	"data/graphics/logo-320x64x5.pal"

************************************************************
        SECTION L_Copper, DATA_C
L_Copper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0102,$0000
	dc.w	$0104,$0000
	dc.w	$0108,$0000
	dc.w	$010a,$0000
        dc.w    $0100,$0200

	dc.w	$0180,$0012

        dc.w    $8c01,$fffe
L_CopCols:
	dc.w	$0180,$0fff,$0182,$0fff,$0184,$0fff,$0186,$0fff
	dc.w	$0188,$0fff,$018a,$0fff,$018c,$0fff,$018e,$0fff
	dc.w	$0190,$0fff,$0192,$0fff,$0194,$0fff,$0196,$0fff
	dc.w	$0198,$0fff,$019a,$0fff,$019c,$0fff,$019e,$0fff
	dc.w	$01a0,$0fff,$01a2,$0fff,$01a4,$0fff,$01a6,$0fff
	dc.w	$01a8,$0fff,$01aa,$0fff,$01ac,$0fff,$01ae,$0fff
	dc.w	$01b0,$0fff,$01b2,$0fff,$01b4,$0fff,$01b6,$0fff
	dc.w	$01b8,$0fff,$01ba,$0fff,$01bc,$0fff,$01be,$0fff

        dc.w    $8d01,$fffe
        dc.w    $0100,$5200

L_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000

        dc.b    $8c+64,$01
        dc.w    $fffe
        dc.w    $0100,$0200
	dc.w	$0180,$0012

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

L_Logo:	incbin	"data/graphics/logo-320x64x5.raw"
