;Beebchase
; Game heavily inspired by/based on Deathchase by Mervyn Estcourt
; BBC Model B/B+/Master

    include "constants.asm"        ; Constants and uninitialised data

    include "zpdata.asm"           ; Zero Page Data

org &3000-3
    jmp start               ; Known position for game entry to allow for code decompressions
guard &6c00
incbin "scoreboard.bin"     ; Scoreboard needs to be at &3000 to allow for screen wrap
.spritestart
incbin "sprites.bin"        ; Sprites are here so they don't go over a page

include "multtables.asm"   ; Need to be next to sprites for alignment

include "irq.asm"          ; IRQ Routines

include "support.asm"      ; Game routines

include "numbers.asm"      ; Number plot routines

.start
    ; Assumes we have started in mode 1 for the wrap setup
include "init.asm"         ; initial setup - only run once 

.newgameloop                ; Main game loop
    jsr newgame             ; Reset game variables

; Reset tree count
    lda #0
    sta newtreecount

.mainloop

    jsr hittree             ; Check if player has hit a tree

    ; Check movement speed
    lda speed               ; Current speed
    clc
    adc speedcount          ; Speed count
    sta speedcount
    cmp #5                  ; If >=5 then update tree positions 
    bcs doposupdate
    jmp skipposupdate       ; Skip if not
.doposupdate
    sec
    sbc #5
    sta speedcount          ; Subtract 5 for even
    dec newtreecount            ; Update tree count as we have moved

    lda speed
    cmp #4
    bne skipaddscore        ; ONly add to score if at full speed

    sed                         ; Increase score by 1 for every move - bcd
    lda score+2
    clc
    adc #1
    sta score+2
    lda score+1
    adc #0
    sta score+1
    lda score
    adc #0
    sta score
    cld 
.skipaddscore

; Move the trees
    ldx #0
    inx
.persploop                  ; Move the tree values down 1 position in arrays
    lda treelr,X
    sta treelr-1,X
    lda treetr,X
    sta treetr-1,x
    lda treexlh,X
    sta treexlh-1,X
    lda treexth,X
    sta treexth-1,x

    lda treex,X         ; Get tree x position
    sta newtreevalue    ; Assume not moved
    beq skiptreeupdate  ; If zero skip update - tree not active                  
    
    bmi treetoright     ; Top bit set - tre is right hand side of screen
; Tree is on left
    lda #128
    sec
    sbc newtreevalue    ; 128-I%
    cmp perspective,X
    bcc skiptreeupdate  ; Less then perspective value so skip move 
    lda treew,X         ; Use tree width/2 as movement amount
    lsr A               
    dec newtreevalue    
    eor #&ff            
    sec
    adc newtreevalue    ; Reverse subtract (I%-=treew%(P%)/2+1)
    jmp finishtreeupdate

.treetoright
    sec
    sbc #128
    cmp perspective,x
    bcc skiptreeupdate  ; Less so skip tree update
    lda treew,X
    lsr A
    inc newtreevalue
    clc
    adc newtreevalue    ; Add to tree position

.finishtreeupdate
    clc
    adc direction       ; Add player direction movement - allows trees to move
    sta newtreevalue

.skiptreeupdate
    lda #0
    sta treex,x         ; clear current value

    lda newtreevalue
    clc
    adc direction       
    cmp #16
    bcc treeleaving
    cmp #240                ;IF I% <16 or I%>240 then I%=0
    bcc treenotleaving
.treeleaving
    lda #0

.treenotleaving    
    sta treex-1,x       ; Write new value

    inx
    cpx #32
    bne persploop

.skipposupdate
    ; Now check bike/chopper/bullet update positions.

    lda #0
    sta rangeflag               ; Assume not in range

    lda gamestatus
    bmi gamenotstarted          ; Skip updates if just starting level

    lda #lo(bike1)
    jsr updatebike              ; Update bike 1

    lda #lo(bike2)
    jsr updatebike              ; Update bike 2

    jsr updatebolt              ; Update bolt position

    jsr updatebonus             ; Update tank/chopper

    ldx #3
.movebonus                      ; Move chopper/tank left/right with player movement
    lda bonusx,X
    clc
    adc direction
    sta bonusx,X
    dex
    bne movebonus

.gamenotstarted

; Wait for frame and swap buffers
    ldx gamespeed
.framewait
    cpx framecount
    bcs framewait

    lda #0
    sta framecount
    ; Set screen buffers

    lda #23
    jsr oswrch
    lda #0
    jsr oswrch
    lda #12
    jsr oswrch
    lda crtcscreenstart
    eor #&0E
    sta crtcscreenstart         ; Update screen start
    jsr oswrch
    lda #0
    jsr oswrch
    jsr oswrch
    jsr oswrch
    jsr oswrch
    jsr oswrch
    jsr oswrch


;Check if we are on a new level
;Done here in code because screen being displayed and plotted to is same.

    lda gamestatus
    beq gamerunning         ; If status = 0 then running game
    bmi newgameentry        ; If negative then new game before moving

    ; Else game over status
    jmp gameoverlogic

.gamerunning                ; Check if both bikes have been destroyed
    lda bike1+2
    bpl nonewlevel
    lda bike1+1
    bne nonewlevel
    lda bike2+2
    bpl nonewlevel
    lda bike2+1
    bne nonewlevel

    lda nightmode
    eor #1
    sta nightmode           ; Change day/night
    bne changetonight
; We have a new level 
    ldx level
    inx
    cpx #7
    bne nosectorwrap        ; Check if we have reached level 6
    lda gamespeed
    eor #1
    sta gamespeed           ; Update speed
    ldx #1

.nosectorwrap
    stx level
    lda #6
    sec
    sbc level
    sta density             ; Density = 6-level

;Print day message
.newgameentry
    ldx #0
    jsr textplot
    inx
    jsr textplot
    jsr printlevel
    lda gamestatus      ; If negative don't do the day setting
    bmi skipsetday
    jsr setday              ; Set day colours
.skipsetday
    jmp finishchangelevel

.changetonight
; Print night message
    ldx #2
    jsr textplot
    inx
    jsr textplot
    jsr printlevel
    jsr setnight            ; Set night colours

.finishchangelevel
    jsr resetbikes
.nonewlevel

    lda screenstart
    EOR #%01110000
    sta screenstart         ; Update screen plot location

    ; Check keys
    ; Keys stored at &88 to &8c 

    lda #5                  ; 6 keys to check
    sta temp1

.keyreadloop
    ldx temp1
    lda &88,X
    tax             ; Move key to be detected to X
    lda #121
    jsr osbyte      ; check if key pressed
    ;if x<0 pressed so move neg flag into keyspressed
    txa
    asl A           ; Move top bit to carry
    rol keyspressed ; Move carry to keyspressed
    dec temp1
    bpl keyreadloop


    lda #0
    sta direction   ; Reset direction flag

    lsr keyspressed
    bcc notfire
    ;Fire
    lda speed
    cmp #4
    bne notfire     ; Don't fire if not at max speed
    lda boltz       ; If bolt in flight don't fore new one
    bpl notfire

    lda #0
    sta boltz       ;Just in front of bike 
    lda #127
    sta boltx       ; entre of the screeen

    ; Fire sound
    tya
    pha             ; Save y
    ldx #lo(shotsound)
    ldy #hi(shotsound)
    lda #&7
    jsr osword      ; Play sound
    pla
    tay             ; Restore y

.notfire
    lsr keyspressed
    bcc notleft     ; Skip if not left
    ldy #2
    sty direction   ; Set direction flag

.notleft
    lsr keyspressed
    bcc notright    ; Skip if not right
    ldy #lo(-2)
    sty direction   ; Set direction flag.

.notright
    ldy speed           ; Get speed for up/down adjustment

    ldx lastmove        ; Get last move couunter
    beq updownallowed   ; If zero then we are allowed to change speed/sound (prevents to faster repeat on key)
    dex
    stx lastmove        ; Decrement and sae
    bpl notsound        ; Always taken

.updownallowed

    lsr keyspressed     
    bcc notup           ; Skip if not up
    lda #1              ; Set last move timer
    sta lastmove

    lda #0              ; Set the game status as "playing". Allows move from "newgame"
    sta gamestatus
    cpy #4              ; Don't allow speed to increase beyond 4
    beq notdown
    iny                 ; Increase speed

.notup
    lsr keyspressed
    bcc notdown         ; Skip if not down
    lda #1              ; Set last move timer
    sta lastmove
    cpy #0              ; Don't allow speed to reduce below 0
    beq notdown
    dey                 ; Decrement speed

.notdown
    sty speed           ; Save speed value
    cpy oldspeed        ; Compare if this has changed

    beq nonewenginesound    ; If not skip engine sound change
    sty oldspeed        ; Save current speed as old speed

    jsr enginesound     ; Make engine sound

.nonewenginesound

    lsr keyspressed     ; Check for sound on/off
    bcc notsound
    ; Sound on/off pressed
    lda #2              ; Set last move timer to prevent key bounce
    sta lastmove

    lda soundstatus     ; Invert sound status
    eor #&ff
    sta soundstatus

    tax
    ldy #0
    lda #210
    jsr osbyte          ; Osbyte 210 sets sound supression status

    jsr enginesound     ; MAke a "new" sound to cancel the current sound

.notsound    

; Clear screen

    ldx #0
    txa
    ldy #&6c
    cpy screenstart     ; Choose screen clear loop based on screen start
    bne clear2jmp
    jmp clslp2
.clear2jmp
    jmp clslp1

.clearexit

; Plot background/bonus sprites

    ldx #3                  ; plot sprites 4-0
.bgspriteloop
    jsr plotv               ; "Vehicle" plot
    dex
    bpl bgspriteloop        ; Loop until x=-1

; Plot Range Flasher - This is an awkward position 2 pixels on one line and 6 on next
    ldy #0                  
    lda #(256-3*8+6)        ; Top of range block
    sta plotpos
    lda #&30                ; Always the same place because of screen wrap
    sta plotpos+1

    lda rangeflag           ; Check range flag
    bne dorangeflash        ; Branch if in range

    lda #lo(notinrangesprite)
    sta spritepos
    lda #hi(notinrangesprite)
    sta spritepos+1         ; Selet not in range sprite

; Plot blank range
.rangeblanklp1
    lda (spritepos),Y       ; Basic load/store
    sta (plotpos),Y         ;
    iny
    cpy #2                  ; Position 2 for new line
    beq rangeblanknwline    ; Do new line
    cpy #10                 ; position 10 (8+2) for new line
    bne rangeblanknonewline
.rangeblanknwline
    inc plotpos+1           ; new line
    lda plotpos             
    sec
    sbc #8                  ; dcrement position to allow Y to increase 
    sta plotpos

.rangeblanknonewline        
    cpy #8                  ; 8 is end of sprite column
    beq rangeblanknewblock
    cpy #16                 ; 16 is enf of sprite
    bne rangeblanklp1       ; loop
    beq rangeend            ; Exit range plot
.rangeblanknewblock
    lda #(256-3*8+6)        ; Top of range block next row
    sta plotpos
    dec plotpos+1           ; Move back up to previous line
    jmp rangeblanklp1

.dorangeflash
; Plot in range - Same as above routine but with eor added. 

    lda #lo(inrangesprite)  ; Get in range sprite - this one is drawn to be eored to allow flash
    sta spritepos
    lda #hi(inrangesprite)
    sta spritepos+1

.rangelp1
    lda (plotpos),Y
    eor (spritepos),Y
    sta (plotpos),Y         ; Eor the sprite with the screen
    iny
    cpy #2
    beq rangenwline         ; As above perform the 2 top lines
    cpy #10
    bne rangenonewline
.rangenwline
    inc plotpos+1
    lda plotpos
    sec
    sbc #8
    sta plotpos

.rangenonewline
    cpy #8
    beq rangenewblock
    cpy #16
    bne rangelp1
    beq rangeend
.rangenewblock
    lda #(256-3*8+6)        ; Top of range block next row
    sta plotpos
    dec plotpos+1
    jmp rangelp1


.rangeend

; Plot trees

    ldx #31                 ; Start at the back row
.plottreeloop

    stx zcount              ; Save X in case we have a sprite plot
    lda treex,X             ; Get tree x position
    bne dotreeplot          ; If not zero then tree is active
    jmp skiptreeplot

.dotreeplot
; Plot tree
    sec
    sbc #64                 ; Tree position is offset 64
    bpl dotreeplot2        ; > 64 < 128+64
    jmp skiptreeplot
.dotreeplot2
    and #%11111100          ; Remove bottom 2 bits.
    asl A                   ; *2 for screen loc
    sta treeplotloc         ; Bottom half of tree loc

    lda treeh,X             ; store trunk height
    sta plotheight          

; Find bottom
    lda treew,X
    cmp #3                  ; Skip thin trunks
    bcs processbottom       ; Do bottom of tree
    lda treey,X
    bne treeonscreen        ; Always taken

.processbottom
    lda treey,x             ; Get tree y position
    sta bottomflag          ; Set bottom flag as non zero
    bpl treeonscreen        ; If top bit not set then we can see the bottom of the tree
    ldy #0
    sty bottomflag          ; Set bottom flag as zero
    and #%01111111          ; Remove top bit
.treeonscreen
    clc
    adc screenstart         ; Add screen start

    sta treeplotloc+1       ; Store tree plot position

; Find height
    lda treeh,x
    sec
    sbc treexth,x       ; Add extra trunk height (subtracting moves closer to zero - the top of the screen)
    bpl trunknotofftop  ; not negative
    lda #0              ; Set height as zero
.trunknotofftop
    clc
    adc screenstart            ; Top of screen -
    sta treeplottop     ; Store tree top

; Find leaf height
    lda treelh,x        ;Get leaf height
    sec
    sbc treexlh,x       ; Add extra trunk height
    bpl leafnotofftop   ; Not negative
    lda #0              ; Set leaf height as zero
.leafnotofftop
    clc
    adc screenstart            ; Top of screen -
    sta treeplotltop    ; Store leaf plot top

    ; Find width
    lda treew,X         ; Get tree width
    tay                 ; Move offset
    ; Store trunk sprite location                      
    lda widthtreetablelo-1,y
    sta treeplottrunksprite
    sta workingtreeplottrunksprite       ; Store original value for addition
    lda widthtreetablehi-1,y
    sta treeplottrunksprite+1
    lda treewidthtable-1,y              ; Get leaf bytes to plot
    sta trunkwidth
    lda treemulttablelookup-1,y         ; Get the multipication table
    sta treemulttable                   ; Modify code for lookup
    lda treetr,x
    sta trandomstore                    ; Random seed for tree

    ; Store leaf sprite                      
    lda widthleaftablelo-1,y
    sta treeplotleafsprite
    sta workingtreeplotleafsprite       ; Store original value for addition
    lda widthleaftablehi-1,y
    sta treeplotleafsprite+1
    lda leafwidthtable-1,y              ; Get leaf bytes to plot
    sta leafwidth
    lda leafmulttablelookup-1,y
    sta leafmulttable                   ; Modify code for lookup
    lda treelr,x
    sta lrandomstore                    ; Random seed for leaf store


    ;All tree parameters have now been read and stored in the plot data.

;trunkplot

    ldy #8                          ; Initial trunk postion offset
    lda treew,X
    cmp #4
    bcs skipsettrunzsubzero         ; If <4 then set as zero
    ldy #0                          ; Set trunk pisitio
.skipsettrunzsubzero
    sty trunksub                    ; Store trunk sub

    ldy #0                          ; Set leaf pos to zero
    cmp #3                          ; Compare tree width to 3
    bcc nottreeleftedge             ; IF <3 Exit check

    ldy #8                          ; Reset value for leaves


.checkleftedge
    ; Are we at the left edge
    lda treeplotloc                 ; Tree screen x position
    cmp #16
    bcs nottreeleftedge             ; If pos >=16 exit as not close to edge
    cmp #8
    bne treeiszero                  ; If ne to 8
    lda treew,x                     ; Tree is in position 1
    cmp #3                          
    beq nottreeleftedge             ; Width is 3 so can ignore                            
    ldy #0                          ; Width is 4 or 5 and pos = 1 or 0
    lda leafwidth                   ; Dont sub + add offset to sprite
    sec:sbc #8
    sta leafwidth                   ; reduce leaf width
    lda workingtreeplotleafsprite   
    clc:adc #8
    sta workingtreeplotleafsprite   ; Increase leaf sprite offset
    ; Now deal with being in position zero
    lda treeplotloc
    bne nottreeleftedge             ; Skip is we are not on left edge
.treeiszero
    sta trunksub                    ; Set trunk sub to zero
    tay                             ; Set leaf offset to zero for 3 case
    lda leafwidth                   
    sec:sbc #8
    sta leafwidth                   ; Reduce leaf width again
    lda workingtreeplotleafsprite   
    clc:adc #8
    sta workingtreeplotleafsprite   ; Increase leaf sprite offset again
    lda treew,x                         ; Tree is in position 1
    cmp #3                          
    beq nottreeleftedge                            ; Width is 3 so can ignore                            
    lda trunkwidth
    sec:sbc #8
    sta trunkwidth                  ; Reduce trunk width
    lda workingtreeplottrunksprite
    clc:adc #8
    sta workingtreeplottrunksprite  ; Inrease trunk sprite offseet

.nottreeleftedge
    sty leafsub

    lda treew,X
    cmp #3
    bcc nottreerightedge    ; <3 = skip - no calcs to be done    

    ; Check right hand edge
    lda treeplotloc
    cmp #256-16
    bcc nottreerightedge ;< 256-16 not off right edge
    beq thinrighttree

    ;width is 3 or more and on right edge

    lda leafwidth
    sec:sbc#8
    sta leafwidth          ; Reduce leaf width

    lda treew,x
    cmp #5
    bne thinrighttree      ; Only width 5 adds character to right hand endge of trunk

    lda trunkwidth
    sec:sbc#8
    sta trunkwidth          ; Reduce trunk width

.thinrighttree
    ; Second to last or last position - 
    lda treew,X
    cmp #5
    bcc nottreerightedge    ; If width<5 no further adjustment required

    lda leafwidth
    sec:sbc#8
    sta leafwidth          ; Reduce leaf width

.nottreerightedge
    lda treeplotloc         
    sec                    
    sbc trunksub            ; Reduce tree plot position based on width
    sta treeplotloc         

.skiptrunkoffset

    lda #0
    sta spritecount         ; counter used to track shifts in random block to produce repeating pattern
                            ; Set to zero to force reload of data on first try

.treeplotlp1
    lda bottomflag
    beq nottrunkbottom      ; Skip bottom if zero
    lda #0
    sta bottomflag          ; Set to zzero for next time
    ldy #4                  ; Set sprite as tree base
    bne firstentry          ; Jump into plot code

.nottrunkbottom
    lsr randombyte
    lsr randombyte          ; Shift random byte right

    dec spritecount     ; Check if we have done 4 shifts
    bpl nonewtrunkrandom     ; Skip if not

    lda #3
    sta spritecount         ; Reset 
    lda trandomstore
    sta randombyte          ; Reset random byte

.nonewtrunkrandom
    lda randombyte          
    and #%11                ; Get bottom two bits
    tay
.firstentry
    treemulttable=P%+1      ; To allow code to be self modifying
    lda mult4,y             ; MUlt table will be written above to be correct for sprite size
    clc
    adc workingtreeplottrunksprite   ; Base of sprite offset
    sta treeplottrunksprite  ; Save calculated sprite offset

    ldy trunkwidth           ; Count of bytes to plot

.treeplotlp2
    lda (treeplottrunksprite),y ; get trunk sprite
    sta (treeplotloc),y         ; Plot trunk sprite
    dey
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey                     
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey
    lda (treeplottrunksprite),y
    sta (treeplotloc),y
    dey                     ;  loop unroll
    bpl treeplotlp2

    dec treeplotloc+1          ; Decrement plot row
    lda treeplotloc+1           
    cmp treeplottop             ; Have we reached the top of the trunk?
    bcs treeplotlp1             ; do loop if not
    cmp screenstart            ; Check if there are any leaves to plot
    bcc skiptreeplot            ; AT top of screen - skip leaves 

    lda #8*3-1                       ; 3 wide
    cmp trunkwidth
    bne trunknot3wide           ; For 3 wide trunk leaves are same width.
    lda treeplotloc
    clc
    adc #4
    sta treeplotloc             ; Add to position because we are going to sibtract below.
.trunknot3wide

; Leaf plot

    lda treeplotloc
    sec             
    sbc leafsub                 ; Subtract previous calculated subtraction
    sta treeplotloc             ; Leaves are somtimes one position left of trees

    lda #0
    sta spritecount             ; Reset reandom counter
    ldy #4                      ; Choose rounded bottom
    bne firstleafentry                    ; First time through

.treeplotlp3
    lsr randombyte
    lsr randombyte          ; Shift random byte right

    dec spritecount     ; Check if we have done 4 shifts
    bpl nonewleafrandom     ; Skip if not

    lda #3
    sta spritecount         ; Reset counter
    lda lrandomstore
    sta randombyte          ; Reset random byte

.nonewleafrandom
    lda randombyte          
    and #%11                ; Get bottom two bits
    tay
.firstleafentry
    leafmulttable=P%+1      ; To allow code to be self modifying
    lda mult4,y
    clc
    adc workingtreeplotleafsprite   ; Base of sprite offset
    sta treeplotleafsprite  ; Save calculated sprite offset

    ldy leafwidth           ; Count of bytes to plot

.treeplotlp4
    lda (treeplotleafsprite),y  ; Plot leaf sprite
    sta (treeplotloc),y
    dey
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey                     
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey                     
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey
    lda (treeplotleafsprite),y
    sta (treeplotloc),y
    dey                         ; Loop unroll                     
    bpl treeplotlp4

    dec treeplotloc+1           ; Decrement plot row
    lda treeplotloc+1
    cmp treeplotltop            ; Compre if we are on the top of the tree
    beq treetop
    bcs treeplotlp3             ; Carry on if not
    bcc skiptreeplot            ; Always taken - exit
.treetop
    ;The logic here is actually incorrect in that a pointed tree top is always plotted
    ;for more ditant trees even if it should have gone off screen. Nearer trees don't
    ;have a tree top so it appears that trees do eventually go offscreen so looks "good enough"
    lda treew,x                   
    cmp #4
    bcs treeplotlp3             ; Don't do special top
    ldy #5                      ; Pointed tree top
    bne firstleafentry          ; skip random

.skiptreeplot
    ; Check bikes
    lda #lo(bike1)
    sta bikepos
    lda #0
    sta biketype                ; Make bike blue

.bikeplotchecklp
    ldy #0                      ; X position
    lda (bikepos),Y
    lsr A:lsr A
    cmp zcount          ; Current pos
    bne dontplotbike        ; If not current row don't plot bike
    jsr plotbike
.dontplotbike
    lda #28                 ; Set dithered
    sta biketype
    lda #lo(bike2)      ; Set second bike
    cmp bikepos         ; Is this the second bike?
    sta bikepos         ; Store anyway for second loop
    bne bikeplotchecklp

    lda boltz           ;Get bolt position
    cmp zcount          ; Compare with current plotted row.
    bne noboltplot      ; Skip if no equal
    tax                 ; move z position into x
    lda bolty,X         ; Get y position
    tay
    lda boltsprite,X    ; Get bolt sprite 
    sta temp1           ; Store for later
    lda boltx           ; Get bolt x position
    sec
    sbc #64
    bmi noboltplot      ; skip if not on screen
    lsr A
    lsr A               ; Divide pos by 4
    tax                 ; move to x
    lda temp1           ; Recall sprite number
    sec
    sbc direction       ; Adjust number based on direction
    sec
    sbc direction       ; Twice....
    jsr maskedplot      ; Plot sprite

.noboltplot

    ldx zcount          ; Restore X
    dex                 ; Reduce rwo count
    bmi finishtree      ; Exit if finished
    jmp plottreeloop    ; Branch > 128 bytes

.finishtree    
    ; Create new trees
    lda newtreecount        ; Check counter
    bpl nonewtree       ; Skip if positive
    lda density         ; Get current density
    sta newtreecount    ; Write to counter

    ldy #0              ; Set magnified direction as 0
    lda direction
    beq storemagdirection   ; Skip if zero
    bmi magdirectionnegative
    ldy #32             ; Load large positive direction
    bne storemagdirection   ; Always taken
.magdirectionnegative
    ldy #lo(-32)        ; Load large negative direction

.storemagdirection
    sty temp1

    jsr dorand          ; Generate random number

    lda rand            ; Get position
    and #127            ; 0-127
    clc
    adc #64             ;64 - 127+64
    sec
    sbc temp1           ; add offset to direction to bias trees in moved direction
    sta treex+31

    jsr dorand
    lda rand
    sta treelr+31       ; Store random seed for leaves

    jsr dorand
    lda rand
    sta treetr+31       ; Store random seed for trunk

    jsr dorand          ; Generate random heights for trees
    lda rand
    and #3
    sta treexlh+31         ; 0-3 for leaf height - includes trunk
    and #1
    sta treexth+31         ; 0=1 for trunk

.nonewtree
; Plot handlebars
    ldy #13                 ; Handlebar sprite
    ldx direction
    beq hstraight
    bmi hright
    dey
    dey         ; To allow iny
.hright
    iny
.hstraight
    tya                 ; move y to handlbar sprite (12-14)
    ldx #12
    ldy #18
    jsr maskedplot      ; Plot handlebars

    jsr printscore      ; Print score every frame

    jmp mainloop        ; Loop

.maskedsprites
incbin "maskedsprites.bin"
.extrasprites
incbin "extrasprites.bin"


textstart=P%-1
incbin "text.bin"

include "distancetables.asm"


.numbers
incbin "numbers.bin"
inrangesprite=numbers+&140
notinrangesprite=numbers+&150


include "sounds.asm"



print "vehicles space",vehiclesprites-P%
align 256   ;    Vehicles need to be sprite aligned to save high byte changes
.vehiclesprites
incbin "vehicles.bin"
print "Vehicles",~vehiclesprites,~P%


include "spritetables.asm"



print "Space",&6c00-P%
save "Chase.bin",&3000-3,P%,start
