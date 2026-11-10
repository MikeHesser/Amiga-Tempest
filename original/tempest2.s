		opt   	o+,ow-

*  TEMPEST (c) Copyright by Mike Hesser
*  after the original of Electric Dreams
*  begin about 1.2.90

ExecBase:	=	$4

 * Includes von RAMDISK *

		INCLUDE	"RAM:Help.i"
		INCLUDE	"RAM:copcon0.i"
		INCLUDE	"RAM:bitplane.i"
		INCLUDE "RAM:blitter.i"
		INCLUDE "RAM:copper.i"

 * Systemroutinen *

OpenLibrary	=	-30-522
AllocMem	=	-30-168
FreeMem		=	-30-180
Forbid		=	-30-102
Permit		=	-30-108
OwnBlitter	=	-30-426
DisownBlitter	=	-30-432

 * Systemvariablen *

color00		= 	$180
ciaapra 	=	$bfe001
ciatast		=	$bfec01
StartList	=	38

 * Programmkonstanten *

Width		=	32           		32 Bytes (LORES)
Height		= 	256			PAL
Planesize	=	Width*Height
Planeanz	=	3			8 Farben
Colors		=	1<<Planeanz		2^Planeanz
Clsize		=	3*Planeanz*4
Chip		=	$2
Clear		=	Chip+$10000

anzenemy	=	6			6 Gegnertypen
cxf		=	2			Faktor für Vek.zeichen
cyf		=	2
BStep1		=	48		   	Anz. von Z-Koord
BStep2		=	BStep1/2		wie BStep1 nur für bye
MaxWays		= 	30		   	Maximale Anzahl von HRBahnen
ShootSize	=	2*2*(BStep1*(MaxWays*2+1))
accuracy	=	7		   	Genauigkeit
enemymax	=	50		   	50 maximal *

 * Macros *

* Plot-Routine: (kein Bereichstest) (32 Bytes Screenbreite!)
* Modus: XOR
* Parameter x (d0), y (d1)    (x=0-255) (y=0-255)
* a0 = Bitplaneadresse
* Ausgang:
* d0.w,d1.w,d2.w zerstört
* Dauer: 62 Taktzyklen

PLOT		MACRO
		lsl.w   #5,d1			
		move.b	d0,d2
		eor.b   #7,d2			
		lsr.w   #3,d0
		add.w   d0,d1
		bchg    d2,(a0,d1.w)
		ENDM

 * Speicher für Planes *

Start:		move.l 	Execbase,a6
		move.l  #Planesize*Planeanz,d0
		move.l  #Clear,d1
		jsr     AllocMem(a6)
		move.l  d0,PlaneAdr
		beq	Ende

 * Schußspeicher *

		move.l  #ShootSize,d0
		moveq   #0,d1		* erst FAST dann CHIP
		jsr     AllocMem(a6)	* Mem für S.Koord
		move.l  d0,ShootMem
		beq     FreePlane

 * Copper *

		moveq	#Clsize,d0
		moveq   #Chip,d1
		jsr	AllocMem(a6)
		move.l	d0,Cladr
		beq	FreeSS

 * Copper init *		

		moveq   #Planeanz-1,d4
		move.l  d0,a0
		move.l  Planeadr(pc),d1
		move.w  #bpl1pt,d3
.loop		move.w  d3,(a0)+
		addq.w  #2,d3
		swap    d1
		move.w  d1,(a0)+
		move.w  d3,(a0)+
		addq.w  #2,d3
		swap    d1
		move.w  d1,(a0)+
		add.l   #Planesize,d1
		dbf     d4,.loop
		move.l	#$fffffffe,(a0)		ende

 * Blitter anfordern *

		lea     GRname(pc),a1
		moveq   #0,d0
		jsr     OpenLibrary(a6)
		move.l	d0,GfxBase
		move.l  d0,a6
		jsr     OwnBlitter(a6)
		move.l	ExecBase,a6
		jsr	Forbid(a6)
		lea	$dff000,a5		Custombase
		lea     Vartab(pc),a6		Varbase
		move.w  #$03e0,dmacon(a5)	DMA off

 * Copper init *

		move.l	Cladr(pc),cop1lch(a5)
		clr.w	copjmp1(a5)

 * PF init *

		move.w	#$30a0,diwstrt(a5)
		move.w	#$30a0,diwstop(a5)
		move.w  #$0048,ddfstrt(a5)
		move.w	#$00c0,ddfstop(a5)
		move.w  #%0011001000000000,bplcon0(a5)  3 Planes
		clr.w	bplcon1(a5)
		clr.w   bplcon2(a5)
		clr.w   bpl1mod(a5)
		clr.w   bpl2mod(a5)
		move.w  #$83c0,dmacon(a5)	DMA on (BLTPRI=0)

 * Color Init *

		moveq   #Colors-1,d0
		lea     color00(a5),a1
		lea     ColTab(pc),a2
.loop2		move.w  (a2)+,(a1)+
		dbf     d0,.loop2

 * MAIN * 

main		move.l 	PlaneAdr(pc),a0
		bsr.w   GInit
		bsr.w   cls
 		bsr.w   scboard

  move.w #100,d7
  swap d7
  move.w #100,d7
  lea t_playerone(pc),a2
 * bsr.w rottext

		bsr.w   LVInit
                bsr.w	new
                bsr.w   tube
 		bsr.w   Plane1
	      	bsr.w   XorOn
		bsr.w   beamzap
	moveq #6,d1
	moveq #20,d0
	move.w #$0004,d2
*	bsr.w setenemy

	moveq #5,d1
	moveq #12,d0
	move.w #$0002,d2
*	bsr.w setenemy

MainLoop	move.w 	joy1dat(a5),d0
		btst    #1,d0
		beq.s   .left
		st      z_flag(a6)	   flag setzen
		bsr.w   zright
		bra.s   .fire

.left		btst    #9,d0
		beq.s   .fire0
		st      z_flag(a6)	   flag setzen
		bsr.w   zleft
		bra.s   .fire
.fire0		sf      z_flag(a6)	   flag loeschen
.fire		btst    #7,ciaapra
		bne.s   .a
		tst.b	s_flag(a6)
		bne.s	.aa
		st	s_flag(a6)
		move.w  zappos(a6),d0
		moveq   #0,d1
		bsr.w   s_shot
		bra.s	.aa
.a		sf	s_flag(a6)
.aa		move.b  ciatast,d0
		cmp.b   #127,d0		-> Space
		bne.s   .b
		tst.b   HZapFlag(a6)
		bne.s   .b
		bsr.w   InitHZap
.b		btst	#6,ciaapra
		beq     wait
		cmp.b   #1,HZapFlag(a6)
		bne.s   .c
		bsr.w   HZap
		cmp.w   #BStep1+1,HZapPos(a6)
		bne.s   .c
		addq.b  #1,HZapFlag(a6)		
		
.c		tst.b   z_flag(a6)
		beq.s   .e
		move.b  z_f(a6),d0
		add.b   #2,d0
		cmp.b	#46,d0
		bcs.s   .d
		moveq   #45,d0
.d		move.b  d0,z_f(a6)
		bra.s   .f
.e		move.b  #1,z_f(a6)

.f		bsr.w   directloop
		bsr.w   bewshot
		bsr.w   gen_enemy


EndMain:
 bsr pause
 bsr pause
 bsr pause 
 bsr pause
 bsr pause
 bsr pause
 bsr pause
 bsr pause
 bsr pause

		bra 	MainLoop


 		bra 	wait
wait		bsr 	bye
		
* Wait mouse

.wait2		btst	#6,ciaapra        *linke Maustaste
		bne     .wait2

 * Exit *

exit		move.l  GfxBase(pc),a6
		move.l  StartList(a6),cop1lch(a5)
		clr.w   copjmp1(a5)
		move.w	#$8020,dmacon(a5)
		jsr	DisownBlitter(a6)

		move.l  ExecBase,a6
		jsr	Permit(a6)

 * Copplist off *

		move.l	Cladr(pc),a1
 		moveq   #Clsize,d0
		jsr     FreeMem(a6)

 * ShootMem off *

FreeSS		move.l  ShootMem(pc),a1
		move.l  #ShootSize,d0
		jsr	FreeMem(a6)

 * Bitplanes off *

FreePlane	move.l  Planeadr(pc),a1
		move.l  #Planesize*Planeanz,d0
		jsr     FreeMem(a6)
Ende		moveq   #0,d0
		rts


 * Variablen *

Vartab		rsreset

 * Leveldaten Anfang = LV *

LVnumber	rs.w	1
		dc.w	0
LVstr    	rs.w    1
		dc.w	0
LVf1_x	 	rs.w	1
		dc.w	0
LVf1_y	 	rs.w    1
		dc.w	0
LVdatadr	rs.l	1
		dc.l	0
LVangle		rs.l	1
		dc.l	0
LVflag		rs.w	1
		dc.w	0

 * Variablen zum Spielablauf *

zappos		rs.w	1
zappos2		rs.w	1
z_shot		rs.w    1
z_enemy		rs.w	1
		dc.w	0,0,0,0
z_flag		rs.b    1
z_f		rs.b	1
		dc.b	0,0

 * Variablen zum Spiel (extern) *

HZapPos		rs.w    1
lives1		rs.w    1
lives2		rs.w    1
score1		rs.l    1
score2		rs.l	1
		dc.w	0,0,0,0,0,0,0
dummy		rs.l	1
		dc.l	0
HZapFlag	rs.b	1
		dc.b	0

gecount		rs.b	1
		dc.b	0
 * Anzahl der einzelnen Gegner *

enemytab	rs.b    anzenemy
		dc.b    2,2,2,2,2,2


 * Speicherliste für Schüsse *

shoot2mem	rs.w    Bstep1
		ds.w    Bstep1  

 * Speicherliste für Enemies *

enemymem	rs.l	enemymax
		ds.l    enemymax
 
s_flag		rs.b	1
		dc.b	0
whichplayerf	rs.b    1
		dc.b 	0
 even


 * System *

GfxBase		dc.l	0
PlaneAdr	dc.l	0
Cladr		dc.l    0
ShootMem	dc.l	0

* Konstanten *

Grname		dc.b    "graphics.library",0
		even

ColTab		dc.w	0          -> Hintergrund schwarz
		dc.w    $aaa       -> Grau
		dc.w    $fff       -> Weiß
		dc.w    $fff       -> Weiß
		dc.w    $55f       -> Rot
		dc.w    $88f	   -> Blau
		dc.w    $f22	   -> Grün
		dc.w    $f88       -> ?
*---------------------------------------------------------------

 * Directloop *

directloop	move.w  z_enemy(a6),d6	 Anzahl Gegner in d6
		rtseq			 keine Gegner? dann zurück
		lea	enemymem(a6),a3  Adresse Gegnerliste

.loop		push.w  d6		 Zähler sichern
		tst.b   3(a3)		 Explosion ? ja, dann Schusstest überspringen
		beq.s	.c
		move.b  1(a3),d3	 ZPos allein
		move.w  (a3),d4		 Zpos und Bahnkoord ins Vergleichsregister
		lea	shoot2mem(a6),a2 Adresse Schussliste in a2
		move.w	z_shot(a6),d0	 Anzahl Schüsse in d0

		tst.b	HZapflag(a6)	 Hyperzap aktiv ?
		beq.s	.aa		 nein, Teil überspringen
		inc.b	d3
		cmp.b	HZapPos+1(a6),d3 Kollission mit HZap?
		beq.s	.bb
.aa		move.w	(a3),d4
		tst.w	d0
		beq.w   .c 		 Keine Schüsse? ja dann kein Test
.a		cmp.w   (a2)+,d4	 Koord. vergleichen
		beq.s   .b		 getroffen, dann .b
		subq.w  #2,d0		 Zähler abzählen
		bne.s   .a		 noch nicht Ende dann .a
		bra.s   .c		 zu dir_3

.b		moveq   #0,d1		 (Treffer)
	        move.b  -2(a2),d0	 Bahnkoord und	 
		move.b  -1(a2),d1	 ZPos holen
		bsr.w   getkoord	 Koord. holen
		bsr.w   Plotxy		 Schuss löschen (Bildschirm)
		bsr.w   clearshot	 Schuss löschen (Speicher)
.bb		addq.l  #2,a3		 G-Zeiger erhöhen
		move.b  1(a3),d0	 Gegnernummer holen
		clr.w   (a3)+            Gegner in Explosion umwandeln
		and.b	#%00011111,d0    Nummer ausmaskieren
		subq.w  #1,d0
		add.w   d0,d0
		move.w  scores(pc,d0.w),d0  Punkzahl nach d0
		bsr.w	AddScore         *Zu Spieler addieren
		bra.s   .d                 nächster Schleifendurchgang

.c		moveq   #0,d0		d1,d2,d3
		moveq	#0,d1		ganz löschen
 		moveq 	#0,d2
 		moveq	#0,d3
		move.b  (a3),d0		Bahnkoord.
		move.b  1(a3),d1	ZPos
		move.b  2(a3),d2	Bewegzustand
		move.b  3(a3),d3	Art des G.+Richtung (FT-Bit oder P-Bit)
		move.w  d3,d4
		and.b	#%00011111,d4   Nummer ausmaskieren
		add.b   d4,d4
		add.b   d4,d4		 *4 (LONG)
		move.l  etab(pc,d4.w),a2 Adresse Gegner in a2
		push.l  a3		 Gegnerliste sichern
		jsr     (a2)		 Sprung zu jeweiligem Gegner
		pop.l   a3
		move.b  d0,(a3)+	aktualisierte 
		move.b  d1,(a3)+	Werte wieder
		move.b  d2,(a3)+	zurückschreiben
		move.b  d3,(a3)+

.d		pop.w   d6		Schleifenzähler zurück
		bsr.w   Plane1		normale Farbe
		subq.w  #4,d6		Zähler abzählen
		bne.w   .loop		nächster Schleifendurchgang
	  	rts

etab:		dc.l	explosion,flyingX,crazyX,square,flap
		dc.l	spike,line,line		

scores:		dc.w    20,50,0,15,25,0   Punke für Gegner


 * Feindgenerator *

gec		=	20

gen_enemy:      dec.b	gecount(a6)		Zähler erniedrigen
		rtsne				noch nicht 0?
		move.b	#gec,gecount(a6)	sonst neu setzen

		lea 	enemytab(a6),a3
.loop		moveq	#anzenemy,d0		zwischen 0 u. 6
		bsr.w	rand			Zufallszahl holen
		tst.b	(a3,d1.w)		keiner mehr da?
 rtseq
*		beq.s	.loop			nach einem anderen suchen
		subq.b  #1,(a3,d1.w)	        einer weniger
		inc.b	d1
		move.w	d1,d2			Gegnerart nach d2
		move.w	LVstr(a6),d0		Bahnnr. durch Zufall
		bsr.w	rand			ermitteln
		move.w	d1,d0
		moveq   #BStep1-1,d1		hinterste ZPos.

		bsr.w	Setenemy		anmelden
		rts


 * Enemies + Explosion *

 * Explosion (0) *

explosion:	rts


 * FlyingX (1) *

flyingX		pushm.w	d0-d3	     	 Beschreibung wie bei CrazyX
		lea	magnify(pc),a3  
		moveq	#BStep1-1,d4
  		sub.b	d1,d4
		beq.s   .a		 unmögl. Position dann .a (erstes Mal)
		move.l  d2,a2
		bsr.w	getkoord          d0->X-Koord; d1->Y-Koord
		move.l  a2,d2
		bsr.w	FX_u2    	 
.a		popm.w 	d0-d3
		inc.b   d2
		cmp.b	#6,d2
		bne.s   .b
		moveq   #0,d2
.b		tst.b	d1
		beq.s	.c
		dec.b	d1
		inc.b	d4
.c		pushm.w	d0-d3
		move.l  d2,a2
		bsr.w	getkoord
		move.l  a2,d2
		bsr.w	FX_u2
		popm.w  d0-d3
		rts		

FX_u2		push.w	d4
		lea 	FX_dat(pc),a1
		lsl.l	#3,d2		d2=d2*8
		add.l	d2,a1
		move.b	(a3,d4.w),d4
		bsr.w	FX_u1		erster Strich für X
		bsr.w	FX_u1		zweiter ...
		pop.w	d4
		rts

FX_u1		pushm.w	d0-d1
		bsr.w	FX_u
		move.w	d0,d2
		move.w	d1,d3
		popm.w	d0-d1
		pushm.w	d0-d1
		bsr.w	FX_u		
		bsr.w	DrawLine2
		popm.w	d0-d1
		rts

FX_u		move.b	(a1)+,d5
		move.b	(a1)+,d6		
		ext	d5
		ext	d6		Vorzeichen erweitern

***    DIREKT zu RPOS!!!!!!

******************************************* Rpos
*Einsprung: d4->magnify
*	    d5->relativ Koord X
*	    d6->relativ Koord Y
*
*Aussprung: d0->X-Koord absolut (Drawline2 benutzen!)
*	    d1->Y-Koord absolut
******************************
rpos		muls	d4,d5          Zoom ähnlich wie bei Bruch
		asr.w	#6,d5	\64	  Koordx*zoom
		add.w	d5,d0	       x =----------- 
		muls	d4,d6		      64
		asr.w	#6,d6	\64
		add.w	d6,d1	       erspart Fließkommazahlen
		rts

 * CrazyX (2) *

crazyX	 	pushm.w	d0-d3
		lea	magnify(pc),a3   Adresse Zoomtabelle in a3
		moveq	#BStep1-1,d4
  		sub.b	d1,d4		 Zpos umdrehen
		move.l  d2,a2		 d2 sichern
		bsr.w	getkoord         Koord. holen (d0=x,d1=y)
		move.l  a2,d2		 d2 zurückholen
		bsr.w	FX_u2    	 X zeichnen (löschfunktion da XOR)
		popm.w	d0-d3
		btst	#6,d3	         First-Time-Bit=0?
		beq.s   .d		 ja, dann erstes Mal
		inc.b   d2		 naechste Rot.Phase (um 15 Grad)
		cmp.b	#6,d2		 90 Grad erreicht ?
		bne.s   .a		 nein zu .a
		moveq   #0,d2		 sonst wieder von vorne
.a		bsr.w   nxtbahn          naechste Bahn ausrechnen
		btst	#30,d0		 Stoß gegen Rand?
		beq.s   .b
		bchg	#7,d3		 Richtung aendern
.b		btst	#31,d0	         Ereignis ? (X stoeßt gegen Anfang oder Ende der Röhre)
		beq.s	.c               nein, dann cra_1 sonst Schritt nach vorne
		tst.b	d1	         schon vorne angelangt?
		beq.s	.c	         ja, dann cra_1
		dec.b	d1	         ZPos=Zpos-1
		inc.b	d4	         Zoom=Zoom+1
.c		pushm.w	d0-d3
		move.l  d2,a2
		bsr.w	getkoord
		move.l  a2,d2
		bsr.w	FX_u2            X zeichnen
		popm.w  d0-d3
.d		bset	#6,d3		 FT-Bit setzen
		rts			

 * Square *

squ_z		= 	3

square	 	pushm.w	d0-d3            Beschreibung ähnlich wie CrazyX
		lea	magnify(pc),a3
		moveq	#BStep1-1,d4
  		sub.b	d1,d4
		beq.s   .a
		move.l  d2,a2
		bsr.w	getkoord          d0->X-Koord; d1->Y-Koord
		move.l  a2,d2
		bsr.w	SQ_u2    	 
.a		popm.w	d0-d3
		inc.b   d2
		cmp.b	#6,d2
		bne.s   .b
		moveq   #0,d2
.b		tst.b	d1
		beq.s	.c
		bchg	#7,d3
		bne.s	.c
		dec.b	d1
		inc.b	d4
.c		pushm.w	d0-d3
		move.l  d2,a2
		bsr.w	getkoord
		move.l  a2,d2
		bsr.w	SQ_u2
		popm.w  d0-d3
		rts		

SQ_u2		push.w	d4
		lea 	SQ_dat(pc),a1    Basis Koord. Daten
		add.w   d2,d2
		move.w  d2,d5
		add.w   d2,d2
		add.w   d2,d2
		add.w   d5,d2		 d2=d2*10
		add.l	d2,a1		 Adresse für Bew.zustand
		move.b	(a3,d4.w),d4

		pushm.w d0-d1
		bsr.w   FX_u
		move.w  d0,d2
		move.w  d1,d3
		popm.w  d0-d1
		moveq   #3,d6		* 4 Linien

SQ_lo		push.w  d6
		pushm.w d0-d1
		bsr.w   FX_u
		pushm.w d0-d1
		bsr.w   DrawLine2
		popm.w  d2-d3
		popm.w  d0-d1

		pop.w   d6
		dbf	d6,SQ_lo
		pop.w	d4
		rts

 * flap (4) *

fla_z		=	20

flap		btst	#5,d3		P-Bit gesetzt?
		bne.s	.c		ja, dann .c
		tst.b	d2
		beq.s	.a
		dec.b	d2
		rts

.a		bsr.w	abs_winkel
		btst	#6,d3		FT-Bit gesetzt?
		beq.s	.b		nein, .b
		bsr.w   showline        loeschen
.b		bset	#5,d3		P-Bit setzen	
		bclr	#6,d3		FT-Bit löschen
		rts
		
.c		btst	#6,d3		FT-Bit gesetzt?
		bne.s	.d		ja, dann .d
		bset	#6,d3		FT-Bit setzen
		bra.s	s_flap

.d		bsr.w	s_flap		zeichne flap (loeschen)
		move.w	d2,d4
		move.w	d0,d5		d0 sichern
		btst	#7,d3		Richtung
		bne.s	.f
		dec.b	d4		Winkel herabzaehlen
		bpl.s	.e
		add.b	#90,d4
.e		bsr.w	posri
		bra.s   .h
.f		inc.b	d4
		cmp.b	#90,d4
		bne.s   .g
		clr.w	d4
.g		bsr.w	posle
.h		bchg	#7,d3
		bsr.w	abs_winkel
		bchg	#7,d3
		exg	d4,d2
		cmp.b	d4,d2		Drehung vollendet?
		beq.s   .i		ja, .i
		move.w	d5,d0
		bra.s	s_flap

.i		tst.w	LVflag(a6)
		bne.s	.ll  
		tst.b	d0
		beq.s	.k
		inc.w	d0		d0 korrigieren fuer Vergleich
		cmp.w	LVstr(a6),d0
		beq.s   .j
		bchg	#7,d3
.j		dec.w	d0

.k 		bchg	#7,d3
.ll		tst.b	d1
		beq.s	.m
		dec.b	d1
.m		bsr.w	showline	setzen
		moveq	#fla_z,d2
		bclr	#5,d3		P-Bit loeschen (Wartephase)
		rts

s_flap		pushm.w d0-d3
		move.w  d0,a2		d0 sichern
		move.w	d2,d6		d2 sichern
		add.w 	d0,d0
		move.w	d0,d4
		move.w	d1,d5
		bsr.w	getkoord2
		exg     d0,d4
		exg     d1,d5
		addq.w	#2,d0
		bsr.w	getkoord2
		btst	#7,d3
		beq.s	.a		0, dann mit UZS
		exg     d4,d0	
		exg 	d5,d1
.a		sub.w	d4,d0		d0->relativ zu d4 (X)
		sub.w	d5,d1		d1->relativ zu d5 (Y)
		pushm.w d4/d5 		sichern
		move.w  d0,a3
		move.w  a2,d0		ZPos zurueck
		bsr.s	abs_winkel
		move.w  d6,d0		Winkel nach d0
		sub.b   d2,d0
		bpl.s	.b
		add.b	#90,d0
.b		bsr.w 	getcosin	dazugehoerigen sinus und cosinus holen
		move.w  a3,d0
		lea	dummy(a6),a3	Dummy-Puffer
		bsr.w	rotate2
		popm.w  d2/d3     	d2=d4,d3=d5
		add.w	d2,d0
		add.w	d3,d1
		bsr.w	Drawline2

		popm.w  d0-d3
		rts

* abs_winkel liefert den Winkel der Spitze eines Flaps
*
* Einsprung: d0 (ZPOS),d3 (wie von Directloop)
* Aussprung: d2=Winkel/a1,d5 zerstört
*
abs_winkel	move.l	LVangle(a6),a1		Adr.-Winkeldat. in a1
		move.b	(a1,d0.w),d2		Winkel in d2
		btst	#7,d3			welche Richtung?
		bne.s	.a			1, dann gegen UZS
		sub.b   #45,d2
		bpl.s	.a
		add.b	#90,d2
.a		bclr	#0,d2			ungerade Löschen (wegen 2er Step)
		rts				

 * spike *

spi_z		equ	3

spike	  	btst    #6,d3	     	 Anfang oder Ende des Tunnels?
		beq.s	bb
		dec.b	d2	      	Zähler erniedrigen
		rtsne			wenn fertig

aa		moveq.b	#spi_z,d2
		bclr 	#6,d3	      	Spike in Bewegen versetzen
		bchg	#7,d3	      	neue Richtung für Spike
		rts

bb		bsr.w	showspike
		btst	#7,d3         	Richtung abfragen
		bne.s	.c	      	wenn 1 nach hinten
		dec.b	d1	      	sonst nach vorne
		bne.s	.d
		bset	#6,d3	      	nach hinten
		moveq.b	#spi_z*10,d2
		bra.s	.d
.c		inc.b	d1
		cmp.b	#Bstep1-1,d1  	hinten angelangt ?
		beq.s	aa
.d		bsr.w	showspike
		rts

showspike	pushm.w	d0-d3
		move.w	d0,d5
		bsr.w	getkoord	Linie von Ende Tunnel bis
		move.w	d0,d4		ZPos
		move.w	d1,d3
		move.w	d5,d0
		moveq	#BStep1-1,d1
		bsr.w	getkoord
		move.w	d4,d2
		bsr.w	DrawLine2
		popm.w	d0-d3
		rts

 * Line *

lin_z		equ	3

line	 	dec.b 	d2	    Zähler abzählen
		rtsne
		moveq   #lin_z,d2   Zähler erneuern
		tst.b   d1	    wenn schon vorne angelangt
		rtseq		    einfach zurück
		cmp.b	#BStep1-1,d1
		beq.s	.a
		bsr.w   showline
.a		dec.b   d1	    Bewegung nach vorne
		tst.b   d1	    vorne angelangt
		bne.s   showline    Loch einreißen
		bsr.w   Plane0	    graue Farbe und gleich zu showline

showline	pushm.w d0-d3
		add.w   d0,d0
		move.w  d0,d5
		move.w  d1,d6
		bsr.w   getkoord2   übernimmt auch Zwischenbahnen
		move.w  d0,d4
		move.w  d1,d3
		move.w  d5,d0
		addq.w  #2,d0
		move.w  d6,d1
		bsr.w   getkoord2
		move.w  d4,d2
		bsr.w   DrawLine2
		popm.w  d0-d3
		rts

 * Daten für Rotationsgegner *
 * Vergrößerung je nach ZPos *

magnify		dc.b	8,8,8,9,10,10,10,12,12,13,14,14,15,15,15,16,16,16,16
		dc.b	16,16,16,16,16,18,18,19,19,20,21,22,23,24,25,26,27,28,29
		dc.b    30,32,35,40,44,48,52,56,60,64

FX_dat		dc.b    0,-12,0,12,12,0,-12,0,4,-11,-3,12,12,4,-11,-3
		dc.b	6,-10,-6,11,11,6,-10,-6,9,-8,-8,9,9,9,-8,-8
		dc.b	11,-6,-10,6,6,11,-6,-10,12,-3,-11,4,4,12,-3,-11

SQ_dat		dc.b	9,-9,9,9,-9,9,-9,-9,9,-9
		dc.b	12,-6,7,12,-11,7,-6,-11,12,-6
		dc.b	13,-3,4,13,-12,4,-3,-12,13,-3
		dc.b	13,0,0,13,-12,0,0,-12,13,0
		dc.b	13,4,-3,13,-12,-3,4,-12,13,4
		dc.b	12,7,-6,12,-11,-6,7,-11,12,7

 * setenemy *

 * reiht neuen Gegner in die Liste ein
 * d0.b -> Bahnnr.
 * d1.b -> Z-Pos
 * d2.w -> Bew. Zustand, Richtungsbit, Art des Gegners, Ausbau

setenemy	moveq   #0,d3			
		move.w  z_enemy(a6),d3		Anzahl Gegner in d3
		cmp.w   #enemymax*4,d3		wenn kein Platz
		bcs     .a
		rts
.a		lea     enemymem(a6),a1		Listenadr. in a1
		add.l   d3,a1			Ende Liste
		move.b  d0,(a1)+		-> Bahnnummer
		move.b  d1,(a1)+		-> Zpos
		move.w  d2,(a1) 		-> Bew. Zustand mit Art des Gegners und Richtung
		addq.w  #4,z_enemy(a6)		Zähler erhöhen (in LONG Schritten!)
		rts

 * expclear (nur nach Explosionen) *
 * löscht Explosion aus Liste *
 * a2-> Adresse Explosion

expclear	moveq   #0,d4
		move.w  z_enemy(a6),d4
		lea	enemymem(a6),a1
		add.l   d4,a1			Länge des
		sub.l   a2,a1			Restbereichs
		move.w  a1,d4			ermitteln
		beq.s   .a			0? dann Ende
		move.l  a2,a1
.loop		move.l  (a1)+,-8(a1)		Element um LONG zurück
		subq.w  #4,d4
		bne.s   .loop
.a		subq.w  #4,z_enemy(a6)
		rts

 * beamzap *

beamzap:	
		bsr.w   showzap
		rts

 * zleft *

zleft		bsr.w   showzap			Zapper zeigen (löschen)
		move.w  zappos2(a6),d0		Winkel des Zappers in d0
		sub.b   z_f(a6),d0		Beschleunigung abziehen
		bcc.s   .c			gültig dann zle_1
		add.b   #45,d0			sonst neuer Winkel
		move.w  zappos(a6),d1		und neue Position
		addq.w  #1,d1
		cmp.w   LVstr(a6),d1		Ende Level?
		bne.s   .b			nein dann Ende
		tst.w	LVflag(a6)		sonst test ob Röhre oder nicht
		bne.s   .a			Röhre, zle_3
		move.b  #1,z_f(a6)		sonst Beschl. auf 1
		bra.s   .c			
.a		moveq   #0,d1			Röhrenanfang
.b		move.w  d1,zappos(a6)		Werte zurück
.c		move.w  d0,zappos2(a6)
		bsr.w   showzap			Zapper zeichnen (neu)
		rts

 * zright *

zright		bsr.w	showzap
		move.w  zappos2(a6),d0
		add.b   z_f(a6),d0
		cmp.b   #45,d0
		bcs.s   .c
		sub.b   #45,d0
		move.w  zappos(a6),d1
		bne.s	.b
		tst.w	LVflag(a6)		LVflag=0?
		bne.s	.a
		move.b  #1,z_f(a6)
		bra.s	.c
.a		move.w  LVstr(a6),d1		d1 noch zu groß
.b		dec.w   d1			darum dec
		move.w  d1,zappos(a6)
.c		move.w  d0,zappos2(a6)
		bsr.w   showzap
		rts

 * nxtbahn *
 * rechnet naechste Pos. aus

nxtbahn		btst	#7,d3
		bne.s	posle

 * weiter zu posri!
 * posri *
 * rechnet Bahn weiter im Uhrzeigersinn und ändert Richtungsbit
 * Einsprung: d0->Bahnkoord.

posri		tst.b	d0		Anfang erreicht
		bne.s	.b		nein dann zurückzählen
		bset	#31,d0		Ereignisbit setzen
		tst.w   LVflag(a6)
		bne.s	.a
		bset    #30,d0		Stoß gegen den Rand
		rts

.a		move.w  LVstr(a6),d0	subq wegen korrigieren
.b		dec.w   d0			
		rts

 * posle *
 * wie oben nur gegen Uhrzeigersinn

posle		inc.w   d0
		cmp.w   LVstr(a6),d0
		rtsne
		bset	#31,d0
		tst.w	LVflag(a6)
		bne.s   .a
		dec.w   d0
		bset    #30,d0
		rts
.a		moveq   #0,d0
.b		rts	

 * showzap *

showzap		moveq   #0,d0
		move.w  zappos(a6),d0		Bahnkoord. in d0
		move.l  LVangle(a6),a1		Adr. Winkeldaten in a1
		move.b  (a1,d0.w),d0		Basiswinkel in d0
		add.w   zappos2(a6),d0		plus Zapperwinkel		
		cmp.b   #90,d0			> 360 Grad?
		bcs.s   .a
		sub.b   #90,d0			ja, dann d0=d0-90
.a		add.w   d0,d0
		add.w   d0,d0	         	mal 4 (nun Offset)
		lea     memforzap(pc),a1	Adresse Koord.Dat.
		add.l   d0,a1			plus Offset
		move.w  (a1)+,d4		d4->X-Koord (relativ)
		move.w  (a1)+,d5		d5->Y-Koord
		move.w  zappos(a6),d0
		move.w  d0,d6			d0 sichern
		moveq   #0,d1
		bsr.w   getkoord		Basiskoord holen
		add.w   d0,d4			d4+d0=Absolutkoord.X
		add.w   d1,d5			Y
		move.w  d6,d0			Bahnkoord. zurück
		add.w   d0,d0
		move.w  d0,d6
		moveq   #0,d1		   	d1->ZPOS
		bsr.w   getkoord2		Koord. für Anfang
		move.w  d4,d2
		move.w  d5,d3
		bsr.w   DrawLine2		Strich Anfang zum rechten Winkel
		move.w  d6,d0
		addq.w  #2,d0
		moveq   #0,d1
		bsr.w   getkoord2 		
		move.w  d4,d2
		move.w  d5,d3
		bsr.w   DrawLine2		Strich Winkel zum Ende
		rts

 * s_shot *
 * plottet Schuß *

s_shot		move.w  z_shot(a6),d2
		lea     shoot2mem(a6,d2.w),a1

		move.b  d0,(a1)+
		clr.b   (a1)		Z-Pos immer null (Anfang)
		bsr.w   getkoord
		bsr.w	Plotxy
		addq.w  #2,z_shot(a6)
		rts

 * Game INIT *

GInit		moveq	#0,d0
		move.w	d0,LVnumber(a6)
		moveq   #0,d0
		move.w  d0,z_shot(a6)		Zähler Schüsse
		move.w	d0,z_enemy(a6)		Zähler Gegner
		moveq   #3,d0			3 Leben
		move.w  d0,lives1(a6)		Spieler 1
		move.w  d0,lives2(a6)		Spieler 2
		moveq   #0,d0			Score 0
		move.l  d0,score1(a6)	
		move.l  d0,score2(a6)
		moveq   #0,d0			Anf. Winkel=0
		lea	memforzap(pc),a3	Adr. für Winkelkoord.
.loop		push.w  d0			Winkel sichern
		bsr.w   getcosin		Cosinus für Winkel holen
		moveq   #0,d0
		moveq   #XFak/2+2,d1		Radius
		bsr.w   rotate2			rotieren und Daten speichern
		pop.w  	d0			Winkel zurück
		inc.b  	d0		
		cmp.b   #90,d0			solange bis 360 Grad
		bne.s   .loop	
		rts

 * Level INIT *

LVinit		move.w	LVnumber(a6),d0
		add.w	d0,d0
		add.w	d0,d0			*4
		move.l  LVTab(pc,d0.w),a1

		move.w	LVnumber(a6),d0		ersetzen durch LVplayed!
		add.w	d0,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w   d1,d0			*6
		lea	LVdiff(pc,d0.w),a2
		lea	enemytab(a6),a3		Zieladresse
		move.l	(a2)+,(a3)+
		move.w	(a2),(a3)		6 Bytes kopieren


		move.l	(a1)+,d7	-> D7 ab jetzt ORIGIN (nur für DRAW!!)
		move.w  (a1)+,d0	Anzahl Bahnen
		move.w  d0,LVstr(a6)
		move.w  (a1)+,LVf1_x(a6)  	Fluchtpunkt X
		move.w  (a1)+,LVf1_y(a6)	Y
		move.w  (a1)+,LVflag(a6)	Röhre oder nicht
		move.l  a1,LVdatadr(a6)		Adresse Koord.
		add.w   d0,d0
		addq.w  #2,d0
		add.l   d0,a1			Adr. Winkeldaten
		move.l  a1,LVangle(a6)
		move.w  LVstr(a6),d0		zufällige
		bsr.w   rand			Position für
		move.w  d1,zappos(a6)		Zapper
		move.w  #23,zappos2(a6)		
		move.b  #1,z_f(a6)		Beschleunigung
		clr.w   HZapFlag(a6)		HyperZap Flag (0=kein HZ 1=HZ)
		move.b	#gec,gecount(a6)	
		rts		

LVdiff:		dc.b	6,0,0,6,0,0		Anzahl der Gegner
		dc.b    6,0,5,6,0,0
		dc.b	0,0,8,3,0,0

LVTab:   	dc.l	Level1,Level2,Level3

 * CLS *

 * löscht Bildschirm (Planes müssen in Folge im Speicher stehen!)
 * Einsprung: -
 * Aussprung: a1,d0,d1 zerstört

cls		move.l  a0,a1
		moveq   #0,d0
		move.w  #(Planesize*Planeanz)/4-4,d1

.loop		move.l  d0,(a1)+
		dbra    d1,.loop
		rts

 * Random(x) *

rand		move.w  vhposr(a5),d1		Rasterstrahlpos.
		and.w   #%1111111,d1		unwichtige Daten ausmaskieren
.a		cmp.w   d0,d1			neuer Wert bis geeignet
		bge.s   .b
		rts
.b		sub.w   d0,d1
		bra.s   .a

 * bewshot *
 * bewegt alle Schüsse

bewshot		move.w  z_shot(a6),d3		Anzahl Schüsse in d3
		rtseq
		lea     shoot2mem(a6),a2	Adr. Schussliste in a2
.loop		moveq   #0,d0
		moveq   #0,d1
		move.b  (a2)+,d0	   	d0->Bahnnr.
		move.b  (a2)+,d1   		d1->Z-Pos
		move.l  d0,d4			sichern
		move.l  d1,d5
		bsr.w   getkoord		Koord holen
		bsr.w	Plotxy			plotten
		move.l  d4,d0			zurück
		move.l  d5,d1
		inc.b   d1			weiterbewegen
		cmp.b   #BStep1,d1		Ende des Tunnels erreicht?
		bne.s   .a			nein, weiter
		bsr.w   clearshot		Schuss löschen (Speicher)
		subq.l  #2,a2			Zeiger korrigieren
		bra.s   .b
.a		move.b  d1,-1(a2)
		bsr.w   getkoord
		bsr.w   Plotxy
.b		subq.w  #2,d3
		bne.s   .loop	
		rts
 
 * Clearshot *

clearshot	move.w  z_shot(a6),d4
		lea	shoot2mem(a6,d4.w),a1	Adr. Schuss a1
		sub.l   a2,a1			Rest ausrechnen
		move.w  a1,d4
		beq.s   .a			0?, dann ende
		move.l  a2,a1
.loop		move.w  (a1)+,-4(a1)		Wort kopieren
		subq.w  #2,d4
		bne.s   .loop
.a		subq.w  #2,z_shot(a6)		Zähler abzählen
		rts

 * new *
 * Aufbau des Levels (incl. Effekte)

new		bsr.w   tubeend			erst Tunnelende
		bsr.w   new_			HZapper von hinten nach vorne
		bsr.w   InitLP			Koord. initialisieren
		bsr.w   DrawQS			Tunnelanfang
		bsr.w	new_			wieder löschen (XOR)
		bsr.w   nw			Levelbahnen zeichnen
		rts

 * new_ *
 * zeichnet QS von hinten nach vorne. Step: 1/8 (30)

new_		bsr.w	XorOn
		bsr.w   Plane1             * Helle Farbe
		bsr.w   tubeend		
		moveq   #30,d4
		move.l	LVdatadr(a6),a1
		move.w  LVstr(a6),d6
.a		pushm.l d4/d6/a1
		bsr.w	InitLP
.b		pushm.l d4/d6/a2
		bsr.w   NxtPos
		popm.l  d4/d6/a2
		dbra    d4,.b
		bsr.w   DrawQS
		bsr.w 	pause
		popm.l  d4/d6/a1
		dbra    d4,.a

		bsr.w	Plane0
		rts

 * bye *
 * zeichnet QS von vorne nach hinten. Step: 1/4
 * Modus: Normal     Farbe:HELL

bye		bsr.w   XorOff
  		bsr.w	Plane1
		bsr.w   InitLP
		moveq	#BStep2,d0	  d0->Anzahl der Bahnen
		bsr.w   DrawLPlo1
		bsr.w   tubeend
		bsr.w	Plane0
		rts

 * GetKoord (Bahn)+ *
 * nur Schussbahnen!
 * Einsprung: d0.l -> Bahnnr., d1.w -> Z-Pos
 *	a1,d2 zerstört!
 * ca. 68 Taktzyklen
 * Aussprung: d0 -> X; d1 -> Y
 
getkoord	move.l  a4,a1
		lsl.w   #6,d0
		move.w  d0,d2
		add.w   d0,d0
		add.w   d2,d0		*192
		add.w   d0,d0
		add.w   #192,d0
		add.w   d1,d1
		add.w   d1,d1
		add.w   d1,d0
		add.l   d0,a1
		move.w  (a1)+,d0
		move.w  (a1)+,d1
		rts

 * berücksichtigt ALLE Bahnen *

getkoord2	move.l  a4,a1
		lsl.w   #6,d0
		move.w  d0,d2
		add.w   d0,d0
		add.w   d2,d0		*192
		add.w   d1,d1
		add.w   d1,d1
		add.w   d1,d0
		add.l   d0,a1
		move.w  (a1)+,d0
		move.w  (a1)+,d1
		rts

 * Init ShootMem *

nw		move.l	LVdatadr(a6),a1
		lea	memforLVA(pc),a2
		move.w  LVstr(a6),d6
		push.w  d6
		clr.w   d0
		clr.w   d1
		move.b  (a1)+,d0
		move.b  (a1)+,d1
.a		bsr.w   DrawLPlo
		clr.w	d4
		clr.w	d5
		move.b  (a1)+,d4
		move.b  (a1)+,d5
		add.w   d4,d0
		add.w   d5,d1
		lsr.w   #1,d0
		lsr.w   #1,d1
		bsr.w   DrawLPlo
		move.w  d4,d0
		move.w  d5,d1
		dbra	d6,.a
		pop.w	d1
		add.w   d1,d1               *2
 		lea     memforLVA(pc),a2
		move.l  ShootMem(pc),a4
		moveq   #Bstep1-1,d0
.b		pushm.l a2/a4/d1
.c		push.l  a2
		bsr.w   DrawLP1
		pop.l   a2
		add.w   d7,d3
		swap	d7
		add.w   d7,d2
		swap    d7
		move.w  d2,(a4)+
		move.w  d3,(a4)+
		add.l   #(BStep1*4)-4,a4
		moveq   #0,d6
		bsr.w   NxtPos
		dbra    d1,.c
		popm.l  a2/a4/d1
		addq.l  #4,a4
		dbra    d0,.b		
		move.l  ShootMem(pc),a4  a4 von nun an unveränderbar
		rts

* InitLP *

InitLP		move.l  LVdatadr(a6),a1
		lea     memforLVA(pc),a2
		move.w  LVstr(a6),d6      	* Counter
	  	pushm.l d6/a1-a2
.loop		clr.w   d0
		clr.w   d1
	        move.b  (a1)+,d0
		move.b  (a1)+,d1
		bsr.w   DrawLPlo
		dbra    d6,.loop
		popm.l  d6/a1-a2
  		rts

DrawLPlo	move.w  d0,(a2)+
		move.w  d1,(a2)+
	        move.w 	d0,d2
                move.w  d1,d3
                lsr.w   #3,d2
                lsr.w   #3,d3
                add.w   LVf1_x(a6),d2
                add.w   LVf1_y(a6),d3
		sub.w   d0,d2
		sub.w   d1,d3
		asl.w   #accuracy,d2	  um x Bits verschieben für höhere Genauigkeit
		asl.w   #accuracy,d3
		move.w  d2,(a2)+           dx
		move.w  d3,(a2)+           dy
		move.w  d2,(a2)+           dx
		move.w  d3,(a2)+           dy
		rts

DrawLPlo1	pushm.l d6/a2
		bsr.w   DrawQS
		inc.w   d6
 		pushm.l d6/a2
		bsr.w   NxtPos
 		popm.l  d6/a2
 		bsr.w 	NxtPos
		move.w  #$99,d5
.loop		divu    #1,d5
		divu    #1,d5
		dbra    d5,.loop
		popm.l  d6/a2
		dbra    d0,DrawLPlo1
 		rts

DrawQS		pushm.l d0/d6/a2
		bsr.w   DrawLP1
        	exg	d2,d0
		exg 	d3,d1
		bra.s   .a

.loop		bsr.w   DrawLP1
		move.w  d2,d4
		move.w  d3,d5
		bsr.w   DrawLine
		move.w  d4,d0
		move.w  d5,d1
.a		dbra    d6,.loop		* DrawQS2
		popm.l  d0/d6/a2
		rts

DrawLP1       	move.w	(a2)+,d2          X
		move.w  (a2)+,d3          Y
		move.w  (a2)+,d4 	  dx
		move.w  (a2)+,d5	  dy
		sub.w   (a2)+,d4
		sub.w   (a2)+,d5
		asr.w   #accuracy,d4
		asr.w   #accuracy,d5
		add.w   d4,d2
		add.w   d5,d3
		rts

NxtPos	 	addq.l  #8,a2
		move.w  (a2),d4
		move.w  2(a2),d5
		asr.w	#3,d4
		asr.w   #3,d5
	       	sub.w   d4,(a2)+
		sub.w   d5,(a2)+
		dbra    d6,NxtPos
		rts

* Tube-ende *

tubeend		move.l  LVdatadr(a6),a1
		move.w  LVstr(a6),d6
		dec.w   d6
		bsr.w   tubeend1
		exg     d2,d0
		exg	d3,d1
.loop		bsr.w   tubeend1
		pushm.w d2-d3
		bsr.w   DrawLine
		popm.w   d0-d1
		dbra    d6,.loop
		rts		

tubeend1	clr.w	d2
		clr.w	d3
		move.b  (a1)+,d2
		move.b  (a1)+,d3
		lsr.w   #3,d2
		lsr.w   #3,d3
		add.w	LVf1_x(a6),d2
		add.w   LVf1_y(a6),d3
		rts

 * tube *
 * Röhre mit hinterem und vorderem Querstreifen zeichnen
 * Modus: Normal

tube		bsr.w	XorOff
		bsr.w	DrawL
		bsr.w	InitLP
		bsr.w   DrawQS
		bsr.w   tubeend
		rts

* Level zeichnen (Strahlen) *

DrawL		move.l	LVdatadr(a6),a1
		move.w  LVstr(a6),d6		* Zähler
		move.w  LVf1_x(a6),d4		* X-Mittelpunkt
		move.w  LVf1_y(a6),d5		* Y-Mittelpunkt

.loop		clr.w	d0
		clr.w	d1
		move.b  (a1)+,d0
		move.b  (a1)+,d1
		move.w  d0,d2
		move.w  d1,d3
		lsr.w   #3,d2
		lsr.w   #3,d3
		add.w   d4,d2
		add.w   d5,d3
		pushm.w d2-d3
		bsr.w   DrawLine
		popm.w  d2-d3
		dbra    d6,.loop
		rts

 * XorOn *

XorOn		move.b	#$4a,DrawMode+3		* !! SelfChange !! (sorry)
		rts

 * XorOff *

XorOff		move.b  #$ca,DrawMode+3
		rts

 * Color 2 (Rot) *

Plane2		move.l  Planeadr(pc),a0
		add.l   #Planesize*2,a0
		rts

 * Color 1 (Hell) *

Plane1		move.l  Planeadr(pc),a0
		add.l	#Planesize,a0
		rts

 * Color 0 (Dunkel) *

Plane0		move.l  Planeadr(pc),a0
		rts

 * VSync *

VSync		move.l	vposr(a5),d2
		and.l	#$0001ff00,d2
		cmp.l	#$c800,d2
		bne.s   VSync
		rts
 * Add Score

AddScore	tst.b	whichplayerf(a6)
		bne.s	.a
		add.l	d0,score1(a6)
		bsr.w	ssc1
		rts
.a		add.l	d0,score2(a6)
		bsr.w	ssc2
		rts

 * Init HZap *

InitHZap	clr.w   HZapPos(a6)
		inc.b   HZapFlag(a6)  Flag setzen
		bsr.w   InitLP
		bsr.w   Plane0
		bsr.w   XorOff
		lea     memforLVA(pc),a2
		move.w  LVstr(a6),d6
		bsr.w   DrawQS
		bsr.w 	Plane1
		bsr.w	XorOn
 		rts

 * HZap *

HZap		lea	enemymem(a6),a2		Gegnerliste
		move.w	HZapPos(a6),d0		ZPos des Zappers
		move.w  z_enemy(a6),d1		Enemyzähler
		



		move.w  LVstr(a6),d6
		lea     memforLVA(pc),a2
		move.w  HZapPos(a6),d0
		beq.s   .a
		cmp.b   #BStep1,d0
		beq.s   .a
		bsr.w   DrawQS
		pushm.l d6/a2
         	inc.w   d6
		bsr.w   NxtPos
		popm.l  d6/a2
.a		bsr.w   DrawQS
		inc.w   HZapPos(a6)
		rts

 * RotText *

 * Einsprung: a2=Adresse Text
 * 	     d7=Koord.

RotText		bsr.w   XorOn
		moveq 	#89,d0
		moveq   #0,d1
		move.b  (a2)+,d1

Rot1		bsr.w   Rot3
		dbra    d0,Rot1
.a		bsr.w	Rot3
		addq.w  #1,d0
		cmp.b   #90,d0
		bne.s   .a
		rts

Rot3		pushm.l d0/d1/d7/a2
		bsr.w   ShowText
		bsr.w   VSync
		popm.l  d0/d1/d7/a2
		pushm.l d0/d1/d7/a2
		lea     memforLVA(pc),a1
		bsr.w   showt1
		popm.l  d0/d1/d7/a2
		rts

 * show text *

 * Einsprung: a2 ->Adr. des Textes
 * d1->Anz. Zeichen
 * d7->ORIGIN
 * d0->Drehwinkel (aller Buchstaben)
 
showtext	lea	memforLVA(pc),a3
		pushm.l a3/d1
		moveq	#0,d6
.loop		move.b 	(a2)+,d6
		tst.b	d6
		bne.s	.a
		move.w  #128,(a3)+
		bra.s   .b
.a		pushm.l a2/d0/d1
		bsr.w	showch
		popm.l  a2/d0/d1
.b		dbra    d1,.loop
		popm.l  a1/d1         a3->a1

showt1		push.w  d1
		bsr.w   showlo
		swap	d7
		add.w	#8*cxf,d7
		swap	d7
		addq.l  #2,a1
		pop.w   d1
		dbra    d1,showt1
		rts

***************************************************************
t_tempest:	dc.b    6,20,5,13,16,5,19,20
t_playerone:	dc.b	9,16,12,1,25,5,18,0,15,14,5
t_playertwo:	dc.b	9,16,12,1,25,5,18,0,20,23,15
t_gameover:	dc.b	8,7,1,13,5,0,15,22,5,18
t_avoidspikes:  dc.b    11,1,22,15,9,4,0,19,16,9,11,5,19
*************************************************************** Cosinus
* *127 <<7
cos		dc.b	127,126,125,124,122,119,115,112,107,102,97,91
		dc.b	84,77,70,63,55,46,38,29,21,12,3,-5,-14,-23,-31
		dc.b	-40,-48,-57,-64,-72,-79,-86,-93,-99,-104,-109
		dc.b	-114,-117,-121,-124,-126,-127,-128,-128,-128
		dc.b  	-127,-126,-124,-121,-117,-114,-109,-104,-99
		dc.b	-93,-86,-79,-72,-64,-57,-48,-40,-31,-23,-14
		dc.b	-5,3,12,21,29,38,46,55,63,70,77,84,91,97
		dc.b	102,107,112,115,119,122,124,125
		even

 * show character *

 * Einsprung: 	     
 *	     d0 -> Drehwinkel
 *	     d6 -> Buchstabennummer
 *	     d7 -> Offset
 *	     a3 -> Adr. von memforLVA
 *

showch		bsr.w   getcosin
		lsl.w   #2,d6			 *4 (LONG)
	   	lea	chtable(pc,d6.w),a1
		move.l  (a1),a1
		moveq   #0,d0
		moveq   #0,d1
		bsr.w   berlo
		rts
getcosin	move.b  cos(pc,d0.w),d4
		move.b  sin(pc,d0.w),d5		
		ext	d4
		ext	d5
		rts
***************************************************************** Sin
sin		dc.b	0,7,16,25,34,42,51,59,66,74,81,87,94,99,105,109
		dc.b    114,117,120,123,125,126,126,126,126,125,123,120
		dc.b	117,114,109,105,99,94,87,81,74,66,59,51,42,34
		dc.b    25,16,7,0,-9,-18,-27,-36,-44,-53,-61,-68,-76
		dc.b    -83,-89,-96,-101,-107,-111,-116,-119,-122,-125
		dc.b	-127,-128,-128,-128,-128,-127,-125,-122,-119
		dc.b	-116,-111,-107,-101,-96,-89,-83,-76,-68,-61
		dc.b	-53,-44,-36,-27,-18,-9

* Pointer auf Vektorzeichensatz *

chtable		dc.l	space,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q
		dc.l    r,s,t,u,v,w,x,y,z

showlo		cmp.w   #128,(a1)
		rtseq
		cmp.w	#255,(a1)
		bne.s   .a
		addq.l  #2,a1
		move.w  (a1)+,d0
		move.w  (a1)+,d1
.a	    	move.w  (a1)+,d2
		move.w  (a1)+,d3		
		pushm.w d2-d3
		bsr.w   DrawLine
		popm.w  d0-d1
		bra.s   showlo
		rts

 * Berechnet Koord. *

 * Einsprung:	a1->Adr. auf char
 *		a3->Adr. auf memforch

berlo		
.loop		cmp.b   #128,(a1)
		beq.s	.b
		cmp.b	#255,(a1)
		bne.s   .a
		inc.l   a1
		move.w  #255,(a3)+
		clr.w	d0
		clr.w	d1
		move.b	(a1)+,d0
		move.b  (a1)+,d1
		bsr.w   rotate
.a		clr.w   d0
		clr.w   d1
	    	move.b  (a1)+,d0
		move.b  (a1)+,d1		
		bsr.w	rotate
		bra.s   .loop
.b 	
		move.w	#128,(a3)+
		rts

 * PlotXY *

Plotxy		PLOT
		rts

 * Score-board *

scboard		bsr.w   Plane1
		lea     tr_1(pc),a3
		bsr.w   ptext
		bsr.w   Plane2
		lea     tr_1(pc),a3
		bsr.w   ptext
		lea     tr_2(pc),a3
		bsr.w   ptext
		bsr.w   slp1
		bsr.w   slp2
		bsr.w   ssc1
		bsr.w   ssc2
		bsr.w   Plane0
		rts

tr_1		dc.b	0,0,"PLAYER ONE   00  00   PLAYER TWO",0
tr_2		dc.b	0,1,"SCORE 000000 000000 SCORE 000000",0

 * Lives-Anzeige *

slp1		move.w  lives1(a6),d4
		moveq   #0,d0
		bra.s   slp
slp2		move.w  lives2(a6),d4
		moveq   #24,d0

slp		moveq   #2,d1
		dec.w   d4
.loop		moveq   #37,d2
		bsr.w   showrc
		moveq   #38,d2
		bsr.w   showrc
		inc.w   d0
		dbra    d4,.loop	
		rts

 * Score-Anzeige *

ssc1		moveq   #6,d0
		move.l  score1(a6),d4
		bra.s   ssc

ssc2		moveq   #26,d0
		move.l  score2(a6),d4
ssc		bsr.w   Plane2
		moveq   #1,d1
		bsr.w   showscore
		bsr.w   Plane1
		rts

 * SCORE *

 * stellt 16 Bit-Zahl am Bildschirm dar
 * Einsprung: d4 -> 32 Bit Zahl
 *	     d0,d1 (x,y)
 * Aussprung: d2,d4,d5 zerstört

showscore	move.l	#100000,d5
		bsr.s	.a
		move.l	#10000,d5
		bsr.s   .a
		move.w  #1000,d5
		bsr.s   .a
		moveq   #100,d5
		bsr.s   .a
		moveq   #10,d5
		bsr.s   .a
		move.w  d4,d2
		inc.w   d2
		bra.s   .b

.a		moveq	#0,d2
.loop		inc.w   d2
		sub.l   d5,d4
		bcc.s   .loop
		add.l   d5,d4
.b		bsr.w   showrc
		rts	

 * ptext *
 * Einsprung: a3 -> Adresse des Textes (0 als Abschluß!!)
 * d0,d1 -> Koord. des Textes
 *----------------------------------------------

ptext		moveq	#0,d0
		moveq   #0,d1
		move.b  (a3)+,d0
		move.b  (a3)+,d1
aaa		moveq   #0,d2
		move.b  (a3)+,d2
		rtseq
		sub.b   #32,d2
		beq.s   .b
		sub.b   #15,d2
		cmp.b   #18,d2
		bcs.b   .b
		sub.b   #7,d2
.b		bsr.w   showrc
		bra.s   aaa
		rts

 * show charac *
 * Schreibt Zeichen aus dem Charactersatz
 *
 * Einsprung: d0.w,d1.w  (x,y) (0-39),(0-ca. 30)
 * 	     d2.l (!) ->Buchstabennummer
 *
 * Aussprung: d2,d3,a1,a2 zerstört d0,d1 bleiben erhalten (d0 eins weiter)
 *--------------------------------------------------

showrc		move.w  d1,d3
		add.w   d1,d1
		add.w   d1,d1
		add.w   d3,d1  			*5
		lsl.w   #6,d1  			*->320
		add.w   d0,d1
		move.l  d1,a1
		add.l   a0,a1
		lsl.w   #3,d2
		lea     rcharac(pc),a2
		add.l   d2,a2
		moveq   #Width,d2
		moveq   #7,d1

.loop		move.b  (a2)+,(a1)
		add.l   d2,a1
		dbra    d1,.loop
		move.w  d3,d1
		inc.w   d0
		rts

 * rotate punkt *

 * d0 = Drehpunkt X
 * d1 = Drehpunkt Y
 * d4 = cos(w)
 * d5 = sin(w)
 * a3 = Adresse von memforLVA

rotate		sub.w   #3*cxf,d0
		sub.w	#3*cyf,d1
rotate2		move.w  d0,d2
		move.w  d1,d3
		muls    d4,d0            * -> x*cos(w)
		muls    d5,d1		 * -> y*sin(w)
		sub.w   d1,d0		 * -> x*cos(w)-y*sin(w)
		muls    d5,d2		 * -> x*sin(w)		
		muls    d4,d3		 * -> y*cos(w)
		add.w	d2,d3		 * -> x*sin(w)+y*cos(w)
		move.w  d3,d1
		asr.w   #7,d0		 * /128
		asr.w   #7,d1		 * /128
		move.w  d0,(a3)+	 * Koordinate in Speicher (X)
		move.w  d1,(a3)+         * Y
		rts

 * Drawline Routine (übernommen aus AMIGA Intern I S.253, leicht modifiziert) *
 
DrawLine	add.w   d7,d1
		add.w   d7,d3
		swap    d7
		add.w   d7,d0
		add.w   d7,d2
		swap    d7

DrawLine2	pushm.l d4-d6
	        cmp.w   d0,d2
		bne.s   .a
 		cmp.w   d1,d3
 		beq     dend 
.a		moveq	#40,d4

		move.w  d1,d4
		lsl.w   #5,d4

		moveq	#-$10,d5
        	and.w	d0,d5
		lsr.w	#3,d5
		add.w	d5,d4
		add.l	a0,d4

		moveq   #0,d5
		sub.w	d1,d3
		roxl.b	#1,d5
		tst.w	d3
		bge.s	.y2gy1
		neg.w	d3
.y2gy1		sub.w	d0,d2
		roxl.b	#1,d5
		tst.w	d2
		bge.s	.x2gx1
		neg.w	d2
.x2gx1		move.w	d3,d1
		sub.w	d2,d1
		bge.s	.dygdx
		exg	d2,d3
.dygdx		roxl.b	#1,d5
		move.b	Okttabelle(pc,d5),d5
		add.w	d2,d2

.WBlit		btst	#14,dmaconr(a5)
		bne.s	.WBlit

		move.w	d2,bltbmod(a5)
		sub.w   d3,d2
		bge.s	.signnl
		or.b	#$40,d5
.signnl		move.w	d2,bltaptl(a5)
		sub.w	d3,d2
		move.w	d2,bltamod(a5)

		move.w	#$8000,bltadat(a5)
		and.w	#$000f,d0
		ror.w	#4,d0
DrawMode	or.w	#$0bca,d0		* $4a->XOR-Modus
		move.w	d0,bltcon0(a5)		* $ca->Normal
		move.w	d5,bltcon1(a5)
		move.l	d4,bltcpth(a5)
		move.l	d4,bltdpth(a5)
		moveq   #Width,d4
		move.w	d4,bltcmod(a5)
		move.w	d4,bltdmod(a5)
		moveq   #$ff,d4
		move.w	d4,bltbdat(a5)
		move.w	d4,bltafwm(a5)

		lsl.w	#6,d3
		addq.w	#2,d3
		move.w	d3,bltsize(a5)
		
dend		popm.l  d4-d6
		rts

Okttabelle	dc.b 	0*4+1
		dc.b 	4*4+1
		dc.b 	2*4+1
		dc.b 	5*4+1
		dc.b 	1*4+1
		dc.b 	6*4+1
		dc.b 	3*4+1
		dc.b 	7*4+1

BlitSync	btst	#14,dmaconr(a5)
		bne.s 	BlitSync
		rts

************************************** PROVISORISCH!!!
bigpause: moveq #30,d6
bp1:	  move.l d6,-(sp)
  bsr pause
  move.l (sp)+,d6
  dbra d6,bp1
  rts
Pause:   move.l d5,-(sp)
	   	move.l  #$150,d5
WaitLoop:	divu    #1,d5
		dbf     d5,WaitLoop

	move.l (sp)+,d5
		rts
************************************* !!!!!!!!!!!!!!!!!!
 
 * LEVELS *
 * 1. Origin (WORD,WORD)
 * 2. Anzahl der Koordinaten-1 (WORD)
 * 3. x,y Koord. des Fluchtpunkte (WORD,WORD)
 * 4. Flag ob Röhre oder Nicht-Röhre (0=Keine Röhre,<>0=Röhre) (WORD)
 * 5. x,y Koord. der Figurkoordinaten (BYTE,BYTE)

XFak		equ 	28

Level

Level1		dc.w    45,40,19,72,-10,0        

		dc.b	0,0,0,32,0,64,24,64,24,96
		dc.b    24,128,48,128,48,160,48,192
		dc.b    72,192,96,192,120,192,120,160
		dc.b    120,128,144,128,144,96,144,64
		dc.b    168,64,168,32,168,0
		dc.b	0,0,67,0,0,67,0,0,67,67,67
		dc.b	45,45,67,45,45,67,45,45

Level2	        dc.w    0,0,24,116,114,1
                dc.b    40,116,40,140,64,148,88,156
                dc.b    104,172,112,200,120,228,144,228
                dc.b    152,200,160,172,176,156,200,148
                dc.b    224,140,224,116,200,108,176,100
                dc.b    160,84,152,56,144,28,120,28
                dc.b    112,56,104,84,88,100,64,108
                dc.b    40,116
                dc.b    0,72,72,78,86,86,67,48
                dc.b    48,56,62,62,45,27,27,33
                dc.b    41,41,22,3,3,11,17,17
                dc.b    40

Level3	        dc.w    25,0,26,90,116,1
                dc.b    30,40,30,68,30,96,30,124,30,152
                dc.b    30,180,30,208,30,236,54,236,78,236
                dc.b    102,236,126,236,150,236,174,236,174,208
                dc.b    174,180,174,152,174,124,174,96,174,68
                dc.b    174,40,150,40,126,40,102,40,78,40
                dc.b    54,40,30,40
                dc.b    0,0,0,0,0,0,0,67,67,67
                dc.b    67,67,67,45,45,45,45,45,45,45
                dc.b    22,22,22,22,22,22,33
		even

 * Zeichensatz *

characters	
space		dc.b	128
a		dc.b	255,0,6*cyf, 3*cxf,0, 6*cxf,6*cyf,255,5*cxf,4*cyf,cxf,4*cyf,128
b		dc.b    255,0,6*cyf,0,0,5*cxf,0,6*cxf,cyf,6*cxf,2*cyf,5*cxf,3*cyf
		dc.b    6*cxf,4*cyf,6*cxf,5*cyf,5*cxf,6*cyf,0,6*cyf,255,5*cxf,3*cyf
		dc.b	2*cxf,3*cyf,128
c		dc.b	255,5*cxf,5*cyf,4*cxf,6*cyf,2*cxf,6*cyf,0,4*cyf,0,2*cyf
		dc.b	2*cxf,0,4*cxf,0,5*cxf,cyf,128
d		dc.b	255,0,6*cyf,0,0,4*cxf,0,6*cxf,2*cyf,6*cxf,4*cyf,4*cxf,6*cyf
		dc.b	0,6*cyf,128
e		dc.b	255,6*cxf,6*cyf,0,6*cyf,0,0,6*cxf,0,255,0,3*cyf,4*cxf,3*cyf,128
f		dc.b	255,0,6*cyf,0,0,6*cxf,0,255,0,3*cyf,4*cxf,3*cyf,128
g		dc.b	255,3*cxf,3*cyf,6*cxf,3*cyf,6*cxf,6*cyf,0,6*cyf,0,0,6*cxf,0,128
h		dc.b	255,0,6*cyf,0,0,255,0,3*cyf,6*cxf,3*cyf,255,6*cxf,0,6*cxf,6*cyf,128
i		dc.b	255,cxf,0,5*cxf,0,255,3*cxf,0,3*cxf,6*cyf,255,cxf,cyf*6,5*cxf,6*cyf,128
j		dc.b	255,cxf,0,5*cxf,0,5*cxf,4*cyf,2*cxf,6*cyf,128
k		dc.b	255,0,6*cyf,0,0,255,0,3*cyf,3*cxf,3*cyf,6*cxf,0,255,3*cxf,3*cyf,6*cxf,6*cyf,128
l		dc.b	255,0,0,0,6*cyf,5*cxf,6*cyf,128	            
m		dc.b    255,0,6*cyf,0,0,3*cxf,3*cyf,6*cxf,0,6*cxf,6*cyf,128
n		dc.b	255,0,6*cyf,0,0,6*cxf,6*cyf,6*cxf,0,128
o		dc.b	255,0,0,6*cxf,0,6*cxf,6*cyf,0,6*cyf,0,0,128
p		dc.b	255,0,6*cyf,0,0,6*cxf,0,6*cxf,3*cyf,0,3*cyf,128
q		dc.b	255,0,0,6*cxf,0,6*cxf,6*cyf,0,6*cyf,0,0,255,4*cxf,4*cyf,6*cxf,6*cyf,128
r		dc.b	255,0,6*cyf,0,0,6*cxf,0,6*cxf,3*cyf,0,3*cyf,255,3*cxf,3*cyf
		dc.b	6*cxf,6*cyf,128
s		dc.b	255,0,6*cyf,6*cxf,6*cyf,6*cxf,3*cyf,0,3*cyf,0,0,6*cxf,0,128
t		dc.b	255,0,0,6*cxf,0,255,3*cxf,0,3*cxf,6*cyf,128
u		dc.b	255,0,0,0,4*cyf,2*cxf,6*cyf,4*cxf,6*cyf,6*cxf,4*cyf,6*cxf,0,128
v		dc.b	255,0,0,0,2*cyf,3*cxf,6*cyf,6*cxf,2*cyf,6*cxf,0,128
w		dc.b	255,0,0,0,3*cyf,2*cxf,6*cyf,3*cxf,3*cyf,4*cxf,6*cyf,6*cxf,3*cyf,6*cxf,0,128
x		dc.b    255,0,0,6*cxf,6*cyf,255,6*cxf,0,0,6*cyf,128
y		dc.b	255,0,0,3*cxf,3*cyf,6*cxf,0,255,3*cxf,3*cyf,3*cxf,6*cyf,128
z		dc.b	255,0,0,6*cxf,0,0,6*cyf,6*cxf,6*cyf,128

 * RasterZeichensatz *

rcharac		dc.b	0,0,0,0,0,0,0,0 ->Space
		dc.b	126,102,102,102,102,102,126,0
		dc.b	12,12,12,28,28,28,28,0
		dc.b	126,6,6,126,96,96,126,0
		dc.b	126,2,2,62,6,6,126,0
		dc.b	96,96,96,102,126,6,6,0
		dc.b	126,96,96,126,6,6,126,0
		dc.b	96,96,96,126,98,98,126,0
		dc.b	126,6,6,6,12,12,12,0
		dc.b	126,98,98,126,98,98,126,0
		dc.b	126,70,70,126,14,14,14,0
		dc.b	62,38,38,126,102,102,102,0
		dc.b	124,102,102,108,102,102,124,0
		dc.b	126,102,96,96,96,102,126,0
		dc.b	120,108,102,102,102,102,126,0
		dc.b	126,64,64,126,96,96,126,0
		dc.b	126,96,96,124,96,96,96,0
		dc.b	126,64,64,78,98,98,126,0
		dc.b	98,98,98,126,114,114,114,0
		dc.b	126,12,12,28,28,28,126,0
		dc.b	62,102,6,6,6,6,54,28
		dc.b	102,102,110,120,110,102,102,0
		dc.b	48,48,48,112,112,112,126,0
		dc.b	126,82,82,86,70,70,70,0
		dc.b	124,102,102,102,102,102,102,0
		dc.b	126,70,70,70,70,70,126,0
		dc.b	126,66,66,126,64,96,96,0
		dc.b	126,98,98,98,106,100,122,0
		dc.b	124,68,68,126,102,102,102,0
		dc.b	126,70,64,126,6,102,126,0
		dc.b	126,24,24,24,24,24,24,0
		dc.b	70,70,70,70,70,70,126,0
		dc.b	98,98,98,102,102,60,24,0
		dc.b	109,109,109,73,73,73,127,0
		dc.b	102,102,102,60,102,102,102,0
		dc.b	70,70,70,70,60,24,24,0
		dc.b	126,98,6,12,24,50,126,0
		dc.b	0,0,0,1,7,28,112,192
		dc.b	0,24,120,204,12,6,6,3

 * Speicher für Lev.Aufbau *

memforLVA	ds.b    MaxWays*2*12  
memforzap	ds.b	360

			***** Finisch! *****
