
; Interrupt routines.
; Tese take the vsync and set timer2 from there for a colour change.  Each colour change sets a subsequent interrupt to move down the screen gradually.

.irq
    LDA &FE4D           \
    lsr A
    lsr A
    Bcs top_of_sc       \  Z=1 => we are at top of screen
    and #%00001000
    beq go_old_irq1v    \  bit5 (now 3) => timer2 has not yet run out

    ; Drop through to timer routine

    TXA                 \  Stash X
    PHA 
 
    ldx paletteoffset

    lda palettes,X      ; Set palettes
    STA &FE21           \  Palette control register
    inx
      lda palettes,X
    STA &FE21           \  Palette control register
    inx
      lda palettes,X
    STA &FE21           \  Palette control register
    inx
      lda palettes,X
    STA &FE21           \  Palette control register
    inx

    stx paletteoffset   ; Save new offset

    ldx timeroffset     ; Get timer offset
    lda irqtimes,x      ;Set new timer values
    sta &fe48
    inx
    lda irqtimes,x
    sta &fe49
    inx
    stx timeroffset

    PLA                 \  Retrieve X
    TAX
    
\  acnowledge timer 2
    lda #%00100000
    sta &fe4d
\ Don't give the timer 2 back to the os
    lda &fc
    rti

.go_old_irq1v
    JMP (old_irq1v)

.old_irq1v
equw &dc93

.top_of_sc
    ; Vsync interrupt
    TXA                 \  Stash X
    PHA
    
\  Set up timer 2 to fire an interrupt partway down the screen

    LDA #lo(512*17-2)          \  Initialise timer 2
    STA &FE48
    LDA #hi(512*17-2)
    STA &FE49           \  Writing the high byte sets it going
    
;   Reset the palette at the top of the screen.  This includes tree colour and sky colour
    LDX #11
.write_pal1
    LDA palettetop,X
    STA &FE21           \  Palette control register
    DEX
    BPL write_pal1

    inc framecount

    lda #0
    sta paletteoffset
    sta timeroffset

    PLA 
    TAX 

\  Our work here is done now .....

    JMP (old_irq1v)

.irqtimes
; successive times for each colour change.
equw 512-6
equw 6*512
equw 512*3+64
equw &ffff


.toppal

.palettes
equb &83,&93,&c3,&d3        ; 2 > Blue
equb &05,&15,&45,&55        ; 0 > Green
equb &87,&97,&c7,&d7        ; 2 > Black
equb &22,&32,&62,&72        ; 1 > Magenta


.palettetop
equb &01,&11,&41,&51        ; 0 > Sky colour
equb &26,&36,&66,&76        ; 1 > Red
equb &85,&95,&c5,&d5        ; 2 > Green
