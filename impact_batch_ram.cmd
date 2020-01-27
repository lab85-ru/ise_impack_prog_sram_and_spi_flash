setMode -bs
setCable -port usb21 -baud 6000000
addDevice -p 1 -file ..\example_top.bit
program -p 1
quit