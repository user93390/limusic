#!/usr/bin/env python3
"""
Extract export symbols from libmpv.dll and write a MSVC-compatible .def file.

Reads the PE export directory directly (via pefile), filters out Java JNI
forwarder symbols and -> export entries, and writes a well-formed DEF file
with explicit CRLF line endings that MSVC's lib.exe requires.
"""

import sys
import pefile


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(f"Usage: {sys.argv[0]} <input.dll> <output.def>")

    dll_path = sys.argv[1]
    def_path = sys.argv[2]

    pe = pefile.PE(dll_path)
    try:
        exp_dir = pe.OPTIONAL_HEADER.DATA_DIRECTORY[0]
        exp = pe.parse_export_directory(exp_dir.VirtualAddress, exp_dir.Size)

        names = []
        for sym in exp.symbols:
            if not sym.name:
                continue
            name = sym.name.decode("ascii", errors="replace")
            if name.startswith("Java_") or "->" in name:
                continue
            names.append(name)

        lines = ["EXPORTS"] + ["    " + n for n in names]
        def_bytes = ("\r\n".join(lines) + "\r\n").encode("ascii")

        with open(def_path, "wb") as f:
            f.write(def_bytes)

        print(f"Written {len(def_bytes)} bytes, {len(names)} exports -> {def_path}")
    finally:
        pe.close()


if __name__ == "__main__":
    main()
