def mcq(question, choices, ans_choice):
    print(question)
    for choice in choices:
        print(choice)
    choice = int(input())
    return choice == ans_choice
    
def open_ended(question, answer):
    print(question)
    return input().strip().lower() == answer.lower()

if (
    mcq(
        "What is the mcu of the device?",
        ["stm32f103c8t6", "atmega328p", "rp2350a", "esp32"],
        3
    ) and
    open_ended(
        "What is an FPGA?",
        "Field Programmable Gate Array"
    )
):
    print("success")

