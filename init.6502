; Game initialisation
; Set up Screen and interrupts
; Only used once

    ; Assumed that these have been set from Basic
    lda &8E
    sta rand
    lda &8F
    sta rand+1

    lda #32+128             ; F0
    sta &8D                 ; Store sound key         

    lda #hi(bike1)
    sta bikepos+1           ; Store bike position high byte - constant

    lda #0
    sta hiscore
    sta hiscore+1
    sta hiscore+2           ; Reset hi score
    sta soundstatus         ; Clear sound status
    sta bottomflag          ; Clear tree bottom flag

    lda #9
    ldx #0
    jsr osbyte              ; Disable flashing colours 

    ; Set CRTC using vdu 23,0,x,y.....
    ldx #13
.crtcloop
    lda #23
    jsr oswrch
    lda #0
    jsr oswrch
    txa
    jsr oswrch
    lda crtcregs,X
    jsr oswrch
    lda #0
    jsr oswrch
    jsr oswrch
    jsr oswrch
    jsr oswrch
    jsr oswrch
    jsr oswrch

    DEX
    BPL crtcloop

; Set initial screen start
    lda #&1C                ; Should be 1C
    sta screenstart

    ; Clear screen 
    sta plotpos+1
    ldy #0
    tya
    ldx #20
    sty plotpos
.initclrlp
    sta (plotpos),Y
    dey
    bne initclrlp
    inc plotpos+1
    dex
    bne initclrlp

    ;Set envelopes - space not a concern so simplistc approach
    lda #&8
    ldx #lo(envelopedata)
    ldy #hi(envelopedata)
    jsr osword

    lda #&8
    ldx #lo(envelopedata+14)
    ldy #hi(envelopedata+14)
    jsr osword

    lda #&8
    ldx #lo(envelopedata+14*2)
    ldy #hi(envelopedata+14*2)
    jsr osword

    lda #&8
    ldx #lo(envelopedata+14*3)
    ldy #hi(envelopedata+14*3)
    jsr osword

    lda #&8
    ldx #lo(envelopedata+14*4)
    ldy #hi(envelopedata+14*4)
    jsr osword


;Write Video ULA
    lda #154
    ldx #%11000100          ; set for mode 5
    jsr osbyte

; Initialise interrupts

SEI
LDA #2:.vsync BIT &FE4D:BEQ vsync   ; Wait for vsync

    LDA &204
    STA old_irq1v
    LDA &205
    STA old_irq1v+1                        
    lda #lo(irq)
    sta &204
    lda #hi(irq)
    sta &205

    lda #%00011101
    sta &fe4e       ; Disable the interrupts we don't want
    lda #%01000000  ; Set the timer mode
    sta &fe4b
    lda #%01111111  ; Disable system VIA 2 interrupts
    sta &fe6e

LDA #(312*64 DIV 2 - 2) MOD 256:STA &FE44
LDA #(312*64 DIV 2 - 2) DIV 256:STA &FE45       ; Set frequency of T1 to not interfere with Vsync

CLI

;Set colour 3 to white

    lda #19
    jsr oswrch
    lda #3
    jsr oswrch
    lda #7
    jsr oswrch
    lda #0
    jsr oswrch
    jsr oswrch
    jsr oswrch

