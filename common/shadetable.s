*******************************************
* Create shade table
*
* Inputs:
*   a0 = Ptr to generated shade table
*   d0 = From color
*   d1 = To color
*   d2 = Number of shades
*******************************************
CreateShadeTable:
    move.w  d0,.shadeTableFrom
    move.w  d1,.shadeTableTo
    move.w  d2,d6
	subq.w	#1,d6

    moveq   #0,d7
.createShade:
    move.w	.shadeTableFrom,d0
	move.w	d0,d1
	and.w	#$0f0,d1
	eor.w	d1,d0
	move.w	d0,d2
	ext.w	d2     ; r
	lsr.w	#8,d0  ; g
	lsr.w	#4,d1  ; b

	move.w	.shadeTableTo,d3
	move.w	d3,d4
	and.w	#$0f0,d4
	eor.w	d4,d3
	move.w	d3,d5
	ext.w	d5
	lsr.w	#8,d3
	lsr.w	#4,d4

	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5

	muls.w	d7,d3
	muls.w	d7,d4
	muls.w	d7,d5

    divs.w  d6,d3
    divs.w  d6,d4
    divs.w  d6,d5

	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5

	lsl.w	#8,d3
	lsl.w	#4,d4
	or.b	d4,d5
	or.w	d3,d5

	move.w	d5,(a0)+

    addq.w  #1,d7
    cmp.w   d6,d7
    ble     .createShade
    rts

    even

.shadeTableFrom:    dc.w    0
.shadeTableTo:      dc.w    0
