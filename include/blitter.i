    IFND    BLITTER_I    
BLITTER_I   = 1

WAITBLIT:macro
	tst.w	(a6)
.wb\@:	btst	#6,2(a6)
	bne.s	.wb\@
	endm

HSIZEBITS 	= 6

ABC         = $80
ABNC        = $40
ANBC        = $20
ANBNC       = $10
NABC        = $8
NABNC       = $4
NANBC       = $2
NANBNC      = $1

; some commonly used operations
A_OR_B	    = ABC+ANBC+NABC+ABNC+ANBNC+NABNC
A_OR_C	    = ABC+NABC+ABNC+ANBC+NANBC+ANBNC
A_XOR_C     = NABC+ABNC+NANBC+ANBNC
A_TO_D	    = ABC+ANBC+ABNC+ANBNC

BC1F_DESC   = 2   ; blitter descend direction

DEST	    = $100
SRCC	    = $200
SRCB	    = $400
SRCA	    = $800

ASHIFTSHIFT = 12
    ENDC