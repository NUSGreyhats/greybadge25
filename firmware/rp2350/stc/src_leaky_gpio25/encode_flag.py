_KEY_A = bytes.fromhex("3c3eaf06" * 4)
_KEY_B = bytes.fromhex("8500ad20" * 4)
_KEY_C = bytes.fromhex("1996c0bc" * 4)

def _decrypt(data: bytes) -> bytes:
    """
    Branching decode:
      if high-bit set, use _KEY_A
      elif odd index, use _KEY_B
      else, use _KEY_C

    Then undo the little nonlinear mix (i*13)&0xFF.
    """
    out = bytearray(len(data))
    for i, c in enumerate(data):
        if c & 0x80: 
            k = _KEY_A[i % len(_KEY_A)]
        elif i & 1:
            k = _KEY_B[i % len(_KEY_B)]
        else:
            k = _KEY_C[i % len(_KEY_C)]
        x = c ^ k
        out[i] = x ^ ((i * 13) & 0xFF)
    return bytes(out)

def _encrypt(plaintext: bytes) -> bytes:
    """
    Invert the above: for each byte p at index i, compute x = p^mix,
    then try each key in the same order, checking the same branch
    conditions on the candidate ciphertext.
    """
    out = bytearray(len(plaintext))
    for i, p in enumerate(plaintext):
        mix = (i * 13) & 0xFF
        x = p ^ mix

        # 1) KEY_A branch
        kA = _KEY_A[i % len(_KEY_A)]
        cA = x ^ kA
        if cA & 0x80:
            out[i] = cA
            continue

        # 2) KEY_B branch (odd indices, low-bit)
        kB = _KEY_B[i % len(_KEY_B)]
        cB = x ^ kB
        if not (cB & 0x80) and (i & 1):
            out[i] = cB
            continue

        # 3) KEY_C branch (even indices, low-bit)
        kC = _KEY_C[i % len(_KEY_C)]
        cC = x ^ kC
        if not (cC & 0x80) and not (i & 1):
            out[i] = cC
            continue

        # If you see this, pick a different set of keys or tweak your scheme
        raise ValueError(f"No valid branch for byte index {i}")
    return bytes(out)

if __name__ == "__main__":
    FLAG = b"grey{N4n053c0nd_Pr3c1510n!}"
    encrypted = _encrypt(FLAG)
    print("Encrypted blob (hex):", encrypted.hex())

    # double check
    assert _decrypt(encrypted) == FLAG
    print("✔️  Round-trip OK.")

