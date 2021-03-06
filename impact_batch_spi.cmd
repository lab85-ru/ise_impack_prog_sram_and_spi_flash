setMode -pff
addConfigDevice  -name "example_top" -path "."
setMode -pff
setSubmode -pffspi
setAttribute -configdevice -attr multibootBpiType -value ""
addDesign -version 0 -name "0"
setMode -pff
addDeviceChain -index 0
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr autoSize -value "FALSE"
setAttribute -configdevice -attr fileFormat -value "mcs"
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr swapBit -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "TRUE"
addPromDevice -p 1 -size 8192 -name 8M
setMode -pff
addDeviceChain -index 0
setSubmode -pffspi
setMode -pff
setAttribute -design -attr name -value "0000"
addDevice -p 1 -file "../example_top.bit"
setMode -pff
setSubmode -pffspi
generate
setCurrentDesign -version 0

setMode -bs
setCable -port usb21 -baud 6000000
addDevice -p 1 -file ..\example_top.bit
attachflash -position 1 -spi "W25Q64FV"
assignfiletoattachedflash -position 1 -file .\example_top.mcs
program -p 1 -dataWidth 1 -spionly -e -loadfpga
quit