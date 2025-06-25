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

### DES Encryption ####
print()
uart.write("@---------------G@")
print(uart.read())

print("DES Encryption/ Decryption")
uart.write("GBBBBBBBB--------G") # Seed is "-"
uart.write("@---------------G@")
print(uart.read())


# Decryption
payload = "ABCDEFGH"
config = "A-----B-"
uart.write("G"+payload+config+"G") # Seed is "-"
uart.write("@---------------G@")
print(uart.read())
print()

### CatCore Hyper ###############################
def xor_decode(a: str, b: str, l: int):
    c = ""
    for i in range(l):
        c = c + (chr(ord(a[i % len(a)]) ^ ord(b[i % len(b)])))
    return c



def run_catcore_hyper_instruction(instr):
    opcode = "D"
    #instr = xor_decode(instr, KEY, len(instr))
    payload = opcode+instr+opcode
    print("payload:", payload, payload.encode(), len(payload))
    uart.write(payload)
    
KEY = "1234567890123456"
def run_catcore_hyper_admin_instruction(instr):
    opcode = "D"
    instr = xor_decode(instr, KEY, len(instr))
    payload = opcode+instr+opcode
    print("payload:", payload, len(payload))
    uart.write(payload)

### Basic
print("Invalid Instruction test")
run_catcore_hyper_instruction("----------------")
print(uart.read())


### Devmode instruction
print("Devmode Intro:")
run_catcore_hyper_instruction("@-----------DEV@")
print(uart.read())

print("Control LED")
#run_catcore_hyper_instruction("BA------------AB") # Full control over LED
run_catcore_hyper_instruction("BA\x0c\x02\x08-------DEVB") # All LEDs o
print(uart.read())

print()

## CatCore without signing
print("Non Devmode Intro: (Should Fail)")
run_catcore_hyper_instruction("@--------------@")
print(uart.read())

print("CatCore Flag:")
run_catcore_hyper_instruction("A1w4n7myfl49p15A")
print(uart.read())


## CatCore with signing
KEY = "1234567890123456"
print()
print("Non Devmode Intro - admin:")
run_catcore_hyper_admin_instruction("@--------------@")
print(uart.read())

print("CatCore Flag:")
run_catcore_hyper_admin_instruction("A1w4n7myfl49p15A")
print(uart.read())

print()


### Revert ###############################
print("Read Key")
uart.write("@---------------A@")
print(uart.read())

uart.write("a----------------a")
print(uart.read())
### AES Encryption #######################
# Send AES Key
uart.write("B----------------B")

# Send AES PlainText
uart.write("C----------------C")

print("AES Out")
uart.write("@---------------E@")
print(uart.read())
