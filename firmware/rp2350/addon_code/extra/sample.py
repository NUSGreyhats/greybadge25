import board
import busio
import digitalio
import time
import hardware.fpga

hardware.hw_state["fpga_overlay"].deinit()
if input("type something to update fpga: ") != "":
    h = hardware.fpga.upload_bitstream("/extra/coprocessor.bit")
    h.deinit()

### Need clear Pins first #######################
DATA_PINS_NO = [board.GP8, board.GP9, board.GP10, board.GP11, board.GP12]
pins = []
for p in DATA_PINS_NO:
    d = digitalio.DigitalInOut(p)
    d.direction = digitalio.Direction.OUTPUT
    d.value = False
    pins.append(d)
            
for d in pins:
    d.deinit()

### Configure UART GPIO #########################
uart = busio.UART(board.GP8, board.GP9, baudrate=460800, timeout=0.1)


# Print dummy message
uart.write("A----------------A-")
print(uart.read())



key = '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
text_in = '\xf3D\x81\xec<\xc6\'\xba\xcd]\xc3\xfb\x08\xf2s\xe6'
plain = '\xf3D\x81\xec<\xc6\'\xba\xcd]\xc3\xfb\x08\xf2s\xe6'
ciph = '\x036v>\x96m\x92YZa|\xc9\xceS\x7f^'

'''
# Trigger Encryption
uart.write("E----------------E-")
print(uart.read())

# Print Encrypted Message
uart.write("@----------------@-")
print(uart.read())
'''

'''
# Trigger Decryption
uart.write("K----------------K-")
print(uart.read())
uart.write("E----------------E-")
print(uart.read())

# Print Decrypted Message
uart.write("`----------------`-")
print(uart.read())
'''

# View Key
uart.write("a----------------a-")
print(uart.read())

# View Text in
uart.write("b----------------b-")
print(uart.read())

#uart.write("C"+key+"C-")
uart.write("C----------------C-")
#uart.write("D----------------D-")
#uart.write("E----------------E-")
#uart.write("F----------------F-")
#uart.write("B----------------B-")
#print(uart.read())
#uart.write("B----------------B-")
#print(uart.read())

