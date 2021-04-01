.NOLIST
#include "ion.inc"
.LIST

; levels:
; 0 000 forest
; 1 001 rain
; 2 010 motorway
; 3 011 snow
; 4 100 desert
; 5 101 storm


;******** Symbolic constants ********
INIHZ	.equ	12			; initial horizon position
INICR	.equ	76			; initial car position
INIOP	.equ	40			; initial opponent car position
OPSPD	.equ	200			; opponent cars' speed
HTSPD	.equ	190			; speed after hitting opponent
CFREQ	.equ	50			; gap between opponent cars
LTMIN	.equ	3			; minimum length of lightning flash
LTMAX	.equ	6			; maximum length of lightning flash
LTFRQ	.equ	100			; reciprocal of probablilty of lightning flash on a given frame
SNSPD	.equ	2			; frames between falling of snow
CLINT	.equ	32			; clock tick interval
SPLEN	.equ	4			; number of frames per sparks
STEER	.equ	$0110			; steering ability
CHLEN	.equ	64			; length of checkpoint display


;******** saferam1 offsets ********
tByte	.equ	0			; pointer to current type byte of track (16-bit)
bPos	.equ	tByte+2		; position within current track section
poly	.equ	bPos+1		; polygon currently being drawn (0, 1, 2, ...)
row	.equ	poly+1		; current y-position of road (63, 62, 61, ...)
col	.equ	row+1			; current x-position of left edge of road (16-bit)
dPos	.equ	col+2			; position within current track section being drawn
angle	.equ	dPos+1		; angle of deviation from straight road (0 at bottom of screen)
width	.equ	angle+1		; current width of road (decreases due to perspective)
horiz	.equ	width+1		; current y-position of horizon
tDist	.equ	horiz+1		; total distance travelled from start (16-bit)
dDist	.equ	tDist+2		; distance from start to current polygon being drawn (16-bit)
endX	.equ	dDist+2		; x-position of last left tunnel-wall drawn
endW	.equ	endX+1		; width of last tunnel drawn
begX	.equ	endW+1		; x-position of first tunnel-wall drawn
begW	.equ	begX+1		; width of first tunnel drawn
prevB	.equ	begW+1		; previous type byte of track
backR	.equ	prevB+1		; current background picture row
fByte	.equ	backR+1		; final type byte of current frame
bkBuf	.equ	fByte+2		; 12-byte line buffer for drawing semi-backgrounds
tnMin	.equ	bkBuf+12		; minimum x-position of tunnel wall
tnMax	.equ	tnMin+1		; maximum x-position of tunnel wall
car	.equ	tnMax+1		; x-position of car
speed	.equ	car+2			; car speed
fPos	.equ	speed+1		; car position within current polygon
rainF	.equ	fPos+1		; current rain animation frame
opPos	.equ	rainF+1		; horizontal position of opponent car (40 to 220)
opDst	.equ	opPos+1		; distance to opponent car
opX	.equ	opDst+2		; x-position of opponent car
opY	.equ	opX+1			; y-position of opponent car
carX	.equ	opY+1			; x-position of car being drawn
carY	.equ	carX+1		; y-position of car being drawn
carH	.equ	carY+1		; height of car being drawn
bounc	.equ	carH+1		; opponent car's bounce direction
arrow	.equ	bounc+1		; equals 1 when drawing an arrow sprite
light	.equ	arrow+1		; frames left to go on current lightning flash
sFall	.equ	light+1		; frames to go before snow falls
level	.equ	sFall+1		; current level
flip	.equ	level+1		; bit 0 flips each cycle 2nd is pressed
time	.equ	flip+1		; amount of time left
clock	.equ	time+1		; clock tick counter
spark	.equ	clock+1		; frames left to go on current sparks
check	.equ	spark+1		; frames left to go on checkpoint display
numCp	.equ	check+1		; number of checkpoints passed through
won	.equ	numCp+1		; set to 1 when won level
item	.equ	won+1			; selected main menu item
score	.equ	item+1		; score (16-bit)
tmPtr	.equ	score+2		; pointer to next extra time amount (16-bit)
dataP	.equ	tmPtr+2		; location of data file (16-bit)


;******** Program ********

#ifdef TI83P
	.org	progstart-2
	.db	$BB,$6D
#else
	.org	progstart
#endif
	ret
	jr	nc,start
	.db	"Lotus Turbo Challenge 1.0",0

start:
	ld	hl,(vat)
	ld	ix,detectString
	call	ionDetect
	ret	nz
	ld	(saferam1+dataP),hl

	ld	ix,saferam1		; initialise IX so we can use our offsets

	ld	(ix+item),0
	ld	(ix+level),0

mainMenu:
	ld	(ix+score),0
	ld	(ix+score+1),0
	bcall(_cleargbuf)		; clear graph buffer
	ld	de,plotsscreen	; draw pictures on menu
	ld	hl,heading
	call	addDataHL
	ld	bc,22*12
	ldir
	ld	de,plotsscreen+(12*43)
	ld	hl,silhouette
	call	addDataHL
	ld	bc,21*12
	ldir

	call	ionFastCopy

menu:
	ld	bc,22*256+11	; draw text on menu
	ld	hl,txtUrl
	call	addDataHL
	call	printSmall
	ld	bc,29*256+0
	ld	hl,txtLevel
	call	addDataHL
	bit	0,(ix+item)
	jr	nz,notLevel
	set	textInverse,(iy+textflags)
notLevel:
	call	printSmall
	res	textInverse,(iy+textflags)

	ld	b,(ix+level)
	ld	hl,txt1
	call	addDataHL
	ld	a,0
	call	levelNum
	ld	hl,txt2
	call	addDataHL
	ld	a,1
	call	levelNum
	ld	hl,txt3
	call	addDataHL
	ld	a,2
	call	levelNum
	ld	hl,txt4
	call	addDataHL
	ld	a,3
	call	levelNum
	ld	hl,txt5
	call	addDataHL
	ld	a,4
	call	levelNum
	ld	hl,txt6
	call	addDataHL
	ld	a,5
	call	levelNum

	ld	bc,36*256+0
	ld	hl,txtReset
	call	addDataHL
	bit	0,(ix+item)
	jr	z,notReset
	set	textInverse,(iy+textflags)
notReset:
	call	printSmall
	res	textInverse,(iy+textflags)
	ld	bc,29*256+60
	ld	hl,txtHigh
	call	addDataHL
	call	printSmall
	push	ix
	ld	hl,(highScore)
	bcall(_setxxxxop2)
	bcall(_op2toop1)
	ld	bc,36*256+60
	ld	(pencol),bc
	ld	a,5
	bcall(_dispop1a)
	pop	ix

titleLoop:
	ld	a,$fe
	out	(1),a
	in	a,(1)
	cp	254			; down
	jr	z,down
	cp	253			; left
	jr	z,left
	cp	251			; right
	jr	z,right
	cp	247			; up
	jr	z,up
	ld	a,$fd
	out	(1),a
	in	a,(1)
	cp	191			; CLEAR
	ret	z
	ld	a,$bf
	out	(1),a
	in	a,(1)
	cp	223			; 2nd
	jr	z,choose
	jr	titleLoop

up:
	ld	(ix+item),0
	jp	menu

down:
	ld	(ix+item),1
	jp	menu

left:
	bit	0,(ix+item)
	jp	nz,menu
	ld	a,(ix+level)
	cp	0
	jp	z,menu
	dec	(ix+level)
	jp	menu

right:
	bit	0,(ix+item)
	jp	nz,menu
	ld	a,(ix+level)
	ld	hl,highLevel
	cp	(hl)
	jp	z,menu
	inc	(ix+level)
	jp	menu

choose:
	bit	0,(ix+item)		; start a level if level is selected on menu
	jp	nz,resetGame
game:
	bcall(_cleargbuf)		; clear graph buffer
	ld	de,plotsscreen+(12*43)	; draw silhouette
	ld	hl,silhouette
	call	addDataHL
	ld	bc,21*12
	ldir
	call	ionFastCopy
	ld	a,(ix+level)	; draw track name
	ld	de,track1
	ld	hl,course1
	cp	0
	jr	z,gotTrack
	ld	de,track2
	ld	hl,course2
	cp	1
	jr	z,gotTrack
	ld	de,track3
	ld	hl,course3
	cp	2
	jr	z,gotTrack
	ld	de,track4
	ld	hl,course4
	cp	3
	jr	z,gotTrack
	ld	de,track5
	ld	hl,course5
	cp	4
	jr	z,gotTrack
	ld	de,track6
	ld	hl,course6
gotTrack:
	call	addDataDE
	call	addDataHL
	push	de
	ld	bc,$0001
	call	printLarge
	ld	hl,course
	call	addDataHL
	bcall(_puts)
	ld	bc,$0303
	ld	hl,txtGetReady
	call	addDataHL
	call	printLarge
	pop	de			; initialise tByte
	ex	de,hl
	ld	(saferam1+tByte),hl
	call	bigDelay
	call	bigDelay

	ld	(ix+bPos),0		; initialise variables
	ld	(ix+horiz),INIHZ
	ld	(ix+tDist),0
	ld	(ix+tDist+1),0
	ld	(ix+car),0
	ld	(ix+car+1),INICR
	ld	(ix+speed),0
	ld	(ix+fPos),0
	ld	(ix+rainF),0
	ld	(ix+light),0
	ld	(ix+sFall),SNSPD
	ld	(ix+opPos),INIOP
	ld	(ix+opDst),0
	ld	(ix+opDst+1),0
	ld	(ix+bounc),1
	ld	(ix+flip),0
	ld	(ix+clock),CLINT
	ld	(ix+spark),0
	ld	(ix+check),0
	ld	(ix+numCp),0
	ld	(ix+won),0

	ld	hl,extraTimes	; make tmPtr point to first extra time amount
	call	addDataHL
	ld	a,(ix+level)
	cp	0
	jr	z,gotTimePtr
	ld	de,numChecks
	call	addDataDE
	ld	b,a
timePtrLoop:
	push	bc
	ld	a,(de)
	ld	b,0
	ld	c,a
	add	hl,bc
	inc	de
	pop	bc
	djnz	timePtrLoop
gotTimePtr:
	ld	a,(hl)		; initialise time
	ld	(ix+time),a
	inc	hl
	ld	(saferam1+tmPtr),hl

drive:
	bit	0,(ix+won)		; don't clock down if won level
	jr	nz,sameTime
	dec	(ix+clock)		; tick clock down
	ld	a,(ix+clock)
	cp	0
	jr	nz,sameTime
	ld	(ix+clock),CLINT
	ld	a,(ix+time)
	cp	0
	jr	z,sameTime
	dec	(ix+time)
sameTime:

	ld	a,(ix+opDst+1)	; wrap opponent car if necessary
	cp	CFREQ
	jr	c,doneWrap
	cp	(CFREQ+256)/2
	jr	c,pastHorizon
	ld	(ix+opDst+1),CFREQ-1
	jr	doneWrap
pastHorizon:
	ld	(ix+opDst+1),0
doneWrap:

	bit	0,(ix+bounc)
	jr	z,bounceLeft
	inc	(ix+opPos)
	inc	(ix+opPos)
	ld	a,(ix+opPos)
	cp	220
	jr	nz,doneBounce
	ld	(ix+bounc),0
	jr	doneBounce
bounceLeft:
	dec	(ix+opPos)
	dec	(ix+opPos)
	ld	a,(ix+opPos)
	cp	40
	jr	nz,doneBounce
	ld	(ix+bounc),1
doneBounce:

	call	display

	ld	hl,(saferam1+opDst)	; move opponent car forward by his speed
	ld	bc,OPSPD
	add	hl,bc
	ld	(saferam1+opDst),hl

	ld	a,$ff			; reset keyport
	out	(1),a
	ld	a,$fd
	out	(1),a
	in	a,(1)
	cp	191			; check if CLEAR is pressed
	jp	z,exitLevel

	ld	a,$fe
	out	(1),a
	in	a,(1)
	cp	253			; check if left is pressed
	jr	nz,noLeft
	ld	hl,(saferam1+car)
	ld	bc,STEER
	scf
	ccf
	sbc	hl,bc
	ld	(saferam1+car),hl
noLeft:
	cp	251			; check if right is pressed
	jr	nz,noRight
	ld	hl,(saferam1+car)
	ld	bc,STEER
	add	hl,bc
	ld	(saferam1+car),hl
noRight:

	ld	a,$df
	out	(1),a
	in	a,(1)
	cp	127			; check if ALPHA is pressed
	jr	nz,noBrake
	call	decelerate		; if so, reduce speed
	call	decelerate
noBrake:

	ld	a,$bf
	out	(1),a
	in	a,(1)
	bit	6,a			; check if MODE is pressed
	push	af
	call	z,pause
	pop	af
	bit	5,a			; check if 2nd is pressed
	jp	z,accelerate	; if so, increase speed
doDecelerate:
	call	decelerate		; otherwise, decrease speed
	call	decelerate
noDecelerate:

	ld	a,(ix+speed)	; if speed is 0, don't move
	cp	0
	jp	z,doneHill
	ld	b,(ix+fPos)		; add speed to current position
	add	a,b
	ld	(ix+fPos),a
	inc	(ix+fPos)
	cp	b			; if addition has wrapped around, move onto next polygon
	jp	nc,doneHill

	ld	hl,(saferam1+opDst)	; move opponent car back by your speed
	ld	b,0
	ld	c,(ix+speed)
	inc	bc
	scf
	ccf
	sbc	hl,bc
	ld	(saferam1+opDst),hl

	ld	hl,(saferam1+tDist)	; increment distance counter
	inc	hl
	ld	(saferam1+tDist),hl

	bit	0,(ix+won)			; if haven't won level,
	jr	nz,noIncScore
	bit	0,l				; increment score every four polygons
	jr	z,noIncScore
	bit	1,l
	jr	z,noIncScore
	ld	hl,(saferam1+score)
	inc	hl
	ld	(saferam1+score),hl
noIncScore:

	ld	hl,(saferam1+tByte)
	inc	hl			; HL -> length of current track section
	ld	a,(hl)		; A = length of current track section
	inc	(ix+bPos)		; increment position within current track section
	cp	(ix+bPos)		; compare with length of current track section
	jr	nz,same1
	inc	hl			; if equal, move onto next track section
	ld	(ix+bPos),0
	ld	(saferam1+tByte),hl

	bit	1,(hl)		; check if on checkpoint
	jr	z,doneNext1
	bit	0,(ix+won)		; ignore checkpoint if won level
	jr	nz,doneNext1

	inc	(ix+numCp)		; check if last checkpoint
	push	hl
	ld	hl,numChecks
	call	addDataHL
	ld	b,0
	ld	c,(ix+level)
	add	hl,bc
	ld	a,(hl)
	pop	hl
	cp	(ix+numCp)
	jr	z,wonLevel

	ld	(ix+check),CHLEN		; if not, set number of frames left to go on checkpoint
	ld	a,(ix+time)			; and add on extra time
	ld	hl,(saferam1+tmPtr)
	add	a,(hl)
	inc	hl
	ld	(saferam1+tmPtr),hl
	cp	97				; ensure time doesn't exceed 96
	jr	c,timeOK
	ld	a,96
timeOK:
	ld	(ix+time),a
	jr	doneNext1

wonLevel:
	ld	(ix+won),1		; if so, set the won variable
	jr	doneNext1
same1:
	dec	hl			; otherwise, stay on current track section
doneNext1:

	bit	7,(hl)
	jr	z,straight
	ld	a,1		; load A with magnitude of angle change
	bit	5,(hl)
	jr	z,gentleCurve
	ld	a,2
gentleCurve:
	bit	6,(hl)	; negate A if at a right turn
	jr	z,addCar
	neg
addCar:
	add	a,(ix+car+1)	; adjust car position
	ld	(ix+car+1),a
straight:

	bit	0,(ix+tDist)	; change horizon every four polygons
	jr	z,doneHill
	bit	1,(ix+tDist)
	jr	z,doneHill
	bit	4,(hl)		; if bit 4 of current track type byte is 0,
	jr	z,doneHill		; don't change horizon
	bit	3,(hl)		; change horizon depending on state of bit 3
	jr	z,uphill
	inc	(ix+horiz)
	jr	doneHill
uphill:
	dec	(ix+horiz)
doneHill:

	call	fixCarPos

	jp	drive

accelerate:
	bit	0,(ix+won)		; don't accelerate if won level
	jp	nz,doDecelerate
	ld	a,(ix+time)		; don't accelerate if out of time
	cp	0
	jp	z,doDecelerate
	bit	0,(ix+flip)		; only accelerate every second time
	jr	z,flipZero
	res	0,(ix+flip)
	jr	doneFlip
flipZero:
	set	0,(ix+flip)
doneFlip:
	bit	0,(ix+flip)
	jp	nz,noDecelerate
	ld	a,(ix+speed)	; ensure speed doesn't exceed 255
	cp	255
	jp	z,noDecelerate
	inc	(ix+speed)
	jp	noDecelerate

decelerate:
	ld	a,(ix+speed)
	cp	0
	jr	nz,notStopped
	bit	0,(ix+won)	; if stopped,
	jr	z,noWin	; don't decelerate if haven't won
	pop	bc		; if have won, remove return address from stack
	jp	endLevel	; and go to end level screen
noWin:
	ld	a,(ix+time)
	cp	0
	ret	nz
	pop	bc		; if time out, remove return address from stack
	jp	endLevel	; and go to end level screen

notStopped:
	dec	(ix+speed)	; reduce speed
	ret

display:
	bcall(_cleargbuf)		; clear graph buffer
	ld	(ix+poly),0		; initialise variables
	ld	(ix+row),63
	ld	(ix+col),0
	ld	(ix+col+1),12
	ld	(ix+angle),0
	ld	(ix+width),72
	ld	(ix+begX),0
	ld	(ix+tnMin),95
	ld	(ix+tnMax),0

	ld	a,(ix+bPos)
	ld	(ix+dPos),a

	ld	bc,(saferam1+tDist)
	ld	(saferam1+dDist),bc

	ld	hl,plotsscreen	; display time
	ld	b,(ix+time)
	ld	c,%10000000
	ld	a,b
	cp	0
	call	nz,drawLine

	ld	hl,(saferam1+tByte)	; HL -> current track type byte

drawLoop:
	push	hl			; save the current track type byte pointer

	bit	2,(hl)		; if bit 2 is set, draw a tunnel
	jp	nz,tunnel
	bit	0,(ix+dDist)	; otherwise, draw a tree every 4 polygons
	jp	z,noObj
	bit	1,(ix+dDist)
	jp	z,noObj

	ld	a,(ix+poly)	; load B with appropriate sprite index (0 = big)
	call	getIndex
	ld	e,b		; save sprite index in E
	push	de
	push	hl
	ld	(ix+arrow),0	; initialise arrow
	bit	7,(hl)		; don't draw arrow if on straight
	jr	z,noArrows1
	bit	6,(hl)		; draw arrow if right corner
	jr	z,noArrows1
	ld	(ix+arrow),1
	ld	hl,arrowsRight	; HL -> start of right arrow sprites
	call	addDataHL
	ld	c,16			; height of arrow index 0
	ld	d,2			; difference between arrow heights
	jr	gotType1
noArrows1:
	ld	hl,trees	; HL -> start of tree sprites
	call	addDataHL
	ld	bc,105	; BC = size of each tree set
	ld	a,(ix+level)
	cp	5		; if on storm course, use left lamps
	jr	nz,getTreeLoop1
	ld	a,2
getTreeLoop1:		; calculate start of correct tree sprite
	cp	0
	jr	z,gotTree1
	add	hl,bc
	dec	a
	jr	getTreeLoop1
gotTree1:
	ld	c,24		; size of tree index 0
	ld	d,3		; difference between tree heights
gotType1:
	call	setupObstacle	; HL -> sprite, E = yPos, C = sprite height, B = width
	ld	a,(ix+col+1)
	sub	b
	dec	a			; A = xPos
	bit	0,(ix+arrow)	; shift sprite right if arrow
	jr	z,notArrow1
	add	a,3
notArrow1:
	push	ix			; draw left obstacle
	call	DRWSPR
	pop	ix

	pop	hl
	pop	de
	ld	(ix+arrow),0	; initialise arrow
	bit	7,(hl)		; don't draw arrow if on straight
	jr	z,noArrows2
	bit	6,(hl)		; draw arrow if left corner
	jr	nz,noArrows2
	ld	(ix+arrow),1
	ld	hl,arrowsLeft	; HL -> start of left arrow sprites
	call	addDataHL
	ld	c,16			; height of arrow index 0
	ld	d,2			; difference between arrow heights
	jr	gotType2
noArrows2:
	ld	hl,trees	; HL -> start of tree sprites
	call	addDataHL
	ld	bc,105	; BC = size of each tree set
	ld	a,(ix+level)
	cp	2		; if on motorway course, use right lamps
	jr	nz,getTreeLoop2
	ld	a,5
getTreeLoop2:		; calculate start of correct tree sprite
	cp	0
	jr	z,gotTree2
	add	hl,bc
	dec	a
	jr	getTreeLoop2
gotTree2:
	ld	c,24		; size of tree index 0
	ld	d,3		; difference between tree heights
gotType2:
	call	setupObstacle	; HL -> sprite, E = yPos, C = sprite height
	ld	a,(ix+col+1)
	add	a,(ix+width)
	inc	a			; A = xPos
	bit	0,(ix+arrow)	; shift sprite left if arrow
	jr	z,notArrow2
	sub	3
notArrow2:
	push	ix			; draw right obstacle
	call	DRWSPR
	pop	ix

	ld	a,(ix+poly)	; if drawing first polygon,
	cp	0
	jr	nz,noObj
	ld	a,(ix+car+1)	; check if car has hit tree
	cp	16
	jr	nc,leftOK1
	ld	(ix+car+1),20
	srl	(ix+speed)
leftOK1:
	cp	81
	jr	c,noObj
	ld	(ix+car+1),76
	srl	(ix+speed)

	jr	noObj

tunnel:

	bit	0,(ix+dDist); draw tunnel walls every two polygons
	call	z,tunWalls

noObj:

	ld	a,(ix+opDst+1)	; check if opponent car is on current polygon
	cp	(ix+poly)
	jr	nz,doPoly

	ld	d,0			; opX = col + opPos * width/256
	ld	e,(ix+width)
	ld	hl,(saferam1+col)
	ld	b,(ix+opPos)
opCalc:
	add	hl,de
	djnz	opCalc
	ld	de,0			; ensure calculation takes constant time
constTime:
	add	hl,de
	djnz	constTime
	ld	(ix+opX),h
	ld	a,(ix+row)		; opY = current row
	ld	(ix+opY),a
doPoly:

	ld	a,(ix+poly)	; load B with correct height of polygon
	cp	3
	jr	nc,not3
	ld	b,3
	jr	gotPolySize
not3:
	cp	8
	jr	nc,not2
	ld	b,2
	jr	gotPolySize
not2:
	ld	b,1
gotPolySize:

polyLoop:			; begin drawing the polygon
	push	bc		; save progress in current polygon

	ld	a,(ix+level); check if on storm course
	cp	5
	jr	z,stormCourse

	ld	a,(ix+dPos)	; if not, draw road if NOT a checkpoint
	cp	2
	jr	nc,polyLine
	pop	bc
	pop	hl
	bit	1,(hl)
	push	hl
	push	bc
	jr	nz,noEdges
	jr	polyLine

stormCourse:
	pop	bc		; if so, draw road if a checkpoint
	pop	hl
	bit	1,(hl)
	push	hl
	push	bc
	jr	z,roadEdges
	ld	a,(ix+dPos)
	cp	2
	jr	nc,roadEdges

polyLine:
	ld	a,(ix+col+1); draw a horizontal line of polygon
	ld	e,(ix+row)
	call	ionGetPixel
	ld	c,a		; C = initial bit pattern
	ld	b,(ix+width); B = length of line
	call	drawLine
	jr	noEdges

roadEdges:
	bit	0,(ix+dDist)	; draw a reflector if bits 0 and 1 of dDist are set
	jr	z,noEdges
	bit	1,(ix+dDist)
	jr	z,noEdges
	ld	a,b
	cp	1
	jr	nz,noEdges

	ld	a,(ix+col+1)
	call	drawRoadDot

	call	getColWidth
	add	a,b
	dec	a
	call	drawRoadDot
noEdges:

	bit	0,(ix+dDist)	 ; draw white road lines if bits 0 and 1 of dDist are set
	jr	z,noLine
	bit	1,(ix+dDist)
	jr	z,noLine

	call	getColWidth
	srl	b
	add	a,b
	call	drawRoadLine

	call	getColWidth
	srl	b
	srl	b
	add	a,b
	call	drawRoadLine

	call	getColWidth
	srl	b
	add	a,b
	srl	b
	add	a,b
	call	drawRoadLine

noLine:

	dec	(ix+width)	; decrease width
	dec	(ix+width)
	dec	(ix+row)	; decrease row
	inc	(ix+col+1)	; increase column due to perspective

	ld	a,(ix+angle); load A with absolute value of angle
	bit	7,a
	jr	z,noNeg1
	neg
noNeg1:
	ld	h,0		; multiply by 24
	ld	l,a
	sla	l
	sla	l
	sla	l
	rl	h
	push	hl
	sla	l
	rl	h
	pop	bc
	add	hl,bc
	ld	b,h
	ld	c,l

	ld	hl,(saferam1+col)
	bit	7,(ix+angle); add/subtract from column according to sign of angle
	jr	z,noNeg2
	scf
	ccf
	sbc	hl,bc
	jr	doneAdd
noNeg2:
	add	hl,bc
doneAdd:
	ld	(saferam1+col),hl

	pop	bc		; recall progress in current poylgon
	dec	b
	jp	nz,polyLoop	; draw rest of polygon


	ld	hl,(saferam1+dDist)	; increment distance of current polygon
	inc	hl
	ld	(saferam1+dDist),hl

	pop	hl		; recall the current track type byte pointer

	bit	7,(hl)	; if bit 7 is zero, track is straight (don't change angle)
	jr	z,doneAngle
	ld	a,1		; load A with magnitude of angle change
	bit	5,(hl)
	jr	z,gentleAngle
	ld	a,2
gentleAngle:
	bit	6,(hl)	; negate A if at a left turn
	jr	nz,addAngle
	neg
addAngle:
	add	a,(ix+angle); adjust the angle variable
	ld	(ix+angle),a
doneAngle:

	inc	hl		; increment track byte pointer if necessary
	ld	a,(hl)
	inc	(ix+dPos)
	cp	(ix+dPos)
	jr	nz,same2
	inc	hl
	ld	(ix+dPos),0
	jr	doneNext2
same2:
	dec	hl
doneNext2:
	inc	(ix+poly)

	ld	a,(ix+poly)	; draw next polygon
	cp	(ix+horiz)
	jp	nz,drawLoop


	ld	(saferam1+fByte),hl	; save the final track type byte

	bit	2,(hl)	; if there is no tunnel on the horizon, skip this
	jr	z,noTunEnd

	call	tunWalls	; draw tunnel walls at the horizon

	ld	d,2		; initial gap between lines (will be halved)
	ld	e,28		; E = y-position
endTunnel:
	push	de
	ld	a,(ix+dDist); if dDist + row + D is even, don't draw a line
	add	a,(ix+row)
	add	a,d
	bit	0,a
	jr	z,noTunLine
	ld	a,(ix+col+1); draw a line
	dec	a
	call	ionGetPixel
	ld	c,a
	ld	a,(ix+width)
	add	a,2
	ld	b,a
	call	drawLine
noTunLine:
	pop	de
	ld	a,e		; increment y-position by half of D
	push	de
	srl	d
	add	a,d
	pop	de
	ld	e,a
	inc	d		; increment gap between lines
	ld	b,(ix+row)	; end loop if at horizon
	cp	b
	jr	c,endTunnel

	call	tunHoriz	; draw horizon at end of tunnel

noTunEnd:

	ld	hl,(saferam1+tByte)	; check whether front polygon is in a tunnel
	bit	2,(hl)		; it not, draw a normal horizon
	jr	z,normHoriz

	call	tunHoriz		; draw horizon at end of tunnel

	bit	2,(ix+prevB)	; if previous front polygon is was not in tunnel,
	jr	z,semiHoriz		; car is at entrance to tunnel, so draw semi-horizon

	ld	hl,plotsscreen+(12*27)	; draw tunnel roof along full width of screen
	ld	b,12
roof:
	ld	(hl),%11111111
	inc	hl
	djnz	roof

	ld	a,(ix+car+1)	; check if car has hit tunnel
	cp	19
	jr	nc,leftOK2
	ld	(ix+spark),SPLEN
	ld	(ix+car+1),23
	srl	(ix+speed)
	jr	doneTunCrash
leftOK2:
	cp	78
	jr	c,doneTunCrash
	ld	(ix+spark),SPLEN
	ld	(ix+car+1),73
	srl	(ix+speed)
doneTunCrash:

	ld	a,(ix+spark)
	cp	0
	jp	z,doneHoriz
	ld	e,55
	ld	c,6
	ld	a,(ix+car+1)
	cp	47
	jr	c,drawLeftSparks
	ld	a,82
	ld	hl,sparkRight
	call	addDataHL
	jr	drawSparks
drawLeftSparks:
	ld	a,6
	ld	hl,sparkLeft
	call	addDataHL
drawSparks:
	push	ix
	call	DRWSPR
	pop	ix
	dec	(ix+spark)

	jr	doneHoriz

normHoriz:
	ld	a,(ix+begX)		; if a tunnel is approaching, only draw horizon on edges
	cp	0
	jr	nz,semiHoriz

	ld	a,0			; draw a full horizon
	ld	e,(ix+row)
	call	ionGetPixel
	ld	b,12
horizon:
	ld	(hl),%11111111
	inc	hl
	djnz	horizon
	jr	doneHoriz

semiHoriz:
	ld	a,0			; draw a horizon to the left and right of the tunnel
	ld	e,(ix+row)
	call	ionGetPixel
	ld	c,a
	ld	b,(ix+begX)
	dec	b
	dec	b
	call	drawLine
	ld	a,(ix+begX)
	add	a,(ix+begW)
	inc	a
	inc	a
	ld	e,(ix+row)
	call	ionGetPixel
	ld	c,a
	ld	a,96
	sub	(ix+begX)
	sub	(ix+begW)
	ld	b,a
	dec	b
	dec	b
	call	drawLine

	ld	a,(ix+tnMax)	; draw the tunnel roof
	inc	a
	sub	(ix+tnMin)
	push	af
	ld	a,(ix+tnMin)
	ld	hl,plotsscreen+(12*27)
	call	getbit
	pop	bc
	ld	c,a
	call	drawLine

doneHoriz:

	ld	a,(ix+horiz)	; calculate y-position of background picture
	sla	a
	ld	b,(ix+horiz)
	srl	b
	add	a,b
	neg
	add	a,51
	ld	(ix+backR),a
	ld	a,0
	ld	e,(ix+backR)
	call	ionGetPixel		; HL -> correct location in graph buffer
	ex	de,hl
	ld	hl,backgrounds
	call	addDataHL
	ld	bc,19*12
	ld	a,(ix+level)
levelLoop:
	cp	0
	jr	z,gotBackground
	add	hl,bc
	dec	a
	jr	levelLoop
gotBackground:
	ex	de,hl

	ld	c,0			; C = number of rows drawn
backLoop:
	ld	a,(ix+begX)		; if there are no tunnels in frame, jump to normBack
	cp	0
	jr	z,normBack
	ld	a,(ix+backR)	; otherwise if below height of tunnel roof, jump to semiBack
	cp	28
	jr	nc,semiBack
normBack:
	push	hl			; if inside a tunnel, don't draw anything above tunnel roof
	ld	hl,(saferam1+tByte)
	bit	2,(hl)
	pop	hl
	jr	nz,skipLine
	ld	a,c			; if 19 or more lines have been drawn, draw dither pattern
	cp	19
	jr	nc,ditherBack
	ld	b,12			; OR background pic with graph buffer line
normLoop:
	ld	a,(de)
	or	(hl)
	ld	(hl),a
	inc	de
	inc	hl
	djnz	normLoop
	jr	doneLine
ditherBack:
	ld	b,12			; OR dither pattern with graph buffer line
ditherLoop:
	ld	a,%10101010
	bit	0,c			; invert every second line of dither
	jr	nz,noFlip
	cpl
noFlip:
	or	(hl)
	ld	(hl),a
	inc	de
	inc	hl
	djnz	ditherLoop
	jr	doneLine
skipLine:
	push	bc			; increment graph buffer and background picture pointers
	ld	bc,12			; to next line but don't draw anything
	add	hl,bc
	ex	de,hl
	add	hl,bc
	ex	de,hl
	pop	bc
doneLine:
	inc	(ix+backR)		; increment current row
	inc	c			; increment number of lines drawn
	ld	a,(ix+backR)	; if at horizon, background is done
	cp	(ix+row)
	jr	nz,backLoop
	jp	doneBack

semiBack:
	bit	2,(ix+prevB)	; if tunnel is at front and back of frame
	jr	z,notInTun		; background is done
	push	hl
	ld	hl,(saferam1+fByte)
	bit	2,(hl)
	pop	hl
	jr	nz,doneBack
notInTun:
	ex	de,hl

semiLoop:
	push	bc
	push	de

	ld	de,saferam1+bkBuf	; load line buffer with picture or dither
	ld	a,c
	cp	19
	jr	nc,semiDither
	ld	bc,12
	ldir
	jr	doneBuffer
semiDither:
	ld	b,12
semiDitherLoop:
	ld	a,%10101010
	bit	0,c
	jr	nz,noFlip2
	cpl
noFlip2:
	ld	(de),a
	inc	de
	djnz	semiDitherLoop
doneBuffer:

	push	hl
	ld	hl,(saferam1+fByte)	; if tunnel at end of frame, jump to tunAtEnd
	bit	2,(hl)
	jr	nz,tunAtEnd

	ld	hl,saferam1+bkBuf		; otherwise, erase left and right of line buffer
	ld	c,%10000000			; to draw background at end of tunnel
	ld	b,(ix+endX)
	dec	b
	call	eraseLine
	ld	hl,saferam1+bkBuf
	ld	a,(ix+endX)
	add	a,(ix+endW)
	inc	a
	ld	b,a
	ld	a,96
	sub	b
	push	af
	ld	a,b
	call	getbit
	pop	bc
	ld	c,a
	call	eraseLine

	jr	doneErase
tunAtEnd:
	ld	hl,saferam1+bkBuf		; erase middle of line buffer so background
	ld	a,(ix+begX)			; doesn't overlap tunnel
	dec	a
	call	getbit
	ld	c,a
	ld	b,(ix+begW)
	inc	b
	inc	b
	call	eraseLine

doneErase:
	pop	hl
	pop	de
	push	hl				; OR the line buffer with the current graph buffer line
	ld	hl,saferam1+bkBuf
	ld	b,12
semiOr:
	ld	a,(de)
	or	(hl)
	ld	(de),a
	inc	de
	inc	hl
	djnz	semiOr
	pop	hl
	inc	(ix+backR)
	pop	bc
	inc	c			; continue with next line
	ld	a,(ix+backR)
	cp	(ix+row)
	jr	nz,semiLoop

doneBack:

	ld	a,(ix+opDst+1); load B with appropriate sprite index (0 = big)
	call	getIndex
	push	bc		; save the sprite index
	ld	hl,opCar
	call	addDataHL
	ld	c,32		; size of car index 0 (with mask)
	ld	a,b		; if car index is 0, don't change sprite address
	cp	0
	jr	z,car0
	ld	a,0		; calculate address offset...
getCar:
	add	a,c		; add car size (sprite and mask)
	push	af
	ld	a,c		; subtract 4 from car size each time
	sub	4
	ld	c,a
	pop	af
	djnz	getCar	; loop until at correct car sprite
car0:
	ld	b,0		; add address offset to HL
	ld	c,a
	add	hl,bc
	pop	bc		; recall the sprite index
	ld	a,8		; store the car sprite height and y-position
	sub	b
	ld	(ix+carH),a
	ld	a,(ix+opY)
	sub	(ix+carH)
	inc	a
	ld	(ix+carY),a
	ld	a,(ix+opX)	; store the car x-position
	sub	8
	ld	(ix+carX),a

	ld	a,(ix+opDst+1)	; don't draw opponent if he's past horizon
	cp	(ix+horiz)
	jr	nc,noOpponent
	cp	0			; check if crashed with opponent
	jr	nz,noCrash
	ld	a,(ix+car+1)
	add	a,15
	cp	(ix+opX)
	jr	c,noCrash
	sub	31
	cp	(ix+opX)
	jr	nc,noCrash
	ld	a,(ix+car+1)		; bump car
	cp	(ix+opX)
	jr	c,crashLeft
	add	a,4
	jr	doneCrash
crashLeft:
	sub	4
doneCrash:
	ld	(ix+car+1),a
	ld	a,(ix+speed)	; reduce speed if faster than opponent
	cp	OPSPD
	jr	c,noCrash
	ld	(ix+speed),HTSPD
noCrash:

	call	fixCarPos
	call	drawCar		; draw opponent car

noOpponent:

	ld	a,(ix+level)	; check if on storm course
	cp	5
	jr	nz,noFlash
	ld	hl,(saferam1+tByte)	; alway invert when in tunnel on storm course
	bit	2,(hl)
	jr	nz,invert
	ld	a,(ix+light)	; check if lightning is on
	cp	0
	jr	nz,contFlash
	ld	b,LTFRQ		; if not, randomise if one should occur
	call	ionRandom
	cp	0
	jr	nz,noFlash
	ld	b,LTMAX-LTMIN+1	; randomise its length
	call	ionRandom
	add	a,LTMIN
	ld	(ix+light),a
contFlash:
	dec	(ix+light)		; decrease flash's life
invert:
	ld	bc,12*64		; invert screen
	ld	hl,plotsscreen
invertScreen:
	ld	a,(hl)
	cpl
	ld	(hl),a
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,invertScreen
noFlash:

	bit	0,(ix+level)		; check if there is any precipitation
	jp	z,dry
	ld	hl,(saferam1+tByte)	; no precipitation when in tunnel
	bit	2,(hl)
	jp	nz,dry
	ld	a,(ix+level)
	cp	3			; snow course
	jr	nz,noSnow
	ld	hl,snow
	call	addDataHL
	jr	noDrift
noSnow:
	cp	1
	jr	nz,noDayRain
	ld	hl,rainDay		; rain course
	call	addDataHL
	jr	drift
noDayRain:
	ld	hl,rainNight	; storm course
	call	addDataHL
drift:
	bit	0,(ix+rainF)	; drift rain right every 2nd frame
	jr	z,noDrift
	bit	1,(ix+rainF)
	jr	z,noDrift
	ld	b,8
	push	hl
driftLoop:
	rrc	(hl)
	inc	hl
	djnz	driftLoop
	pop	hl
noDrift:

	ld	b,0		; calculate starting address of sprite
	ld	c,(ix+rainF)
	add	hl,bc
	ex	de,hl
	ld	hl,plotsscreen
rainLoop1:
	push	bc		; C = offset from start of rain sprite
	ld	b,8		; 8 rows of sprites
rainLoop2:
	push	bc
	ld	b,12		; 12 sprites across
rainLoop3:
	ld	a,(de)
	xor	(hl)
	ld	(hl),a
	inc	hl
	djnz	rainLoop3
	ld	bc,7*12	; move to next row of sprites
	add	hl,bc
	pop	bc
	djnz	rainLoop2
	inc	de		; move to next sprite byte and
	ld	bc,63*12	; go back to first row of sprites
	scf
	ccf
	sbc	hl,bc
	pop	bc
	inc	c		; increase offset
	ld	a,c		; wrap C back to 0 if C = 8
	cp	8
	jr	nz,noRainWrap
	ex	de,hl		; and return to top of sprite
	ld	bc,8
	scf
	ccf
	sbc	hl,bc
	ex	de,hl
	ld	c,0
noRainWrap:
	ld	a,c		; finish once C returns to original value
	cp	(ix+rainF)
	jr	nz,rainLoop1

	bit	1,(ix+level)	; fall each frame if raining
	jr	z,fall
	dec	(ix+sFall)		; only fall snow when sFall drops to 0
	jr	nz,dry
	ld	(ix+sFall),SNSPD	; reset sFall for next cycle
fall:
	dec	(ix+rainF)
	ld	a,(ix+rainF)	; return to original sprite once fallen 8 pixels
	cp	-1
	jr	nz,dry
	ld	(ix+rainF),7
dry:

	ld	a,(ix+car+1)	; draw player's car
	sub	8
	ld	(ix+carX),a
	ld	(ix+carY),56
	ld	(ix+carH),8
	ld	hl,ownCar
	call	addDataHL
	call	drawCar

	bit	0,(ix+won)		; check if won level
	jr	nz,winDisp

	ld	a,(ix+time)		; if not, check if out of time
	cp	0
	jr	nz,stillTime
	dec	(ix+check)		; if so, display out of time every two frames
	bit	0,(ix+check)
	jr	nz,doneDisp
	ld	a,0			; largeSprite requires A to be 0 (undocumented)
	ld	b,16			; height
	ld	c,12			; width * 8
	ld	h,0			; x-pos
	ld	l,2			; y-pos
	push	ix
	ld	ix,outOfTime
	call	addDataIX
	call	ionLargeSprite
	pop	ix
	jr	doneDisp

stillTime:
	ld	a,(ix+check)	; check if the word checkpoint should be displayed
	cp	0
	jr	z,doneDisp
	dec	(ix+check)		; if so, decrease number of frames to go
	bit	0,(ix+check)	; and display sprite every two frames
	jr	nz,doneDisp
	ld	a,0			; largeSprite requires A to be 0 (undocumented)
	ld	b,15			; height
	ld	c,12			; width * 8
	ld	h,0			; x-pos
	ld	l,2			; y-pos
	push	ix
	ld	ix,checkpoint
	call	addDataIX
	call	ionLargeSprite
	pop	ix
	jr	doneDisp

winDisp:
	dec	(ix+check)		; if won level, display congratulations every two frames
	bit	0,(ix+check)
	jr	nz,doneDisp
	ld	a,0			; largeSprite requires A to be 0 (undocumented)
	ld	b,10			; height
	ld	c,12			; width * 8
	ld	h,0			; x-pos
	ld	l,2			; y-pos
	push	ix
	ld	ix,congratulations
	call	addDataIX
	call	ionLargeSprite
	pop	ix

doneDisp:
	ld	hl,(saferam1+tByte)	; record current track byte type in prevB
	ld	a,(hl)
	ld	(ix+prevB),a

	call	ionFastCopy		; copy graph buffer to screen
	ret


;******** Subroutines ********

fixCarPos:
	ld	a,(ix+car+1)	; ensure car doesn't move off screen
	cp	8
	jr	nc,leftOK
	ld	(ix+car+1),8
leftOK:
	cp	89
	ret	c
	ld	(ix+car+1),88
	ret

getColWidth:			; load A with column and B with width
	ld	a,(ix+col+1)
	ld	b,(ix+width)
	ret

drawRoadLine:		; invert two dots on road at (A, row)
	push	af
	call	drawRoadDot
	pop	af
	dec	a

drawRoadDot:		; invert dot on road at (A, row)
	ld	e,(ix+row)
	call	ionGetPixel
	xor	(hl)
	ld	(hl),a
	ret

drawCar:			; draw a two-sprite car where
	push	hl		; HL -> 2 mask sprites and 2 picture sprites
	call	invertBlock
	pop	hl
	ld	a,(ix+carX)
	ld	e,(ix+carY)
	ld	c,(ix+carH)
	push	hl
	push	ix
	call	DRWSPR
	pop	ix
	pop	hl
	ld	a,(ix+carX)
	add	a,8
	ld	e,(ix+carY)
	ld	b,0
	ld	c,(ix+carH)
	add	hl,bc
	push	hl
	push	ix
	call	DRWSPR
	pop	ix
	call	invertBlock
	pop	hl
	ld	a,(ix+carX)
	ld	e,(ix+carY)
	ld	b,0
	ld	c,(ix+carH)
	add	hl,bc
	push	hl
	push	ix
	call	DRWSPR
	pop	ix
	pop	hl
	ld	a,(ix+carX)
	add	a,8
	ld	e,(ix+carY)
	ld	b,0
	ld	c,(ix+carH)
	add	hl,bc
	push	ix
	call	DRWSPR
	pop	ix
	ret

invertBlock:		; invert a block on-screen where car being drawn is
	ld	a,(ix+carX)
	ld	l,(ix+carY)
	ld	b,(ix+carH)
	push	ix
	ld	ix,block
	call	addDataIX
	call	ionPutSprite
	pop	ix
	ld	a,(ix+carX)
	add	a,8
	ld	l,(ix+carY)
	ld	b,(ix+carH)
	push	ix
	ld	ix,block
	call	addDataIX
	call	ionPutSprite
	pop	ix
	ret

getIndex:			; load B with index of correct sprite where
	cp	2		; A = polygon number
	jr	nc,notSize0
	ld	b,0
	ret
notSize0:
	cp	3
	jr	nc,notSize1
	ld	b,1
	ret
notSize1:
	cp	6
	jr	nc,notSize2
	ld	b,2
	ret
notSize2:
	cp	8
	jr	nc,notSize3
	ld	b,3
	ret
notSize3:
	cp	12
	jr	nc,notSize4
	ld	b,4
	ret
notSize4:
	cp	16
	jr	nc,notSize5
	ld	b,5
	ret
notSize5:
	ld	b,6
	ret


tunHoriz:
	ld	e,(ix+row)		; draw horizon at end of tunnel
	ld	a,(ix+endX)
	dec	a
	call	ionGetPixel
	ld	c,a
	ld	b,(ix+endW)
	inc	b
	inc	b
	call	drawLine
	ret

tunWalls:
	ld	a,(ix+col+1)	; draw the left tunnel wall
	dec	a
	cp	(ix+tnMin)		; record the minimum tunnel x-position
	jr	nc,leaveMin
	ld	(ix+tnMin),a
leaveMin:
	ld	e,(ix+row)
	call	ionGetPixel
	ld	c,a
	ld	b,(ix+width)
	ld	(ix+endW),b		; record the tunnel width at horizon
	ld	a,(ix+begX)		; record the tunnel width at front
	cp	0
	jr	nz,leaveBeg1
	ld	(ix+begW),b
leaveBeg1:
	srl	b
	ld	de,-12
tunLeft:
	ld	a,c
	or	(hl)
	ld	(hl),a
	add	hl,de
	djnz	tunLeft

	ld	b,(ix+col+1)	; draw the right tunnel wall
	ld	(ix+endX),b		; record the tunnel x-position at horizon
	ld	a,(ix+begX)		; record the tunnel x-position at front
	cp	0
	jr	nz,leaveBeg2
	ld	(ix+begX),b
leaveBeg2:
	ld	a,b
	add	a,(ix+width)
	cp	(ix+tnMax)		; record the maximum tunnel x-position
	jr	c,leaveMax
	ld	(ix+tnMax),a
leaveMax:
	ld	e,(ix+row)
	call	ionGetPixel
	ld	c,a
	ld	b,(ix+width)
	srl	b
	ld	de,-12
tunRight:
	ld	a,c
	or	(hl)
	ld	(hl),a
	add	hl,de
	djnz	tunRight
	ret

setupObstacle:		; make HL -> sprite, E = yPos, C = sprite height, B = width
	ld	b,e
	ld	a,b		; if tree index is 0, don't change sprite address
	cp	0
	jr	z,tree0
	ld	a,0		; calculate address offset...
getTree:
	add	a,c		; add tree height
	push	af
	ld	a,c		; subtract 3 from tree height each time
	sub	d
	ld	c,a
	pop	af
	djnz	getTree	; loop until at correct tree sprite
tree0:
	ld	d,c		; D = height of sprite
	ld	b,0		; add address offset to HL
	ld	c,a
	add	hl,bc

	ld	b,e		; B = tree index
	ld	a,(ix+row)
	sub	d
	ld	e,a
	inc	e		; E = yPos

	ld	a,8
	sub	b
	ld	b,a		; B = width of sprite
	ld	c,d		; C = height of sprite
	ret

drawLine:			; draw a horizontal line
	ld	a,c		; C = initial bit pattern
	or	(hl)		; HL -> graph buffer byte containing start of line
	ld	(hl),a
	dec	b		; B = length of line
	ld	a,b
	cp	0
	ret	z
	srl	c
	jr	nc,drawLine
	inc	hl
	ld	c,%10000000
	ld	a,b
	srl	a
	srl	a
	srl	a
	jr	z,drawLine
lineLoop:
	ld	(hl),%11111111
	inc	hl
	dec	a
	jr	nz,lineLoop
	ld	a,b
	and	%00000111
	ret	z
	ld	b,a
	jr	drawLine

eraseLine:			; erase a horizontal line
	ld	a,(hl)	; HL -> graph buffer byte containing start of line
	cpl
	or	c		; C = initial bit pattern
	cpl
	ld	(hl),a
	dec	b		; B = length of line
	ld	a,b
	cp	0
	ret	z
	srl	c
	jr	nc,eraseLine
	inc	hl
	ld	c,%10000000
	ld	a,b
	srl	a
	srl	a
	srl	a
	jr	z,eraseLine
eraseLoop:
	ld	(hl),%00000000
	inc	hl
	dec	a
	jr	nz,eraseLoop
	ld	a,b
	and	%00000111
	ret	z
	ld	b,a
	jr	eraseLine

printSmall:
	ld	(pencol),bc
	bcall(_vputs)	; bjump() crashed the 83+ here
	ret

printLarge:
	ld	(currow),bc
	bcall(_puts)	; bjump() crashed the 83+ here
	ret

levelNum:
	cp	b		; display level number on menu
	jr	nz,notCurLevel
	set	textInverse,(iy+textflags)
notCurLevel:
	bcall(_vputs)
	res	textInverse,(iy+textflags)
	ret

exitLevel:				; when CLEAR pressed in level
	bit	0,(ix+won)		; don't reset time if won level
	jr	nz,endLevel
	ld	(ix+time),0

endLevel:
	bcall(_cleargbuf)		; clear graph buffer
	ld	de,plotsscreen+(12*43)	; display silhouette
	ld	hl,silhouette
	call	addDataHL
	ld	bc,21*12
	ldir

	ld	hl,plotsscreen	; display time
	ld	b,(ix+time)
	ld	c,%10000000
	ld	a,b
	cp	0
	call	nz,drawLine
	call	ionFastCopy

	ld	bc,$0202		; display score
	ld	hl,txtScore
	call	addDataHL
	call	printLarge
	ld	hl,(saferam1+score)
	bcall(_disphl)

	ld	a,(ix+time)		; check if time is zero
	cp	0
	jr	z,doneTime

	ld	hl,(saferam1+score)	; increase score
	ld	bc,30
	add	hl,bc
	ld	(saferam1+score),hl
	dec	(ix+clock)			; tick clock down
	ld	a,(ix+clock)
	cp	0
	jr	nz,endLevel
	ld	(ix+clock),CLINT
	dec	(ix+time)
	jr	endLevel
doneTime:
	call	bigDelay
	call	bigDelay
	bit	0,(ix+won)
	jr	z,gameOver
	ld	a,(ix+level)
	cp	5
	jr	z,wonGame
	inc	(ix+level)		; go to next level
	ld	b,(ix+level)	; adjust highest level
	ld	a,(highLevel)
	cp	b
	jp	nc,game
	ld	a,b
	ld	(highLevel),a
	jp	game
gameOver:
	ld	bc,$0300		; display game over
	ld	hl,txtGameOver
	call	addDataHL
	jr	printMessage
wonGame:
	ld	bc,$0000		; display congratulations
	ld	hl,txtCongrats
	call	addDataHL
printMessage:
	call	printLarge
compScores:
	ld	de,(highScore)	; check high score
	ld	hl,(saferam1+score)
	call	hiscr
	jr	nz,sameHS		; check if high score beaten
	ld	(highScore),hl	; if so, adjust high score
	ld	bc,$0104
	ld	hl,txtNewHS		; and display message
	call	addDataHL
	call	printLarge
sameHS:
	call	bigDelay
	call	bigDelay
	bit	0,(ix+won)		; return to main menu if haven't won game
	jp	z,mainMenu
winSeq:
	bcall(_cleargbuf)		; othrwise, display win sequence
	call	dispFront
	call	delay
	call	delay
	call	dispHalf
	call	dispOff
	call	delay
	call	dispFlash
	call	dispFlash
	call	bigDelay
	call	dispHalf
	call	dispFront
	call	bigDelay
	call	bigDelay
	jp	mainMenu

dispFront:
	ld	de,plotsscreen+12		; display car front
	ld	hl,front
	call	addDataHL
	ld	bc,12*62
	ldir
	call	ionFastCopy
	call	delay
	ret

dispHalf:
	ld	de,plotsscreen+(12*31)+1	; display half-open deltas
	ld	hl,halfLeft
	call	addDataHL
	call	delta
	ld	de,plotsscreen+(12*31)+8
	ld	hl,halfRight
	call	addDataHL
	call	delta
	call	ionFastCopy
	call	delay
	ret

dispFlash:
	ld	de,plotsscreen+(12*31)+1	; flash lights on then off
	ld	hl,lightLeft
	call	addDataHL
	call	delta
	ld	de,plotsscreen+(12*31)+8
	ld	hl,lightRight
	call	addDataHL
	call	delta
	call	ionFastCopy
	call	delay
dispOff:
	ld	de,plotsscreen+(12*31)+1
	ld	hl,openLeft
	call	addDataHL
	call	delta
	ld	de,plotsscreen+(12*31)+8
	ld	hl,openRight
	call	addDataHL
	call	delta
	call	ionFastCopy
	call	delay
	ret

delta:
	ld	a,10		; overlay headlight deltas
deltaLoop:
	ld	bc,3
	ldir
	ex	de,hl
	ld	bc,9
	add	hl,bc
	ex	de,hl
	dec	a
	jr	nz,deltaLoop
	ret

bigDelay:
	call	delay		; big delay (delay * 4)
	call	delay
	call	delay

delay:
	ld	bc,0		; delay
delayLoop:
	dec	bc
	ld	a,b
	or	c
	jr	nz,delayLoop
	ret

resetGame:
	bcall(_clrlcdf)		; display warning message
	ld	hl,txtWarning
	call	addDataHL
	ld	bc,$0001
	call	printLarge
	ld	bc,$0002
	call	printLarge
	ld	bc,$0003
	call	printLarge
	ld	bc,$0405
	call	printLarge
	ld	bc,$0206
	call	printLarge
resetLoop:
	ld	a,$fd
	out	(1),a
	in	a,(1)
	cp	191			; CLEAR
	jp	z,noReset
	ld	a,$bf
	out	(1),a
	in	a,(1)
	cp	127			; DEL
	jr	z,reset
	jr	resetLoop
reset:
	ld	(ix+level),0	; reset game
	ld	a,0
	ld	(highLevel),a
	ld	hl,0
	ld	(highScore),hl
	jp	mainMenu
noReset:
	call	delay
	jp	mainMenu

pause:
	ld	bc,$0503		; display paused
	ld	hl,txtPaused
	call	addDataHL
	call	printLarge
	call	bigDelay
pauseLoop:
	ld	a,$bf
	out	(1),a
	in	a,(1)
	cp	223			; return when 2nd is pressed
	ret	z
	jr	pauseLoop


;---------= Get the bit for a pixel =---------
; input:	a - x coordinate
;		hl - start location	; includes gbuf
; returns:	a - holds bit
;		hl - location + x coordinate/8
;		b=0
;		c=a/8
getbit:	ld	b,$00
	ld	c,a
	and	%00000111
	srl	c
	srl	c
	srl	c
	add	hl,bc
	ld	b,a
	inc	b
	ld	a,%00000001
gblp:	rrca
	djnz	gblp
	ret

;---------= High Score =---------
; Input: de=previous high score
;	hl=current score
; Output: hl=high score
;	z=1 (a=0) if new high score, z=0 (a=1) if not
; Registers destroyed: af, de, hl
hiscr:	push	hl
	xor	a
	sbc	hl,de
	pop	hl
	jr	z,nnhs
	jr	nc,nhs
nnhs:	ex	de,hl
	inc	a
	ret
nhs:	or	a
	ret


;‹€€€€€€€€€€€€ﬂ DRWSPR ﬂ€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€
;⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
;≥ Draw 8xc sprite ˛ a=x, e=y, hl=sprite address (Badja - c=height of sprite) ≥
;¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
DRWSPR:

        push    hl              ; Save sprite address

;€€€€   Calculate the address in graphbuf   €€€€

        ld      hl,0            ; Do y*12
        ld      d,0
        add     hl,de
        add     hl,de
        add     hl,de
        add     hl,hl
        add     hl,hl

        ld      d,0             ; Do x/8
        ld      e,a
        srl     e
        srl     e
        srl     e
        add     hl,de

        ld      de,plotsscreen
        add     hl,de           ; Add address to graphbuf

        ld      b,00000111b     ; Get the remainder of x/8
        and     b
        cp      0               ; Is this sprite aligned to 8*n,y?
        jp      z,ALIGN


;€€€€   Non aligned sprite blit starts here   €€€€

        pop     ix              ; ix->sprite
        ld      d,a             ; d=how many bits to shift each line

        ld      e,c             ; Line loop (Badja - changed 8 to c)
LILOP:  ld      b,(ix+0)        ; Get sprite data

        ld      c,0             ; Shift loop
        push    de
SHLOP:  srl     b
        rr      c
        dec     d
        jp      nz,SHLOP
        pop     de

        ld      a,b             ; Write line to graphbuf
        or      (hl)
        ld      (hl),a
        inc     hl
        ld      a,c
        or      (hl)
        ld      (hl),a

        ld      bc,11           ; Calculate next line address
        add     hl,bc
        inc     ix              ; Inc spritepointer

        dec     e
        jp      nz,LILOP        ; Next line

        jp      DONE1


;€€€€   Aligned sprite blit starts here   €€€€

ALIGN:                          ; Blit an aligned sprite to graphbuf
        pop     de              ; de->sprite
        ld      b,c             ; (Badja - changed 8 to c)
ALOP1:  ld      a,(de)
        or      (hl)            ; xor=erase/blit
        ld      (hl),a
        inc     de
        push    bc
        ld      bc,12
        add     hl,bc
        pop     bc
        djnz    ALOP1

DONE1:
        ret
;‹€€€€€€€€€€€€‹ DRWSPR ‹€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€


addDataDE:
	push	hl
	ld	hl,(saferam1+dataP)
	add	hl,de
	ex	de,hl
	pop	hl
	ret

addDataHL:
	push	bc
	ld	bc,(saferam1+dataP)
	add	hl,bc
	pop	bc
	ret

addDataIX:
	push	bc
	ld	bc,(saferam1+dataP)
	add	ix,bc
	pop	bc
	ret


;******** Data ********

detectString:
	.db	"badjaLTC",0

highScore:
	.dw	0

highLevel:
	.db	0


;******** Data file offsets ********

arrowsLeft	.equ	$0000
arrowsRight	.equ	$0046
trees	.equ	$008c
backgrounds	.equ	$0302
checkpoint	.equ	$085a
congratulations	.equ	$090e
outOfTime	.equ	$0986
ownCar	.equ	$0a46
opCar	.equ	$0a66
block	.equ	$0af2
sparkLeft	.equ	$0afa
sparkRight	.equ	$0b02
numChecks	.equ	$0b0a
extraTimes	.equ	$0b10
track1	.equ	$0b3a
track2	.equ	$0c56
track3	.equ	$0d6a
track4	.equ	$0e50
track5	.equ	$0f60
track6	.equ	$1084
heading	.equ	$1188
silhouette	.equ	$1290
front	.equ	$138c
halfLeft	.equ	$1674
halfRight	.equ	$1692
openLeft	.equ	$16b0
openRight	.equ	$16ce
lightLeft	.equ	$16ec
lightRight	.equ	$170a
txtUrl	.equ	$1728
txtLevel	.equ	$173d
txt1	.equ	$1746
txt2	.equ	$1749
txt3	.equ	$174c
txt4	.equ	$174f
txt5	.equ	$1752
txt6	.equ	$1755
txtReset	.equ	$1758
txtHigh	.equ	$1763
txtScore	.equ	$1768
txtGameOver	.equ	$1770
txtCongrats	.equ	$177a
txtNewHS	.equ	$178b
course1	.equ	$179a
course2	.equ	$17a2
course3	.equ	$17a9
course4	.equ	$17b2
course5	.equ	$17b9
course6	.equ	$17c1
course	.equ	$17c9
txtGetReady	.equ	$17d1
txtPaused	.equ	$17db
txtWarning	.equ	$17e2
snow	.equ	$181d
rainDay	.equ	$1825
rainNight	.equ	$182d

.end
