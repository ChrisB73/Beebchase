; sound parameters

.enginechannel0
equw &0010      ; Channel 0 flush
equw -10        ; Volume
equw 3          ; Pitch = follow channel 1
equw -1         ; Duration

.enginechannel1
equw &0011      ; Channel 1 flush
equw 5          ; Volume
equw 3          ; Pitch
equw -1         ; Duration

.shotsound
equw &0012      ; Channel 2 flush
equw 1          ; Volume
equw 80          ; Pitch = follow channel 1
equw 5        ; Duration

.explosionsound
equw &0013      ; Channel 3 flush
equw 2          ; Volume
equw 40          ; pitch
equw 15         ; Duration


.playerdie0
equw &0010      ; Channel 0 flush
equw -15        ; Volume
equw 7          ; Pitch = follow channel 1
equw 55         ; Duration

.playerdie1
equw &0011      ; Channel 1 flush
equw 3          ; Volume
equw 150          ; pitch
equw 55        ; Duration

.daysound3
equw &0013      ; Channel 1 flush
equw 4          ; Volume
equw 49          ; pitch
equw 20        ; Duration

.daysound2
equw &0012      ; Channel 1 flush
equw 4          ; Volume
equw 65          ; pitch
equw 20        ; Duration


.enginepitches
equb 100,140,150,160,170

.envelopedata
equb 1,1,120,0,0,10,0,0,100,lo(-2),lo(-2),lo(-2),100,0
equb 2,1,33,0,0,50,0,0,100,lo(-1),lo(-1),lo(-1),100,0
equb 3,129,lo(-1),0,0,110,0,0,80,0,0,lo(-100),70,70
equb 4,130,1,0,0,30,0,0,75,0,0,lo(-3),75,75
equb 5,1,0,4,0,8,1,7,0,0,0,0,0,0

print "Sounds",~enginechannel0,~P%
