#!/usr/bin/python3

import mmap
import struct
import sys
from pathlib import Path


def patch_equivalent_zero_instruction(
    binary: Path,
    text_offset: int,
    text_size: int,
) -> int:
    with binary.open("r+b") as file:
        with mmap.mmap(file.fileno(), 0) as blob:
            text_end = text_offset + text_size
            if text_offset < 0 or text_end > len(blob) or text_offset % 4:
                raise RuntimeError("invalid Mach-O __text bounds")

            for offset in range(text_offset, text_end - 3, 4):
                instruction = struct.unpack_from("<I", blob, offset)[0]
                register = instruction & 0x1F

                # MOVZ Wd,#0 → MOV Wd,WZR (ORR Wd,WZR,WZR)
                if instruction & 0xFFFFFFE0 == 0x52800000:
                    replacement = 0x2A1F03E0 | register
                # MOVZ Xd,#0 → MOV Xd,XZR (ORR Xd,XZR,XZR)
                elif instruction & 0xFFFFFFE0 == 0xD2800000:
                    replacement = 0xAA1F03E0 | register
                else:
                    continue

                struct.pack_into("<I", blob, offset, replacement)
                blob.flush()
                return offset

    raise RuntimeError("equivalent zero-instruction patch point not found")


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: patch_macho.py BINARY TEXT_OFFSET TEXT_SIZE")

    offset = patch_equivalent_zero_instruction(
        Path(sys.argv[1]),
        int(sys.argv[2], 0),
        int(sys.argv[3], 0),
    )
    print(offset)


if __name__ == "__main__":
    main()
