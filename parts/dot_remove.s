************************************************************
DR_NrColumns    = 20
DR_NrRows       = 4

************************************************************
        SECTION DotRemove, CODE_P
DotRemove_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr	BltClr
	jsr	WaitBlitter

        move.l  DrawBuffer,a0
        move.l  ViewBuffer,a1
        lea.l   96*40(a0),a0
        lea.l   96*40(a1),a1
        move.w  #64*10-1,d7
.fill:  move.l  #-1,(a0)+
        move.l  #-1,(a1)+
        dbf     d7,.fill

        move.l  DrawBuffer,a0
	lea	DR_BplPtrs+2,a1
        moveq   #0,d0
	moveq	#1-1,d1
	jsr	SetBpls

    	move.l	#DR_Copper,$80(a6)
        rts

************************************************************
DotRemove_Run:
	movem.l	DrawBuffer,a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
	lea	DR_BplPtrs+2,a1
        moveq   #0,d0
	moveq	#1-1,d1
	jsr	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	jsr	BltClr
	jsr	WaitBlitter

        bsr     DotRemove_Wave
        bsr     DotRemove_RenderBlocks

        rts

************************************************************
DotRemove_Interrupt:
        addq.l  #1,DR_LocalFrameCounter

        move.l  DR_LocalFrameCounter(pc),d0

        cmp.w   #120,d0
        bgt.s   .wave
        bsr.s   .dotEffect
        bra     .done

.wave:  cmp.w   #256,d0
        bgt.s   .waveAndTwirl
        bsr.s   .waveEffect
        bra     .done

.waveAndTwirl:
        cmp.w   #500,d0
        bgt.s   .done
        bsr.s   .scaleDownEffect
        bsr.s   .waveEffect
        bra     .done

.done:  rts

.scaleDownEffect:
        move.l  DR_LocalFrameCounter(pc),d0
        and.w   #3,d0
        bne.s   .scaleDoneExit

        tst.w   DR_ScaleFactor
        beq.s   .scaleDoneExit
        subq.w  #1,DR_ScaleFactor
.scaleDoneExit:
        rts

.waveEffect:
        lea.l   DR_WaveSinIndex(pc),a0
        move.l  d7,-(sp)
        move.w  DR_Columns(pc),d7
.inc:   add.w   #30,(a0)+
        dbf     d7,.inc
        move.l  (sp)+,d7

        cmp.w   #DR_NrColumns-1,DR_Columns
        beq     .waveExit
        and.w   #3,d0
        bne.s   .waveExit

        addq.w  #1,DR_Columns
.waveExit:
        rts

.dotEffect:
        and.l   #1,d0
        bne.s   .dotEffectExit

        lea.l   DR_RowIndex(pc),a0
        cmp.w   #60*2,6(a0)
        beq.s   .dotEffectExit
        addq.w  #2,(a0)+
        addq.w  #2,(a0)+
        addq.w  #2,(a0)+
        addq.w  #2,(a0)
.dotEffectExit:
        rts

************************************************************
        even
DotRemove_Wave:
        lea.l   DR_WaveSinIndex(pc),a2
        tst.w   (a2)
        beq     .done

        lea.l   Costab,a0
        lea.l   DR_Positions(pc),a1

        moveq   #DR_NrColumns-1,d7
.move:  move.w  (a2)+,d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d1
        asr.w   #8,d1
        asr.w   #2,d1

OFFS    SET     0
        REPT    DR_NrRows
        move.w  OFFS+4(a1),d2
        muls    d1,d2
        asr.w   #5,d2

        move.w  d2,OFFS+6(a1)
OFFS    SET     OFFS+(8*20)
        ENDR        

        addq.l  #8,a1
        dbf     d7,.move
.done:  rts

DotRemove_RenderBlocks:
        move.l  a6,-(sp)

        move.l  DrawBuffer,a0
        lea.l   DR_Positions(pc),a1
        lea.l   DR_RowIndex(pc),a2
        lea.l   DR_DotIndexTable(pc),a3
        lea.l   DotMask,a4
        lea.l   Mulu40,a6

        moveq   #DR_NrRows-1,d7
.renderRow:
        move.w  (a2)+,d0                ; Block index
        moveq   #DR_NrColumns-1,d6
.renderBlock:
        move.w  (a3,d0.w),d1            ; Offset to dot mask

        move.l  (a1)+,d2
        add.w   #160-8,d2
        move.w  d2,d4
        move.l  (a1)+,d3

        move.w  DR_ScaleFactor,d5
        muls    d5,d3
        asr.l   #5,d3

        add.w   #128-8,d3
        lsr.w   #3,d2
        and.w   #$fffe,d2
        and.w   #15,d4

        add.w   d3,d3
        move.w  (a6,d3.w),d3

        add.w   d2,d3

        lea.l   (a0,d3.w),a5

I       SET     0
II      SET     0
        REPT    16
        move.l  II(a4,d1.w),d5
        lsr.l   d4,d5
        or.l    d5,I(a5)
I       SET     I+40
II      SET     II+4
        ENDR

        addq.w  #2,d0
        dbf     d6,.renderBlock
        dbf     d7,.renderRow

        move.l  (sp)+,a6
        rts

************************************************************
        even

DR_LocalFrameCounter:   dc.l    0

DR_ScaleFactor:         dc.w    32

DR_WaveSinIndex:        dcb.w   DR_NrColumns,0
DR_Columns:             dc.w    0

DR_RowIndex:            dc.w    0,6,12,8
DR_DotIndexTable:       dcb.w   20,0
                        dc.w    1*16*4
                        dc.w    2*16*4
                        dc.w    3*16*4
                        dc.w    4*16*4
                        dc.w    5*16*4
                        dc.w    6*16*4
                        dc.w    5*16*4
                        dc.w    4*16*4
                        dc.w    3*16*4
                        dc.w    2*16*4
                        dc.w    1*16*4

                        dc.w    0*16*4
                        dc.w    1*16*4
                        dc.w    2*16*4
                        dc.w    3*16*4
                        dc.w    4*16*4
                        dc.w    5*16*4
                        dc.w    6*16*4
                        dc.w    5*16*4
                        dc.w    4*16*4
                        dc.w    3*16*4
                        dc.w    2*16*4
                        dc.w    1*16*4

                        dc.w    0*16*4
                        dc.w    1*16*4
                        dc.w    2*16*4
                        dc.w    3*16*4
                        dc.w    4*16*4
                        dc.w    5*16*4
                        dc.w    6*16*4
                        dcb.w   32,6*16*4
                        dc.l    0

DR_Positions:           
Y                       SET     -32+8
                        REPT    DR_NrRows
X                       SET     160-16+8
                        REPT    DR_NrColumns
                        dc.w    X,X,Y,Y
X                       SET     X-16
                        ENDR
Y                       SET     Y+16
                        ENDR

************************************************************
        SECTION DR_Copper, CODE_C
DR_Copper:
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

	dc.w	$0180,$0222
	dc.w	$0182,$0fff

        dc.w    $0100,$1200
DR_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe
