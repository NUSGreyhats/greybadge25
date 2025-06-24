import board
import busio
import digitalio
import time

# Make sure fpga bitstream is flashed beforehand
#from challenge.hornet_revenge import *
import hardware
overlay = hardware.hw_state["fpga_overlay"]
hardware.display_text(hardware.hw_state, "CTF Mode")
print("Initialising FPGA...")
overlay.init()

### Need clear Pins first #######################
DATA_PINS_NO = [board.GP8, board.GP9, board.GP10, board.GP11, board.GP12]
pins = []
overlay.set_mode((0, 0, 0))
for p in DATA_PINS_NO:
    d = digitalio.DigitalInOut(p)
    d.direction = digitalio.Direction.OUTPUT
    d.value = False
    pins.append(d)
            
for d in pins:
    d.deinit()

### Configure UART GPIO #########################
overlay.set_mode((0,1,1))
uart = busio.UART(board.GP8, board.GP9, baudrate=9600, timeout=0.1)
            
uart.write("AAA")

### UART Insturctions ###########################
#print("Unknown Instruction")
#uart.write("@----------------@")
#print(uart.read())

print("Read Key")
uart.write("@---------------A@")
print(uart.read())

print("Read SMD Skills")
uart.write("@---------------B@")
print(uart.read())


print("Read Unknown")
uart.write("@A---------------@")
print(uart.read())

### CatCore Hyper ###############################
def xor_decode(a: str, b: str, l: int):
    c = ""
    for i in range(l):
        c = c + (chr(ord(a[i % len(a)]) ^ ord(b[i % len(b)])))
    return c

KEY = "1234567890123456"

def run_catcore_hyper_instruction(instr):
    opcode = "D"
    #instr = xor_decode(instr, KEY, len(instr))
    payload = opcode+instr+opcode
    print("payload:", payload, len(payload))
    uart.write(payload)
    
print("Invalid Instruction")
run_catcore_hyper_instruction("----------------")
print(uart.read())

print("Devmode Intro:")
run_catcore_hyper_instruction("@--------------@")
print(uart.read())

print("CatCore Flag:")
run_catcore_hyper_instruction("A--------------A")
print(uart.read())


print("Control LED")
#run_catcore_hyper_instruction("BA------------AB") # Full control over LED
run_catcore_hyper_instruction("B-A\x0c\x02\x08---------B") # All LEDs o
print(uart.read())




### Revert ###############################
print("Read Key")
uart.write("@---------------A@")
print(uart.read())


### AES Encryption #######################
# Send AES Key
uart.write("B----------------B")

# Send AES PlainText
uart.write("C----------------C")

print("AES Out")
uart.write("@---------------E@")
print(uart.read())
