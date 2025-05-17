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
        "What is the FPGA chip on here? Answer with ?????_??_CABGA256",
        "ECP5U_25_CABGA256"
    )
):
    print("success")


### Flag Reading Part 2
def xor_decode(a: str, b: str, l: int):
    c = ""
    for i in range(l):
        c = c + (chr(ord(a[i]) ^ ord(b[i])))
    return 