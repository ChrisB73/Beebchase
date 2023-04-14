; Number print routines

.printhiscore
    ; Print hiscore
    lda #hiscore
    ldx #256-5*16
    bne hiscoreentry
.printscore
    ; print score
    ldx #3*8
    lda #score
.hiscoreentry
    sta maskpos
    stx plotpos
    lda #&32
    sta plotpos+1
;MUst run into print numbrs

.printnumbers
;Print score/hiscore
;Takes plotpos as position to plot at
;Takes lo of maskpos as score to plot

    ldy #0      ; 6 pairs
    sty temp1
    sty maskpos+1 ; Top of maskpos is zero as scores in ZP
.scorelp1
    sty temp1
    lda (maskpos),y ; Get number pair
    pha
    and #%11110000  ; get first number - numbers are 16 byte each so Can be used as an offset directly
    clc
    adc #lo(numbers)
    sta spritepos
    lda #hi(numbers)    ; Add offset to numbers
    adc #0
    sta spritepos+1
    ldy #15             ; Two columns of bytes
.scorelp2
    lda (spritepos),y   
    sta (plotpos),Y         
    dey
    lda (spritepos),y
    sta (plotpos),Y         ; Plot first number half with slight loop unrolling
    dey
    bpl scorelp2

    pla

    asl A:asl A:asl A:asl A
    clc
    adc #lo(numbers+160)
    sta spritepos
    lda #hi(numbers+160)        ; Right hand numbers sprite position
    adc #0
    sta spritepos+1

    lda plotpos
    adc #8                 ; Next char pos Carry clear from previous add
    sta plotpos


    ldy #15                 ; Two columns - Right hand side needs writing to screen directly
.scorelp3
    lda (spritepos),y
    sta (plotpos),Y         
    dey
    lda (spritepos),y
    sta (plotpos),Y         ; Plot second number half
    dey
    cpy #7
    bne scorelp3

.scorelp4                   ;left hand side needs eoring with current bytes 
    lda (plotpos),y
    eor (spritepos),Y
    sta (plotpos),y
    dey
    lda (plotpos),y
    eor (spritepos),Y
    sta (plotpos),y
    dey
    bpl scorelp4

    lda plotpos
    clc
    adc #16                 ; Next char pos
    sta plotpos

    ldy temp1
    iny
    cpy #3                  ; Check if we have finished
    bne scorelp1
    rts

.addscore
    ; Add A to score second digits - uised for bonus hits
    sed             ; BCD Scores
    clc
    adc score+1
    sta score+1
    lda score
    adc #0
    sta score
    cld
    rts

.printlives
    ; Print number of lives
    lda lives
    asl a:asl a:asl a:asl A             ; Multiply by 16.
    clc
    adc #lo(numbers+160)
    sta spritepos
    lda #hi(numbers+160)
    adc #0
    sta spritepos+1

    ; Set screen position

    lda #&30
    sta plotpos+1

    lda #%11111111
    sta temp1

    ; Because of screen position lives are 2+6 pixels Same logic as distance flasher.

    ldy #0
.lifelp2
    lda #8*8+6
    sta plotpos
.lifelp
    lda (spritepos),Y
    eor temp1
    sta (plotpos),Y         ; Not speed critical no reason to unroll
    iny
    cpy #2
    beq lifeskip1
    cpy #10
    bne lifeskip2
.lifeskip1
    inc plotpos+1           ; Update screen pos
    lda #7*8+6
    sta plotpos
.lifeskip2
    cpy #8
    beq lifenewrow
    cpy #16
    bne lifelp
    rts
.lifenewrow
    lda #0
    sta temp1
    dec plotpos+1
    bne lifelp2              ; Always taken
