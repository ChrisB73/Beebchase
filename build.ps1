..\..\beebasm-1.09\beebasm.exe -i beebchase.asm
..\..\utils\lzsa -r -f2 chase.bin chase.lzsa
..\..\beebasm-1.09\beebasm.exe -i loader.asm -do ..\..\discs\BeebChase.ssd -opt 3 -title BChaseV1
