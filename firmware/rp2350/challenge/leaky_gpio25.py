__all__ = ["secret_in_gpio25"]

def __dir__():
    return "shoo, go away"

def secret_in_gpio25():
    from board import GP25
    from rp2pio import StateMachine
    from adafruit_pioasm import assemble
    from array import array

    program = """
    .program encode_bits
    .wrap_target
        pull block         ; Pull a 32-bit word from TX FIFO
        set y, 31

    bit_loop:
        out x, 1           ; Shift a bit to x register
        jmp !x send_short  ; If bit is 0, send short pulse 

    send_long:             ; 1 bit = long pulse
        set pins, 1 [31]   ; Pin HIGH for 32 cycles. 0.256 ms @ 125 MHz
        jmp end            ; Jump to the common end section.

    send_short:            ; 0 bit = short pulse
        set pins, 1 [11]   ; Pin HIGH for 12 cycles. 0.096 ms @ 125 MHz

    end:
        set pins, 0        ; Set pin low.
        jmp y-- bit_loop   ; Decrement counter. If not yet zero, loop to send next bit.
    .wrap
    """

    binary = assemble(program)
    frequency = 125_000_000
    sm = StateMachine(
        program=binary,
        first_set_pin=GP25,
        frequency=frequency,
        auto_pull=True,
        pull_threshold=32,
        out_shift_right=False
    )

    FLAG = b"grey{N4n053c0nd_Pr3c1510n!}" # 27 bytes = 216 bits

    # Pack the 27-byte message into 32-bit words
    words = []
    for i in range(0, len(FLAG), 4):
        chunk = FLAG[i:i+4]
        words.append(int.from_bytes(chunk, "big"))

    data = array("I", words)

    sm.write(data)
    print("I leaked the secret in GPIO25! Catch me if you can!")
