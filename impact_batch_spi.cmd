setMode -bs
setCable -port usb21 -baud 6000000
addDevice -p 1 -file ..\example_top.bit
attachflash -position 1 -spi "W25Q64FV"
assignfiletoattachedflash -position 1 -file .\example_top.mcs
program -p 1 -dataWidth 1 -spionly -e -loadfpga
quit