..\beebasm-1.09\beebasm.exe -i beebchase.6502
..\utils\lzsa -r -f2 chase.bin chase.lzsa
..\beebasm-1.09\beebasm.exe -i loader.6502 -do ..\discs\BeebChase.ssd -opt 3 -title BChaseV1
