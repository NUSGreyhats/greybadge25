
__all__ = ["secret_in_gpio25"]

def __dir__():
    return "shoo, go away"

def secret_in_gpio25():
    from board import GP25
    from rp2pio import StateMachine
    from adafruit_pioasm import assemble
    from array import array

    fa1da1e1 = bytes([0x3C, 0x3E, 0xAF, 0x06] * 4)
    d14d9a726ea3 = bytes([0x85, 0x00, 0xAD, 0x20] * 4)
    c4d4a922 = bytes([0x19, 0x96, 0xC0, 0xBC] * 4)

    j4exE0FZvu = [
        "7e7fd07e5",
        "60fd515414071ea9",
        "0f9129abc9119922c24803b4f6480"
    ]
    KARqOfCw18 = "".join(j4exE0FZvu)
    b2hp3lFbWw = bytes.fromhex(KARqOfCw18)

    F = bytearray(len(b2hp3lFbWw))
    for i, c in enumerate(b2hp3lFbWw):
        if c & 0x80:
            key = fa1da1e1[i & 15]
        elif i & 1:
            key = d14d9a726ea3[i & 15]
        else:
            key = c4d4a922[i & 15]
        F[i] = (c ^ key) ^ ((i * 13) & 0xFF)
    vJ0HwsimvI = bytes(F)

    lines = [
        ".program encode_bits", ".wrap_target",
        "pull block", "set y,31",
        "bit_loop:", "out x,1", "jmp !x send_short",
        "send_long:", "set pins,1 [31]", "jmp end",
        "send_short:", "set pins,1 [11]",
        "end:", "set pins,0", "jmp y-- bit_loop",
        ".wrap"
    ]
    pio_src = "\n".join(lines)
    binary = assemble(pio_src)

    sm = StateMachine(
        program=binary,
        first_set_pin=GP25,
        frequency=125_000_000,
        auto_pull=True,
        pull_threshold=32,
        out_shift_right=False
    )

    WHzgE6r1JUa = array("I", [
        int.from_bytes(vJ0HwsimvI[i : i + 4], "big")
        for i in range(0, len(vJ0HwsimvI), 4)
    ])
    sm.write(WHzgE6r1JUa)
    print("I leaked the secret in GPIO25! Catch me if you can!")
