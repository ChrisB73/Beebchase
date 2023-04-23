; GAme constants

    include "sprites.bin.info"
    include "vehicles.bin.info"
    include "maskedsprites.bin.info"
    include "extrasprites.bin.info"
    include "text.bin.info"


org &1b01           ; 01 to stop treex indexing crossing page

; Bike data structure
; 0 = Z position            
; 1 = movement duration
; 2 = Status -1 destroyed, 0=moving left, 2 = straight, 4 = moving right
; 3 = X position     
.bike1
skip 4
.bike2
skip 4
.bikeend

.treex
skip 32
.treelr
skip 32
.treetr
skip 32
.treexth
skip 32
.treexlh
skip 32


;Increment top byte if carry st
MACRO ADD16 addr
bcc addskip
inc addr
.addskip
ENDMACRO

;-----------------------------------------------------------------------------------------------------------------------------------------------------
; os vectors and functions
;-----------------------------------------------------------------------------------------------------------------------------------------------------

irqAcc			= &fc			; irq1 bbc os stores accumulator here
irqVector		= &204			; irq1 jump vector

osword=&fff1
osbyte			= &fff4			; os function
oscli			= &fff7			; os function
osfile			= &ffdd			; os function
oswrch			= &ffee			; os function

;-----------------------------------------------------------------------------------------------------------------------------------------------------
; 6522 via
;-----------------------------------------------------------------------------------------------------------------------------------------------------

viaPortB		= &fe40			; via port B data
viaPortDdrB		= &fe42			; via port B io control

viaPortDdrA		= &fe43			; via Port A io control

viaT1CounterLo		= &fe44			; via timer 1 low counter
viaT1CounterHi		= &fe45			; via timer 1 high counter
viaT1LatchLo		= &fe46			; via timer 1 low latch
viaT1LatchHi		= &fe47			; via timer 1 high latch

viaT2CounterLo		= &fe48			; via timer 2 counter low
viaT2CounterHi		= &fe49			; via timer 2 counter high

viaAcr			= &fe4b			; via auxiliary control register

viaIfr			= &fe4d			; via interrupt flags
via2Ifr			= &fe6d			; via interrupt flags
viaIer			= &fe4e			; via interrupt enable (via #1)
via2Ier			= &fe6e			; via interrupt enable (via #2)

viaPortA		= &fe4f			; via Port A data (no handshake)

;-----------------------------------------------------------------------------------------------------------------------------------------------------
; video chips
;-----------------------------------------------------------------------------------------------------------------------------------------------------

crtcAddr		= &fe00			; 6845 address
crtcData		= &fe01			; 6845 data
ulaMode			= &fe20			; ula video mode
ulaPalette		= &fe21			; ula colour palette

