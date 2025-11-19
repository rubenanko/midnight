def cipher_byte(b):
    return ((b ^ 4) + b) & 0xFF


def cipher_block(block):
    result = 0
    for byte in block:
        result = (result << 8) | cipher_byte(byte)
    return result


if __name__ == "__main__":
    password = b"l0IHaYT5Cfuf1ER&"
    print(f"HASH1: 0x{cipher_block(password[:8]):016X}")
    print(f"HASH2: 0x{cipher_block(password[8:]):016X}")
