************************************************************
        SECTION HorizontalStrips, CODE_P
HorizontalStrips_Init:
	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #(4<<6)+(320>>4),d0
        jsr	BltClr
	jsr	WaitBlitter

        move.l  DrawBuffer,a0
        lea.l   HS_BplPtrs,a1
        moveq   #4-1,d7
.setBpls:
        move.l  a0,d0
        move.w  d0,6(a1)
        swap    d0
        move.w  d0,2(a1)
        adda.l  #40,a0
        adda.l  #16,a1
        dbf     d7,.setBpls

        lea.l   HS_ShadeTable(pc),a0
        move.w  #$0012,d0
        move.w  #$0fff,d1
        move.w  #74,d2
        jsr     CreateShadeTable

    	move.l	#HS_Copper,$80(a6)
        rts

************************************************************
HorizontalStrips_Run:
        ; Set shade
        lea.l   HS_BplPtrs,a0
        lea.l   HS_ShadeTablePtrs(pc),a1
        moveq   #4-1,d7
.setColor:
        move.l  (a1)+,a2
        move.w  (a2),10(a0)
        lea.l   16(a0),a0
        dbf     d7,.setColor

        ; Draw bars
        move.l  DrawBuffer,a0

        lea.l   HS_EaseInLeftToRight,a1
        lea.l   HS_EaseInRightToLeft,a2
        lea.l   HS_OldPos,a3
        lea.l   HS_Index,a4

        moveq   #2-1,d7
.outerLoop:
        ; strip 1+3 - right to left
        move.w  (a4)+,d1
        cmp.w   #-2,d1
        beq.s   .next1
        move.w  (a2,d1.w),d1
        
        move.w  (a3),d0
        sub.w   d1,d0
        move.w  d1,(a3)+

.plot:  move.w  d1,d2
        not     d2
        and.b   #7,d2
        move.w  d1,d3
        lsr.w   #3,d3
        bset.b  d2,(a0,d3.w)
        addq.w  #1,d1
        dbf     d0,.plot

.next1: ; strip 2+4 - left to right
        move.w  (a4)+,d1
        cmp.w   #-2,d1
        beq.s   .next2
        move.w  (a1,d1.w),d1
        
        move.w  (a3),d0
        move.w  d1,(a3)+
        sub.w   d0,d1

.plot2: move.w  d0,d2
        not     d2
        and.b   #7,d2
        move.w  d0,d3
        lsr.w   #3,d3
        bset.b  d2,40(a0,d3.w)
        addq.w  #1,d0
        dbf     d1,.plot2

.next2:
        lea.l   80(a0),a0
        dbf     d7,.outerLoop
.done:
        rts

************************************************************
HorizontalStrips_Interrupt:
        addq.l  #1,HS_LocalFrameCounter

        cmp.w   #74*2,HS_Index
        beq.s   .bar1done
        addq.w  #2,HS_Index
        add.l   #2,HS_ShadeTablePtrs
.bar1done:

        cmp.l   #5,HS_LocalFrameCounter
        bmi     .skip
        cmp.w   #74*2,HS_Index+2
        beq.s   .bar2done
        addq.w  #2,HS_Index+2
        add.l   #2,HS_ShadeTablePtrs+4
.bar2done:

        cmp.l   #10,HS_LocalFrameCounter
        bmi     .skip
        cmp.w   #74*2,HS_Index+4
        beq.s   .bar3done
        addq.w  #2,HS_Index+4
        add.l   #2,HS_ShadeTablePtrs+8
.bar3done:

        cmp.l   #15,HS_LocalFrameCounter
        bmi     .skip
        cmp.w   #74*2,HS_Index+6
        beq.s   .bar4done
        addq.w  #2,HS_Index+6
        add.l   #2,HS_ShadeTablePtrs+12
.bar4done:

.skip:
        rts

************************************************************
        even

HS_LocalFrameCounter:   dc.l    0
HS_OldPos:
        dc.w    319,0,319,0
HS_Index:
        dc.w    0,-2,-2,-2
HS_EaseInLeftToRight:
        dc.w    0, 8, 16, 25, 33, 41, 49, 56
        dc.w    64, 72, 79, 86, 94, 101, 108, 115
        dc.w    121, 128, 135, 141, 147, 154, 160, 166
        dc.w    172, 177, 183, 188, 194, 199, 204, 209
        dc.w    214, 219, 224, 228, 233, 237, 242, 246
        dc.w    250, 254, 258, 261, 265, 268, 272, 275
        dc.w    278, 281, 284, 287, 289, 292, 294, 297
        dc.w    299, 301, 303, 305, 307, 308, 310, 311
        dc.w    313, 314, 315, 316, 317, 317, 318, 319
        dc.w    319, 319, 319
HS_EaseInRightToLeft:
        dc.w    319, 311, 303, 294, 286, 278, 270, 263
        dc.w    255, 247, 240, 233, 225, 218, 211, 204
        dc.w    198, 191, 184, 178, 172, 165, 159, 153
        dc.w    147, 142, 136, 131, 125, 120, 115, 110
        dc.w    105, 100, 95, 91, 86, 82, 77, 73
        dc.w    69, 65, 61, 58, 54, 51, 47, 44
        dc.w    41, 38, 35, 32, 30, 27, 25, 22
        dc.w    20, 18, 16, 14, 12, 11, 9, 8
        dc.w    6, 5, 4, 3, 2, 2, 1, 0
        dc.w    0, 0, 0
HS_ShadeTable:
        ds.w    74
        dcb.w   8,$fff
HS_ShadeTablePtrs:
        dc.l    HS_ShadeTable,HS_ShadeTable,HS_ShadeTable,HS_ShadeTable

************************************************************
        SECTION HS_Copper, CODE_C
HS_Copper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0102,$0000
	dc.w	$0104,$0000
	dc.w	$0108,-40
	dc.w	$010a,$0000
        dc.w    $0100,$0200

	dc.w	$0180,$0012
	dc.w	$0182,$0012

        dc.w    $8c01,$fffe
        dc.w    $0100,$1200
HS_BplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000,$0182,$0012
        dc.b    $8c+16,$01
        dc.w    $fffe
	dc.w	$00e0,$0000,$00e2,$0000,$0182,$0012
        dc.b    $8c+32,$01
        dc.w    $fffe
	dc.w	$00e0,$0000,$00e2,$0000,$0182,$0012
        dc.b    $8c+48,$01
        dc.w    $fffe
	dc.w	$00e0,$0000,$00e2,$0000,$0182,$0012

        dc.b    $8c+64,$01
        dc.w    $fffe
        dc.w    $0100,$0200

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe
