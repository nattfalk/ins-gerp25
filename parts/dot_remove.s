************************************************************
        SECTION DotRemove, CODE_P
DotRemove_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #(320*256)>>4,d0
        jsr	BltClr
	jsr	WaitBlitter

        move.l  DrawBuffer,a0
        lea.l   96*40(a0),a0
        move.w  #64*10-1,d7
.fill:  move.l  #-1,(a0)+
        dbf     d7,.fill

        lea.l   DR_BplPtrs,a0
        move.l  DrawBuffer,d0
        move.w  d0,6(a0)
        swap    d0
        move.w  d0,2(a0)

    	move.l	#DR_Copper,$80(a6)
        rts

************************************************************
DotRemove_Run:

        move.l  DrawBuffer,a0
        lea.l   96*40(a0),a0            ; Initial screen y position, 96

        lea.l   DotMask,a1
        lea.l   DR_DotIndexTable(pc),a2
        lea.l   DR_RowIndex(pc),a3

        moveq   #4-1,d7
.renderRow:
        move.w  (a3)+,d0                ; Block index
        move.w  #38,d2                  ; X. Right border min one block. Render right to left
        moveq   #20-1,d6
.renderBlock:
        move.w  (a2,d0.w),d1            ; Offset to dot mask

        lea.l   (a0,d2.w),a4
I       SET     0
II      SET     0
        REPT    16
        move.w  II(a1,d1.w),I(a4)
I       SET     I+40
II      SET     II+2
        ENDR

        subq.w  #2,d2
        addq.w  #2,d0
        dbf     d6,.renderBlock

        lea.l   16*40(a0),a0

        dbf     d7,.renderRow

        rts

************************************************************
DotRemove_Interrupt:
        addq.l  #1,DR_LocalFrameCounter

        move.l  DR_LocalFrameCounter(pc),d0
        and.l   #1,d0
        bne.s   .skip

        lea.l   DR_RowIndex(pc),a0
        cmp.w   #48*2,6(a0)
        beq.s   .skip
        addq.w  #2,(a0)+
        addq.w  #2,(a0)+
        addq.w  #2,(a0)+
        addq.w  #2,(a0)

.skip:
        rts

************************************************************
        even

DR_LocalFrameCounter:   dc.l    0

DR_RowIndex:            dc.w    0,4,8,12
DR_DotIndexTable:       dcb.w   20,0
                        dc.w    1*16*2
                        dc.w    2*16*2
                        dc.w    3*16*2
                        dc.w    4*16*2
                        dc.w    5*16*2
                        dc.w    6*16*2
                        dc.w    5*16*2
                        dc.w    4*16*2
                        dc.w    3*16*2
                        dc.w    2*16*2
                        dc.w    1*16*2

                        dc.w    0*16*2
                        dc.w    1*16*2
                        dc.w    2*16*2
                        dc.w    3*16*2
                        dc.w    4*16*2
                        dc.w    5*16*2
                        dc.w    6*16*2
                        dcb.w   30,6*16*2
                        dc.l    0

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
