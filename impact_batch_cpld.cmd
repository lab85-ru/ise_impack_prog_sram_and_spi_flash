setMode -bs
setCable -port usb21 -baud 6000000
addDevice -p 1 -file ..\top.jed
program -e -v -r -p 1
quit