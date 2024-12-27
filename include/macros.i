WAITBLIT:MACRO
	    tst.w	(a6)
.wb\@:	btst	#6,2(a6)
	    bne.s	.wb\@
	    ENDM

PUSH:   MACRO			;PUSH [Registers][ALL]
		IFC	\1,ALL
		movem.l	d0-a6,-(sp)
		ELSE
		movem.l	\1,-(sp)
		ENDIF
		ENDM

POP:	MACRO			;POP [Registers][ALL]
		ifc	\1,ALL
		movem.l	(sp)+,d0-a6
		else
		movem.l	(sp)+,\1
		endif
		ENDM
