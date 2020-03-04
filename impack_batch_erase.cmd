setMode -bs
setCable -port usb21 -baud 6000000
#identification xilinx fpga from jtag(auto)
Identify -inferir
#identification xilinx fpga from BIT(file)
#addDevice -p 1 -file ..\example_top.bit
attachflash -position 1 -spi "W25Q64FV"
erase -p 1 -o -spionly
quit