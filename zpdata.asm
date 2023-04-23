; Zero page data for Beebchase

org 0
guard &88   ; &88+ are keyboard locations

.temp1
skip 1

.temp2
skip 1
.zcount
skip 1
.direction
skip 1
.newtreevalue
skip 1
.newtreecount
skip 1
.plotheight
skip 1
.treeplotloc
skip 2
.treeplottop
skip 1
.treeplotltop
skip 1

.plotpos
.treeplottrunksprite
skip 2

.spritepos
.treeplotleafsprite
skip 2

.maskpos
.workingtreeplottrunksprite
skip 1

.workingtreeplotleafsprite
skip 1

.spritecount
skip 1

.leafwidth
skip 1

.trunkwidth
skip 1

.screenstart
skip 1


.rand
skip 2

.trandomstore
skip 1

.lrandomstore
skip 1

.randombyte
skip 1

.speed
skip 1

.speedcount
skip 1

.framecount
skip 1

.score
skip 3 

.hiscore
skip 3

.lives
skip 1

.leafsub
skip 1

.trunksub
skip 1

.density
skip 1

.bottomflag
skip 1

.paletteoffset
skip 1

.timeroffset
skip 1

.chopperpos
skip 1

.keyspressed
skip 1

.bikepos        ; Bike position in memory
skip 2

.biketype
skip 1

.boltx
skip 1

.boltz
skip 1

.rangeflag
skip 1

.gamespeed
skip 1

.level
skip 1

.nightmode
skip 1

.gamestatus
skip 1      ; 0 - running, -1 game start, 1 game over

.bonustimer
skip 1

.bonusx
skip 1
.bgx
skip 3

.bonusy
skip 1
.bgy
skip 3

.bonussprite    ; Low values of Sprites to plot
skip 4

.bonusstatus    ;0 tank, 1 - chopper, negative - explosion
skip 1

.choppercount
skip 1

.fcstore
skip 1

.oldspeed
skip 1

.lastmove
skip 1

.soundstatus
skip 1

print "zp space",&88-P%