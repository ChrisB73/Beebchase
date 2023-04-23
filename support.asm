; Game Routines

.newgame
    ; Reset data for new game

    ; Reset lives
    lda #3
    sta lives
    sta gamespeed           ; Game speed can be 3 or 2 - flicker on 2 at max density
    ; Reset score
    ldx #0
    stx score
    stx score+1
    stx score+2
    stx nightmode   ; Force day mode
    stx direction   ; Reset direction flag
    stx lastmove    ; Reset last move counter
    stx oldspeed    ; Set old speed to be stationary at start

    jsr setcoloursdirect    ; Set daytime

    inx                     ; X is 1
    stx level       ; Set start level

    jsr setclouds   ; Create clouds


; Clear storage area
    jsr clearstorage    ; Clear tree storage

    jsr printscore      ; Print scores
    jsr printhiscore

    jsr resetbikes      ; REse bike locations

    jsr printlives      ; Show current lives

    lda #5
    sta density         ; Set tree density 

    ldx #128
    stx gamestatus          ; Negative - new game

    ; Reset bonus sprites
    jsr bonusnew

    rts

.dorand
    ; Generate Random Number
    txa
    pha
    lda rand+1
	tax ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr a; shift to consume zeroes on left...
	lsr a
	lsr a
	sta rand+1 ; now recreate the remaining bits in reverse order... %111
	lsr a
	eor rand+1
	lsr a
	eor rand+1
	eor rand+0 ; recombine with original low byte
	sta rand+1
	; compute seed+0 ($39 = %111001)
	txa ; original high byte
	sta rand+0
	asl a
	eor rand+0
	asl a
	eor rand+0
	asl a
	asl a
	asl a
	eor rand+0
	sta rand+0
    pla
    tax
	rts

.crtcregs
equb &3F ; R0  horizontal total
equb 32 ; R1  horizontal displayed
equb 45 ; R2  horizontal position
equb &24 ; R3  sync width
equb &26 ; R4  vertical total
equb 0 ; R5  vertical total adjust
equb 24 ; R6  vertical displayed
equb &1e ; R7  vertical position
equb &00 ; R8  interlace
equb &7 ; R9  scanlines per row
equb &20 ; R10 cursor start
equb &8 ; R11 cursor end
.crtcscreenstart
equb &0d  ;R12 Screen start hi 
equb &80 ;R13 Screen Start lo

    .clslp1
    ; Clear screen loop - fully unrolled for speed
    sta &1c00,X
    sta &1d00,X
    sta &1e00,X
    sta &1f00,X
    sta &2000,X
    sta &2100,X
    sta &2200,X
    sta &2300,X
    sta &2400,X
    sta &2500,X
    sta &2600,X
    sta &2700,X
    sta &2800,X
    sta &2900,X
    sta &2a00,X
    sta &2b00,X
    sta &2c00,X
    sta &2d00,X
    sta &2e00,X
    sta &2f00,X
    DEX
    bne clslp1
    jmp clearexit

    .clslp2
    ; Clear screen second buffer
    sta &6c00,X
    sta &6d00,X
    sta &6e00,X
    sta &6f00,X
    sta &7000,X
    sta &7100,X
    sta &7200,X
    sta &7300,X
    sta &7400,X
    sta &7500,X
    sta &7600,X
    sta &7700,X
    sta &7800,X
    sta &7900,X
    sta &7a00,X
    sta &7b00,X
    sta &7c00,X
    sta &7d00,X
    sta &7e00,X
    sta &7f00,X
    DEX
    bne clslp2
    jmp clearexit

.plotv
    ; ' Vehicle' plot routine - uses for bonuses, clouds and the moon
    lda bonusx,x
    sec
    sbc #64             ; Check if left onscreen
    bmi exitplotv
    cmp #128-8          ; check of off right
    bcs exitplotv

    and #%11111100      ; Align to bytes
    asl A
    sta plotpos         ; X position

    lda bonusy,X        ; Y position
    clc
    adc screenstart     
    sta plotpos+1       ; Store plot pos high byte

    ldy #3*8-1          ; Plot 3 columns - 12 pixels

    lda #hi(vehiclesprites)
    sta spritepos+1
    lda bonussprite,x   ; Get sprite offset - assumes all sprites in same page
    sta spritepos
.plotvlp
    lda (spritepos),y
    sta (plotpos),y         ; Write sprite to screen
    dey
    lda (spritepos),y
    sta (plotpos),y
    dey                     ; loop unroll
    lda (spritepos),y
    sta (plotpos),y
    dey                     ; loop unroll
    lda (spritepos),y
    sta (plotpos),y
    dey                     ; loop unroll
    bpl plotvlp
.exitplotv
.bikeexit
    rts

.isbikeexploded
    ; Check if bike is exploded - called from "plotbike"
    dey
    lda (bikepos),y     ; Y=1 Duration
    cmp #2              ; 
    bcc bikeexit        ; Exit if movement counter <2
                        ; Means that explosion won't be visible during transition
    ; We have an explosion
    ldy #3
    lda (bikepos),y      ; X position
    sec
    sbc #64             ; Move to screen coordinates
    bmi bikeexit
    lsr A
    lsr A
    tax
    dex                 ; explosion is offset from bile by 1
    ldy #9              ; Fixed y position
    lda #27             ; Fixed sprite number
    bne maskedplot              ; Always taken


.plotbike
    ; Bike plot routine - must be next to masked plot
    ldy #2
    lda (bikepos),Y     ; Status
    bmi isbikeexploded
                        ; A contains direction (0,2,4)
    asl A               ; A = 0 , 4, 8
    sec
    sbc #4              ; A= -4,0,4

    ldx zcount          ; Distance
    clc
    adc bikesizes-10,x  ; Add sprite offset -10 because bike never very clos
    clc
    adc biketype        ; Allow for blue or dithered
    sta temp1           ; Store for later
    iny                 ; Y=3
    lda (bikepos),y      ; X position
    sec
    sbc #64             ; Move to screen coordinates
    bmi bikeexit        ; Not on screen

    lsr a
    lsr a
    tax                 ; x coordinate
    ldy #10             ; Fixed  y pos
    lda temp1           ; Restore sprite number

.maskedplot
    ;Masked sprite plot routine
    ; Position is always row/column aligned
    ;takes X and Y positions in X & Y
    ; Takes sprite number in A
    cpx #31
    bcs exitmaskedplot  ; Exit if at very rigt hand edge

    pha         ; Save sprite number for later

    ;Calculate X position
    txa
    asl A:asl A:asl A       ; Multiply by 8
    sta plotpos             ; X offset

    tya
    clc
    adc screenstart
    sta plotpos+1           ; Y offset

    pla:tax                 ; Move sprite number to X
    ; Get sprite & mask location
    
    lda spritelo,x
    sta spritepos
    lda spritehi,X
    sta spritepos+1

    lda spritemlo,X
    sta maskpos
    lda spritemhi,X
    sta maskpos+1

    lda spritewidth,X
    sta temp1                     ; Store for loop
    sta temp2
    inc temp2                     ; 1 bigger for row addition              
    lda spriterows,X
    tax                         ; Row count
.maskedplotlp1
    ldy temp1                   ; Get width
.maskedplotlp2
    lda (plotpos),y             ; Get screen value
    and (maskpos),Y             ; Mask value
    ora (spritepos),Y           ; Add sprite
    sta (plotpos),y             ; Store in screen
    dey
    lda (plotpos),y
    and (maskpos),Y
    ora (spritepos),Y
    sta (plotpos),y
    dey
    lda (plotpos),y
    and (maskpos),Y
    ora (spritepos),Y
    sta (plotpos),y
    dey
    lda (plotpos),y
    and (maskpos),Y
    ora (spritepos),Y
    sta (plotpos),y
    dey                         ; Small unroll
    bpl maskedplotlp2
    inc plotpos+1               ; Update screen row
    clc
    lda spritepos               ; Update sprite pointer
    adc temp2                   ; Add sprite width
    sta spritepos
    lda spritepos+1
    adc #0
    sta spritepos+1               ; Update sprite pointer

    lda maskpos                 ; Update mask pointer
    adc temp2                   ; Carry will be clear from previous add
    sta maskpos
    lda maskpos+1
    ADD16 maskpos+1               ; Update mask pos

    dex
    bne maskedplotlp1           ; check row count
.exitmaskedplot
    rts                         ; All done

.updatebike
    ; Update bike position
    ; Takes A low byte of bike data structure

    sta bikepos         ; Store low byte
    ldy #0
    lda (bikepos),y     ; z position
    lsr a
    lsr a
    tax                 ; Move to screen coordinates
    ; Update z position
    lda speed 
    cmp #4
    beq bikemovecloser  ; If player at maximum speed make bikes get nearer to player
    cmp #3
    beq bikeskipzmovement ; If nearly max speed don't make bike move away
; Move away
    lda (bikepos),Y         ; Get Z location
    bmi bikeskipzmovement   ; Negative = exploded
    clc
    adc #1
    bpl bikezsave           ; Always taken

.bikemovecloser
    lda (bikepos),y
    cmp #10*4+1             ; Check if bike is already close enough
    bcc bikeskipzmovement   ; Skip if so
    sec
    sbc #1                  ; Update position

.bikezsave
    sta (bikepos),Y         ; Store Z position

.bikeskipzmovement
    lda (bikepos),Y         ; Get Z pos
    cmp #11*4               ; Check if in range
    bcs bikeskipsaverange   ; Skip if to far away
    sta rangeflag           ; Set in range flag
.bikeskipsaverange

    iny                 ; Y = 1
    lda (bikepos),Y     ; Movement counter
    beq bikechangemovement ; If zero then choose new movement
    sec                 ; Update counter if not
    sbc #1
    sta (bikepos),Y     ; Decrement counter 
    bpl bikemove        ; Now move on to update position 

.bikechangemovement
    iny
    lda (bikepos),Y     ; Status
    bmi bikenoselfmovement    ; Negative then exploded so finish

    jsr dorand                  ; Need a random number
    iny                         ; Y=3
    lda (bikepos),Y             ; X position
    ; Force movement towards centre
    cmp #128+48
    bcs bikeforceleft
    cmp #128-48
    bcs bikenoforce
    ;Force bike right
    lda rand
    and #%10            ; Result is 2 or 0
    clc
    adc #2              ; Final value is 2 or 4
    bpl bikeforceend 

.bikeforceleft
    lda rand
    and #%10            ; Gives 0 or 2
    bpl bikeforceend

.bikenoforce
    lda rand
    lsr a               ; Move bottom bit into carry        
    and #1              ; Value is 0 or 1
    bcc bikeskipshift
    asl A               ; Valus is 0 or 2
.bikeskipshift          
    asl A               ; Value is 0,2 or 4

.bikeforceend
    dey                 ; Y = 2
    sta (bikepos),Y     ; Store movement type
    lda rand
    lsr A
    lsr A               ; remove bits used in direction 
    and #7              ; A = 0 to 7
    sta temp1           ; Store for later

    lda #11
    sec
    sbc level           ; A is value from 4-10  
    lsr A               ; a = 2-5    - Bikes will move more erattically on later levels

    clc
    adc temp1           ; add to random value
    dey
    sta (bikepos),Y     ; Movement duration

.bikemove
    ldy #2
    lda (bikepos),y         ; Status
    bmi bikenoselfmovement  ; exploded so skip self movement

    sec
    sbc #2                  ; force movement to be -2,0,2

.bikedomove
    clc
    iny
    adc (bikepos),Y         ; Add movement direction
    sta (bikepos),Y

.bikenoselfmovement 
    ; Update positions from player movement
    ldy #3
    lda (bikepos),Y         ; X position
    clc
    adc direction           ; Assume direction set as per tree movement
    cmp #20
    bcs bikenotoffleft      ; Skip if bike too far to left
    lda #20
.bikenotoffleft
    cmp #256-20
    bcc bikenotoffright     ; Skip if bike to far to right
    lda #256-20
.bikenotoffright
    sta (bikepos),Y         ; Store new value

;Check if bike has been hit
    ldy #2
    lda (bikepos),Y             ; Status
    bmi finishupdatebike        ; skip if negative - can't hit and already hit bike.
    ldy #0
    lda (bikepos),y             ; Z position
    lsr A
    lsr a                       ; Divide by 4 to make same coords as bolt
    cmp #10                     
    bne finishupdatebike        ; Not in right place to be hit
    cmp boltz
    bne finishupdatebike        ; not hit
    
    ldy #3
    lda (bikepos),Y             ; Z position
    lsr A
    lsr A
    sta temp1                   ; Move to screen space
    lda boltx
    lsr A
    lsr A                       ; Move to screen space
    cmp temp1                   ; Is bike + bolt is same place?
    bne finishupdatebike        ; Not hit

    dey                         ; Y = 2
    lda #lo(-1)
    sta (bikepos),Y             ; Mark bike as destroyd
    sta boltz                   ; Mark bolt as inactive
    dey                         ; Y=1
    lda #10
    sta (bikepos),Y             ; Explosion counter

    ; Explosion sound
    lda #&7
    ldx #lo(explosionsound)
    ldy #hi(explosionsound)
    jsr osword

    lda #&10
    jmp addscore                ; Add score and exit

.finishupdatebike
    rts

.updatebolt
    ;Update bolt position
    ldx boltz
    bmi finishupdatebike        ; If negative not in flight
    jsr checkbolttree
    inx
    cpx #16
    bcc boltskipdouble
    inx
.boltskipdouble
    cpx #33
    bcc skipboltzupdate
    ldx #128
.skipboltzupdate
    stx boltz

    ; Move bolt left/right with movement
    lda boltx
    sec
    sbc direction
    sta boltx

    ;Falls through to check tree again. 

.checkbolttree
    lda boltx
    ; Check if bolt has hit a tree
    lsr A
    lsr A
    sta temp1               ; Get bolt position and store

    lda treex,X             ; Get tree position
    lsr A
    lsr A
    cmp temp1               ; Is it the same?
    beq unsetbolt           ; if so stop bolt
    tay
    lda treew,x
    cmp #3                  ; Do we have a large tree?
    bcc nounsetbolt   ; TRee width <2
    dey                     ; Decrement postion
    cpy temp1               ; Have bolt hit tree?
    bne nounsetbolt         ; Skip if we not
.unsetbolt
    ldx #128                ; Mark bolt as inactive
    stx boltz
.nounsetbolt
    rts

.resetbikes
    ;Reset bike and speed for start of level
    lda #2
    sta bike1+2
    sta bike2+2             ; Set status as straight
    
    lda #40
    sta bike1+3
    lda #256-40
    sta bike2+3         ; Write starting X positions    


    lda #120
    sta bike1
    sta bike2           ; Write Z positions as distant

    lda #0
    sta speed           ; Write player speed as zero

    rts

.setnight
    jsr silence0        ; Turn off engine noise
    ldx #1
.nightloop
    jsr setdaynightcolours  ; Set colours
    inx
    cpx #5              ; Have we done all colours
    bne nightloop       ; Loop if not

    ; Set vehicle sprites as moon
    jsr dorand
    lda rand            ; Moon X position
    sta bonusx+1
    sta bonusx+2
    sta bonusx+3

    jsr dorand
    lda rand

    and #3              ; Height 0-3
    tax                 
    inx                 ; Height 1-4

    stx bonusy+1        ; Store height
    inx
    stx bonusy+2
    inx
    stx bonusy+3

    ; Set moon sprites
    lda #lo(vehiclesprites+4*3*8)
    sta bonussprite+1
    lda #lo(vehiclesprites+5*3*8)
    sta bonussprite+2
    lda #lo(vehiclesprites+6*3*8)
    sta bonussprite+3

    rts

.silence0
    ; Silence channel 0
    lda #21
    ldx #4
    jmp osbyte

.setday
    ; Set day values
    jsr silence0        ; Silence channel 0 
   ldx #3               ; Set counter for colours
.dayloop
    jsr setdaynightcolours  ; Set colours
    dex
    bpl dayloop
    jsr setclouds       ; Set the clouds
    rts


.setdaynightcolours
    lda #0
    sta framecount      ; Set framecount for timer

    lda #35             ; Wait until 35 ticks
.daynightwaitlp
    cmp framecount
    bcs daynightwaitlp
 
.setcoloursdirect       ; Entry to set colours without delay
    lda daynightcolours,x ; Set colours
    sta palettetop
    ora #&10
    sta palettetop+1
    ora #&40
    sta palettetop+3
    eor #&10
    sta palettetop+2
    txa
    pha

    lda #7
    ldx #lo(daysound2)
    ldy #hi(daysound2)
    jsr osword          ; Make sound

    lda #7
    ldx #lo(daysound3)
    ldy #hi(daysound3)
    jsr osword          ; Make sound

    pla
    tax

    rts

.daynightcolours
equb 1,2,6,3,7      ; Cyan,magenta,red,blue,black

; equb &01,&11,&41,&51        ; 0 > Sky colour

.textplot
    ;Routine to plot "text" - just sprites
    ; Takes X as text to plot
    lda textlo,X        ; Get sournce address
    sta spritepos
    lda texthi,x
    sta spritepos+1
    lda textlength,x    ; Length of text to plot
    tay
    lda textcolumn,X    ; Column to plot
    sta plotpos
    lda textrow,x       ; Screen row to plot
    clc
    adc screenstart     ; Add screen start
    sta plotpos+1
.textloop
    lda (spritepos),y   ; Read data
    sta (plotpos),Y     ; Plot to screen
    dey
    bne textloop        ; Loop until done
    rts

.printlevel
    ; Routine to print text at start of level
    ldx #4
    jsr textplot                ; "Sector" 
    ;PRint secor numbers
    lda #8*11+Sector_size       
    sta plotpos                 ; set x pos 
    lda level
    asl A:asl a:asl a:asl A ; Multiply by 16
    clc
    adc #lo(numbers)        ; Get offset to number
    sta spritepos
    lda #0
    adc #hi(numbers)
    sta spritepos+1         ;
    ldy #15                 ;Copy 16 bytes
.sectnumlp
    lda (spritepos),Y       ; Get from sprite
    sta (plotpos),Y         ; Store to screen
    dey                 
    bpl sectnumlp           ;loop No need to unroll as not time sensitive

    lda gamespeed           
    lsr a                   ; Check if bottom bit set
    bcs endprintlevel       ; Skip "super speed" if set

    ldx #5
    jsr textplot            ; "Super Speed"

.endprintlevel
    rts

.gameoverlogic
    ldx #6
    jsr textplot            ; Print game over message
    inx
    jsr textplot            ; Print game over message
    ; Check if this is a high score.
    lda hiscore
    cmp score
    bne scorecmpexit
    lda hiscore+1
    cmp score+1
    bne scorecmpexit
    lda hiscore+2
    cmp score+2
    bne scorecmpexit
    lda hiscore+2
    cmp score+2
.scorecmpexit
    bcs noscoreupdate   ; hiscore greater so skip update
    ; Update high score
    lda score
    sta hiscore
    lda score+1
    sta hiscore+1
    lda score+2
    sta hiscore+2
    lda score+3
    sta hiscore+3

.noscoreupdate
    ; Introduce a pause (255 frames)
    ldx #1
    stx framecount
    dex
.gopause
    cpx framecount
    bne gopause

    ;Update to be on the "right" screen
    lda screenstart
    EOR #%01110000
    sta screenstart

    jmp newgameloop         ; Back to new game screen

.hittree
        ;Check if player has hit a tree
    lda treex               ; Get tree closest to player
    cmp #128-8              ; Check if tree is in middle of screen
    bcc nothittree          
    cmp #128+8
    bcs nothittree          ; Skip if not

    ; Play "dead" sound

    jsr deadsound

    ldy #150                ; Set number of colour changes
    lda #0
    sta framecount          
.treecolourlp               ; Set tree color to random colour
    jsr dorand
    lda rand
    and #7
    ora #&20                ; Write tree colours to base palette
    sta palettetop+4
    ora #&10
    sta palettetop+1+4
    ora #&40
    sta palettetop+3+4
    eor #&10
    sta palettetop+2+4

    lda framecount
.hittreewait
    cmp framecount
    beq hittreewait         ; Wait for vsync

    dey
    bne treecolourlp        ; Loop
    
    ; Reset tree trunk colours to Red

    lda #&26
    sta palettetop+4
    lda #&36
    sta palettetop+1+4
    lda #&66    
    sta palettetop+3+4
    lda #&76
    sta palettetop+2+4

    ;Decrement lives
    dec lives
    bne livesnotzero    ; Check if game ver
    lda #1
    sta gamestatus      ; Store game over status
.livesnotzero
    jsr clearstorage    ; Clear tree locations
    jsr printlives      ; Print new lives vales

    lda #0              ; Reset speed
    sta speed
                        ; Reset bike locations to horizon
    ldx #120
    lda bike1+2         ; Status for bike 1
    bmi skipb1reset     ; Negative = destroyed - so skip
    lda #48
    sta bike1+3
    stx bike1
.skipb1reset
    lda bike2+2         ; Status for bike 2
    bmi skipb2reset     ; Negative = destroyed
    stx bike2           ; Write Z positions as distant
    lda #256-48
    sta bike2+3
.skipb2reset

.nothittree
rts

.clearstorage
    ; Clear tree storage
    lda #0
    ldy #&ff
    sty boltz           ; Bolt negative - not plotted
.nglp
    sta treex-1,y
    dey
    bne nglp
    rts

.deadsound
    lda #7
    ldx #lo(playerdie0)
    ldy #hi(playerdie0)
    jsr osword              ; Play sound

    lda #7
    ldx #lo(playerdie1)
    ldy #hi(playerdie1)
    jmp osword              ; Play sound


.updatebonus
    ; Chopper/tank update routine
    ldx bonusstatus
    bmi bonusprocessexplosion   ; Currently exploded
    ldy bonustimer          ; Get timer
    bne bonusdotimer
    ; Timer is zero so chopper/tank onscreen and X as sprite number
    lda bonusx
    clc
    adc #2          ; Move right
    adc direction   ; Account for player movement
    cmp #128+64     ; Are we off screen?
    bcs bonusnew    ; Jump to create new bonus
    sta bonusx
 
    lda bonusstatus ; Get type of vehicle
    beq bonusskipheight       ; Skip height for tank 
    ; Process height
    ldx bonusy
    inc choppercount    ; Count is independent of screen position
    lda choppercount
    and #1
    bne bonusskipheight ; Change every other moeement
    lda choppercount
    cmp #&68                 ; Right hand side of the screen - going up
    bcc bonusnotright
    cpx #5
    bcc storeheight         ; IS bonus below 5?
    dex                     ; If so decrement height
    bpl storeheight         ; Always taken

.bonusnotright
    cmp #128-32-20          ; Left side of screen - before ging down
    bcc bonusskipheight         ; Too far to the left.
    cpx #10                 ; Minimum height
    bcs storeheight         ; Skip if minimum
    inx    

.storeheight
    stx bonusy              ; Store heght value

.bonusskipheight
    ; Check if hit
    lda bonusy
    cmp #10
    bne finishupdatebonus       ; Skip if not at ground level
    lda boltz
    cmp #&1f                    ; Compare if bolt at right distance
    bne finishupdatebonus
    lda boltx                   ; Get bolt X position
    clc
    adc #4                      ; Move slightly to right to ensre centre hit
    cmp bonusx
    bcc finishupdatebonus       ; boltx+4<bonusx
    sec
    sbc #8                      ; Move to left to ensure centre hit
    cmp bonusx
    bcs finishupdatebonus        ; boltx-4>bonusx
    ; Must have hit
    ldx #8
    stx bonustimer              ; Explosion duration

    ; Explosion sound
    lda #&7
    ldx #lo(explosionsound)
    ldy #hi(explosionsound)
    jsr osword                  ; Play sound

    ; Add score
    lda bonusstatus
    asl A
    asl A
    ora bonusstatus             ; Multiply by 5
    ora #&20                    ; Bonus is either &25 for chopper or &20 for tank

    ldx #128                    ; Exploded status
    stx bonusstatus

    ldx #lo(vehiclesprites+3*8*2) ; Explosion sprite
    stx bonussprite             ; Save for plot routine

    jmp addscore                ; Add score and exit

.finishupdatebonus
    rts

.bonusprocessexplosion
    ; Update the bonus explosion
    dec bonustimer         ; Decrement timer 
    beq bonusnew                ; If finished create new sprite
    rts

.bonusdotimer
    ; Update timer to next bonus
    dey
    sty bonustimer          ; Store result
    bne bonusfinishtimer    ; If not zero
    lda #64
    sta choppercount        ; Store chopper move position
    sta bonusx              ; put sprite onscreen
.bonusfinishtimer
    rts

.bonusnew
    ; Create new bonus sprite
    jsr dorand
    lda rand
    and #1              ; Bonus status is 0 ot 1
    sta bonusstatus     ; Store which vehicle
    tax                 ; store offset in X
    lda rand            
    lsr A               ; Get remainder of random byte (0-127)
    clc
    adc #80             ; Add 128
    sta bonustimer      ; Store 128-255 in bonustimer
    ; Save positions
    lda #0
    sta bonusx          
    lda bonusheights,x  ; X is bonus type
    sta bonusy              ; Store height of sprite

    lda vehiclelo,x
    sta bonussprite         ; Store which sprite we are plotting

    rts

.bonusheights
; Start height for bonus sprites
equb 10
equb 4

.setclouds
    ; Set clouds in sky
    ldx #3              ; 3 clouds
.cloudloop
    jsr dorand
    lda rand            ; Choose random x position
    sta bonusx,x        ; Store x position
    jsr dorand
    lda rand
    and #7
    sta bonusy,x        ; Store y pos (0-7)
    lda #lo(vehiclesprites+3*8*3)
    sta bonussprite,x   ; Set as type "cloud"
    dex
    bne cloudloop
    rts

.enginesound
    ; Set engine sound
    ldy speed
    lda enginepitches,Y ; Get pirch
    sta enginechannel1+4    ; Store in sound block

    lda #7
    ldx #lo(enginechannel0)
    ldy #hi(enginechannel0)
    jsr osword              ; Make sound

    lda #7
    ldx #lo(enginechannel1)
    ldy #hi(enginechannel1)
    jmp osword              ; Make sound
