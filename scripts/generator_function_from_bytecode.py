from typing import List
from tqdm import tqdm
import os.path
import sys

HELP_MESSAGE = "usage: python generator_function_from_bytecode.py [-h | --help] file_name starting_key\n\nwrites an x64 asm function that pushes to the stack each bytes\nrepresented by pairs of hexadecimal digits space-separated in\nthe input file name in the reversed order, in a file named output.s\nthe resulting function obfuscate the data in a silly way, by summing\nthe difference between the last pushed byte and the next byte, to the\nlast pushed byte. This process is initialised with an arbitrary byte\nof your choice (starting_key)\n\n\t-h, --help\t shows this help message\n\tfile name\t name of the file containing the bytecode"
OUTPUT_FILENAME = "output.s"


def generate_asm(filename: str, starting_key : chr) -> None:
    starting_key = ord(starting_key)
    print(f"starting key ascii code: {hex(starting_key)}")
    
    with open(filename,"r") as f:
        data = f.read()

    parsed_data = list(reversed(data.split(" ")))

    if len(parsed_data)%8 != 0:
        number_of_added_noop = (8-len(parsed_data)%8)
        parsed_data += ["90"]*number_of_added_noop
        print(f"no-op codes (0x90) added to the begining of the file: {number_of_added_noop}")

    asm_code = "" # début du code asm
    tmp_instruction = ""
    last_byte = starting_key # initialisation du dernier bit poussé
    qword_counter = 0 # compteur de qword, pour savoir quand pousser rax

    for byte in tqdm(parsed_data):
        difference = int(byte,16) - last_byte

        if difference < 0:
            tmp_instruction += f"sub cl,{hex(-difference)}\nadd al,cl\n"
        else:
            tmp_instruction += f"add cl,{hex(difference)}\nadd al,cl\n"

        qword_counter += 1
        last_byte = int(byte,16)

        if qword_counter == 8:
            qword_counter = 0
            asm_code += tmp_instruction + "push rax\nshl rax,8\n"
            tmp_instruction = ""
        else:
            tmp_instruction += "shl rax,8\n"
            
    with open(OUTPUT_FILENAME,"w") as f:
        f.write(asm_code)


def main(argv: List[str]) -> None:
    if len(argv) < 2:
        print(HELP_MESSAGE)
        sys.exit(1)

    elif argv[1] in ["-h","--help"]:
        print(HELP_MESSAGE)
        sys.exit(0)

    elif len(argv) != 3:
        print(HELP_MESSAGE)
        sys.exit(1)

    elif os.path.isfile(argv[1]):
        generate_asm(argv[1],argv[2][0])
        sys.exit(0)
    else:
        print(f"error: the file '{argv[1]}' does not exist")
        sys.exit(1)

if __name__ == "__main__":
    main(sys.argv)