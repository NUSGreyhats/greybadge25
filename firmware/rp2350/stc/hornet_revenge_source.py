import hardware
overlay = hardware.hw_state["fpga_overlay"]

hardware.display_text(hardware.hw_state, "CTF Mode")
print("Initialising FPGA...")
overlay.init()
overlay.set_mode((0,1,1))


def mcq(question, choices, ans_choice):
    print(question)
    for c in range(len(choices)):
        choice = choices[c]
        print(f"{c}. {choice}")
    choice = int(input("Answer: "))
    return choice == ans_choice
    
def open_ended(question, answer):
    print(question)
    return input("Answer: ").strip().lower() == answer.lower()

def qna1():
    print("Type in full")
    if (
        ### Q #####################################################
        mcq(
            "What is the mcu of the device?",
            ["STM32F103C8T6", "ATMEGA328P", "RP2350", "ESP32"],
            2
        ) and print() is None and
        ### Q #####################################################
        open_ended(
            "What does the P in PIO stand for?",
            "Programmable"
        ) and print() is None and
        ### Q #####################################################
        open_ended(
            "What is an FPGA? Answer with " +
            "F???? P??????????? G??? A???? ",
            "Field Programmable Gate Array"
        ) and print() is None and
        ### Q ######################################################
        open_ended(
            "What are FPGAs 'coded' in? Answer with ????l??",
            "Verilog"
        ) and print() is None and
        ### Q ######################################################
        open_ended(
            "What is the FPGA chip on here? Answer with ?????-??F-6BG256?",
            "LFE5U-25F-6BG256C"
        )
    ):
        print("Success: Here's the 1st part of the flag:")
        print("grey{for_last_greyctf_")
    else:
        print("Wrong lmao")
        
import board
import digitalio
import time
import busio
def qna2():
    print("connect GP27 of the RP to GND")
    time.sleep(1)
    pin = digitalio.DigitalInOut(board.GP27)
    pin.direction = digitalio.Direction.INPUT
    pin.pull = digitalio.Pull.UP
    if pin.value == False:    
        print("2nd part of the flag")
        print("i_was_")
    else:
        print("lmao the pin not GNDed, try using tweezers/ a spare wire/ usb cable, hmmm orr......")
    pin.deinit()
    

PROMPT3 = "Next, we need to extract the key from the FPGA\nI've imported the libraries busio and board for you."
def qna3():
    print(PROMPT3)
    exec(input("Gimme some code to initialise uart at baud rate 9600 on board GP8 and GP9: "))
    exec(input("Send the string '@---------------A@' excluding quotes to the uart: "))
    #print("Press and release the down button to prompt the army for the secret key")
    #time.sleep(5)
    exec(input("Gimme some code to retrieve the key from the FPGA: "))
    print("Run qna4()")
    
def qna4():
    key = input(("Enter the key you got from qna3(): "))
    flag = xor_decode(lmao, key, len(lmao))
    print("3rd part of the flag")
    print(flag)

lmao = '\x13\x07\x05;\x00I\n\x00\x1b\x0e\x16\x19qO\\\x0f\x0c\t$\x1c\x016\x1ax\n-\x1c\x16\x16\x069>\x1bJ\x14"\x15\x0763\x06I\n:\x0b0\x06\x1e:\x04\x022\x1d\x18\x0b\x1a\x00)\x0cC\x10'
### Flag Reading Part 2
def xor_decode(a: str, b: str, l: int):
    c = ""
    for i in range(l):
        c = c + (chr(ord(a[i % len(a)]) ^ ord(b[i % len(b)])))
    return c

print("There are 4 functions to run, qna1(), qna2(), qna3(), qna4()")