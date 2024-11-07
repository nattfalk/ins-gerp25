InitRotate:
	Movem.l	d0-a6,-(sp)
	Lea	Sintab(Pc),a0
	Lea	Costab(Pc),a1
	Lea	Rotate_Rotatematrix(Pc),a2
	And.w	#$3fe,d0
	Add.w	d0,d0
	And.w	#$3fe,d1
	Add.w	d1,d1
	And.w	#$3fe,d2
	Add.w	d2,d2
	Move.w	(a0,d0.w),Rotate_RotateSinx
	Move.w	(a1,d0.w),Rotate_RotateCosx
	Move.w	(a0,d1.w),Rotate_RotateSiny
	Move.w	(a1,d1.w),Rotate_RotateCosy
	Move.w	(a0,d2.w),Rotate_RotateSinz
	Move.w	(a1,d2.w),Rotate_RotateCosz

	Move.w	Rotate_RotateSinx(Pc),d2
	Muls.w	Rotate_RotateSinz(Pc),d2
	Add.l	d2,d2
	Swap	d2			; k1

;k2 = d3 = sinx*cosz
	Move.w	Rotate_RotateSinx(Pc),d3
	Muls.w	Rotate_RotateCosz(Pc),d3
	Add.l	d3,d3
	Swap	d3			; k2

;k3 = d4 = cosx*sinz
	Move.w	Rotate_RotateCosx(Pc),d4
	Muls.w	Rotate_RotateSinz(Pc),d4
	Add.l	d4,d4
	Swap	d4			; k3

	Move.w	Rotate_RotateCosx(Pc),d5
	Muls.w	Rotate_RotateCosz(Pc),d5
	Add.l	d5,d5
	Swap	d5			; k4

	Move.w	Rotate_RotateCosy(Pc),d0
	Muls.w	Rotate_RotateCosz(Pc),d0
	Add.l	d0,d0
	Swap	d0
	Move.w	d0,(a2)


;k3 = d0 = cosx*sinz
;k2 = d1 = sinx*cosz
	Move.w	d4,d0			; d0=k3
	Move.w	d3,d1			; d1=k2
	Muls.w	Rotate_RotateSiny(Pc),d1	; k3-(((k2*RotateSiny) <<1)>>16) & 0xFFFF
	Add.l	d1,d1
	Swap	d1
	Sub.w	d1,d0
;d0 = cosx*sinz-sinx*cosz*siny
	Move.w	d0,2(a2)

	Move.w	d2,d0			; d0 = k1
	Move.w	d5,d1			; d1 = k4
	Muls.w	Rotate_RotateSiny(Pc),d1	; (k1+(((k4*RotateSiny) <<1) >>16)) & 0xFFFF
	Add.l	d1,d1
	Swap	d1
	Add.w	d1,d0
	Move.w	d0,4(a2)

	Move.w	Rotate_RotateCosy(Pc),d0		; [2][1]
	Muls.w	Rotate_RotateSinz(Pc),d0
	Add.l	d0,d0
	Swap	d0
	Neg.w	d0
	Move.w	d0,6(a2)

	Move.w	d5,d0				; k4
	Move.w	d2,d1				; k1
	Muls.w	Rotate_RotateSiny(Pc),d1
	Add.l	d1,d1
	Swap	d1
	Add.w	d1,d0
	Move.w	d0,8(a2)

	Move.w	d3,d0				; k2
	Move.w	d4,d1				; k3
	Muls.w	Rotate_RotateSiny(Pc),d1
	Add.l	d1,d1
	Swap	d1
	Sub.w	d1,d0
	Move.w	d0,10(a2)


	Move.w	Rotate_RotateSiny(Pc),d0
	Neg.w	d0
	Move.w	d0,12(a2)

	Move.w	Rotate_RotateSinx(Pc),d0
	Muls.w	Rotate_RotateCosy(Pc),d0
	Add.l	d0,d0
	Swap	d0
	Neg.w	d0
	Move.w	d0,14(a2)

	Move.w	Rotate_RotateCosx(Pc),d0
	Muls.w	Rotate_RotateCosy(Pc),d0
	Add.l	d0,d0
	Swap	d0
	Move.w	d0,16(a2)

	Movem.l	(sp)+,d0-a6
	Rts

; 68000 version without shifts
RotatePoint:
	Movem.l	a0/a1/a2,-(sp)	;/d3/d4/d5/d7,-(sp)
	Lea.l	Rotate_Rotatematrix(Pc),a0
	Lea.l	Rotate_TmpMat(Pc),a1
	Movem.w	d0/d1/d2,(a1)
	Lea.l	Rotate_NewMat(Pc),a2
;	MoveQ	#3-1,d7
;.Rotate:
	REPT	3
	Move.w	0(a0),d0
	Muls	0(a1),d0		; a*x
	swap	d0

	Move.w	2(a0),d1
	Muls	2(a1),d1		; b*y
	swap	d1
	Add.w	d1,d0

	Move.w	4(a0),d1
	Muls	4(a1),d1		; c*z
	swap	d1
	Add.w	d1,d0			; d0 = X,Y,Z
	Move.w	d0,(a2)+

	Addq.l	#6,a0			; Next row in matrix.
	ENDR
;	Dbf	d7,.Rotate
	Lea.l	Rotate_NewMat(Pc),a2
	Movem.w	(a2)+,d0/d1/d2
	Movem.l	(sp)+,a0/a1/a2	;/d3/d4/d5/d7
	Rts

Rotate_TmpMat:	Ds.w	3
Rotate_NewMat:	Ds.w	3

Rotate_RotateSinx:	Ds.w	1
Rotate_RotateCosx:	Ds.w	1
Rotate_RotateSiny:	Ds.w	1
Rotate_RotateCosy:	Ds.w	1
Rotate_RotateSinz:	Ds.w	1
Rotate_RotateCosz:	Ds.w	1

Rotate_Rotatematrix:	Ds.w	9
