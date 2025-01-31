************************************************************
DR_NrColumns    = 20
DR_NrRows       = 4

************************************************************
        SECTION DotRemove, CODE_P

        include "include/macros.i"

DotRemove_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #(256<<6)+(320>>4),d0
        jsr	BltClr
        WAITBLIT

        move.l  DrawBuffer,a0
        lea.l   96*40(a0),a0
        move.w  #64*10-1,d7
.fill:  move.l  #-1,(a0)+
        dbf     d7,.fill

        move.l  ViewBuffer,a0
        move.w  #256*10-1,d7
.fill2: move.l  #-1,(a0)+
        dbf     d7,.fill2

        lea.l   DR_Background,a0
	lea	DR_BplPtrs+2,a1
        move.l  #320*256>>3,d0
	moveq	#4-1,d1
	jsr	SetBpls

        move.l  ViewBuffer,a0
	lea	DR_BplPtrs+(4*8)+2,a1
        moveq   #0,d0
	moveq	#1-1,d1
	jsr	SetBpls

    	move.l	#DR_Copper,$80(a6)

        jsr     InitFade

        rts

************************************************************
DotRemove_Run:
        cmp.l   #33,DR_LocalFrameCounter
        bge     .doDots

        cmp.l   #16,DR_LocalFrameCounter
        bge.s   .fadeDone

        lea.l   DR_BackgroundFromColor(pc),a0
        lea.l   DR_BackgroundToColor(pc),a1
        lea.l   DR_CopCols,a2
        moveq   #14,d0
        moveq   #1-1,d1
        jsr     Fade

.fadeDone:
        move.w  DR_ClearYPos(pc),d0
        cmp.w   #96,d0
        beq.s   .clearDone

        move.l  ViewBuffer,a0
        move.w  d0,d1
        mulu    #40,d0
        lea.l   (a0,d0.w),a1
 
        move.w  #253,d2
        sub.w   d1,d2
        mulu    #40,d2
        lea.l   (a0,d2.w),a0

        moveq   #3*10-1,d7
.clear: clr.l   (a1)+
        clr.l   (a0)+
        dbf     d7,.clear
        addq.w  #3,DR_ClearYPos

.clearDone:
        cmp.w   #48,DR_ClearYPos
        bne.s   .doFade2
        jsr     InitFade
.doFade2:
        cmp.w   #48,DR_ClearYPos
        blo.s   .skipFade

        lea.l   DR_FromCols(pc),a0
        lea.l   DR_ToCols(pc),a1
        lea.l   DR_CopCols2,a2
        moveq   #16,d0
        moveq   #16-1,d1
        jsr     Fade
.skipFade:
        bra     .done
.doDots:

        cmp.l   #550,DR_LocalFrameCounter
        bgt.s   .initFadeDone
        cmp.l   #550,DR_LocalFrameCounter
        bne.s   .initFadeDone
        jsr     InitFade

.initFadeDone:
        cmp.l   #550,DR_LocalFrameCounter
        blo.s   .noFadeOut

        lea.l   DR_ToCols(pc),a0
        lea.l   DR_ToCols2(pc),a1
        lea.l   DR_CopCols2,a2
        moveq   #48,d0
        moveq   #16-1,d1
        jsr     Fade
        bra.s   .done

.noFadeOut:
	movem.l	DrawBuffer,a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
	lea	DR_BplPtrs+(4*8)+2,a1
        moveq   #0,d0
	moveq	#1-1,d1
	jsr	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	jsr	BltClr
        WAITBLIT

        bsr     DotRemove_RenderBlocks

.done:
        addq.l  #1,DR_LocalFrameCounter
        rts

************************************************************
DotRemove_Interrupt:

        move.l  DR_LocalFrameCounter(pc),d0

        cmp.w   #32,d0
        ble.s   .done
        cmp.w   #99-10,d0
        ble     .dotEffect
        
        cmp.w   #100-10,d0
        beq.s   .resetDots1
        cmp.w   #189-10,d0
        ble     .dotEffect
        
        cmp.w   #190-10,d0
        beq.s   .resetDots2
        cmp.w   #289-10,d0
        ble     .dotEffect
        
        cmp.w   #290-10,d0
        beq     .resetDots3
        cmp.w   #399-25,d0
        ble     .dotEffect
        
        cmp.w   #400-25,d0
        beq     .resetDots4
        cmp.w   #499-25,d0
        ble     .dotEffect
        
        cmp.w   #500-25,d0
        beq     .resetDots5
        cmp.w   #699-25,d0
        ble     .dotEffect

.done:  rts

.resetDots1:
        move.w  #-64,DR_TargetYPos
        move.w  #2,DR_IndexAddValue

        clr.w   DR_Counter
        bra     .dotEffect

.resetDots2:
        clr.w   DR_TargetYPos
        move.w  #-2,DR_IndexAddValue

        clr.w   DR_Counter
        bra     .dotEffect

.resetDots3:
        move.w  #64,DR_TargetYPos
        move.w  #2,DR_IndexAddValue

        clr.w   DR_Counter
        bra     .dotEffect

.resetDots4:
        move.w  #-64,DR_TargetYPos
        move.w  #-2,DR_IndexAddValue

        clr.w   DR_Counter
        bra     .dotEffect

.resetDots5:
        clr.w   DR_TargetYPos

        move.w  #4,DR_IndexAddValue
        clr.w   DR_Counter
        bra     .dotEffect

.scaleDownEffect:
        move.l  DR_LocalFrameCounter(pc),d0
        and.w   #1,d0
        bne.s   .scaleDoneExit

        tst.w   DR_ScaleFactor
        beq.s   .scaleDoneExit
        subq.w  #1,DR_ScaleFactor
.scaleDoneExit:
        rts

.dotEffect:
        cmp.l   #480,DR_LocalFrameCounter
        blo.s   .noScale

        bsr     .scaleDownEffect

.noScale:
        move.w  DR_YPos(pc),d1
        move.w  DR_TargetYPos(pc),d2
        cmp.w   d1,d2
        beq.s   .atTarget
        cmp.w   d1,d2
        bmi.s   .subY
        addq.w  #4,DR_YPos
        bra.s   .atTarget
.subY:  subq.w  #4,DR_YPos
.atTarget:
        move.l  DR_LocalFrameCounter(pc),d0
        and.l   #1,d0
        bne.s   .dotEffectExit

        add.w   #1,DR_Counter
        cmp.w   #60,DR_Counter
        beq.s   .dotEffectExit
        lea.l   DR_RowIndex(pc),a0
        move.w  DR_IndexAddValue(pc),d0
        add.w   d0,(a0)+
        add.w   d0,(a0)+
        add.w   d0,(a0)+
        add.w   d0,(a0)
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
        move.l  DR_PositionsPtr(pc),a1
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
        move.l  (a1)+,d3

        move.w  DR_ScaleFactor,d5
        muls    d5,d3
        asr.l   #5,d3

        add.w   DR_YPos(pc),d3

        add.w   #128-8,d3
        lsr.w   #3,d2
        and.w   #$fffe,d2

        add.w   d3,d3
        move.w  (a6,d3.w),d3

        add.w   d2,d3

        lea.l   (a0,d3.w),a5

I       SET     0
II      SET     0
        REPT    16
        move.l  II(a4,d1.w),d5
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

DR_BackgroundFromColor: dc.w    $0fff
DR_BackgroundToColor:   dc.w    $0012

DR_FromCols:            dcb.w   16,$0fff
DR_ToCols:              dc.w	$0fff,$0ccc,$0aaa,$0888,$0666,$0777,$0999,$0bbb
                        dc.w	$0ddd,$0fff,$0eee,$0ccc,$0aaa,$0888,$0666,$0444
DR_ToCols2:             dcb.w   16,$0456

DR_ClearYPos:           dc.w    0

DR_ScaleFactor:         dc.w    32
DR_WaveSinIndex:        dcb.w   DR_NrColumns,0
DR_Columns:             dc.w    0

DR_YPos:                dc.w    0
DR_TargetYPos:          dc.w    0

DR_Counter:             dc.w    0
DR_IndexAddValue:       dc.w    2
DR_RowIndex:            dc.w    0,6,12,8

DR_DotIndexTablePre:    dcb.w   32,6*16*4
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
                        dc.w    5*16*4
                        dc.w    4*16*4
                        dc.w    3*16*4
                        dc.w    2*16*4
                        dc.w    1*16*4

DR_DotIndexTable:       dcb.w   28,0
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

                        dcb.w   96,6*16*4
                        dc.l    0

DR_PositionsPtr:        dc.l    DR_Positions
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

DR_CopCols:
	dc.w	$0180,$0fff,$0182,$0012,$0184,$0012,$0186,$0012
	dc.w	$0188,$0012,$018a,$0012,$018c,$0012,$018e,$0012
	dc.w	$0190,$0012,$0192,$0012,$0194,$0012,$0196,$0012
	dc.w	$0198,$0012,$019a,$0012,$019c,$0012,$019e,$0012
DR_CopCols2:
	dc.w	$01a0,$0fff,$01a2,$0fff,$01a4,$0fff,$01a6,$0fff
	dc.w	$01a8,$0fff,$01aa,$0fff,$01ac,$0fff,$01ae,$0fff
	dc.w	$01b0,$0fff,$01b2,$0fff,$01b4,$0fff,$01b6,$0fff
	dc.w	$01b8,$0fff,$01ba,$0fff,$01bc,$0fff,$01be,$0fff

DR_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000
        
        dc.w    $0100,$5200

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

        SECTION DR_Data, DATA_C

DR_Background:  incbin  "data/graphics/dot_bkg_320x256x4.raw"