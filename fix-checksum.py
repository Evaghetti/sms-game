#!/usr/bin/env python3

import argparse



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculates the checksum for a Sega Master System ROM")
    parser.add_argument("romPath", type=str, nargs=1, help="File that the checksum will be calculated")
    parser.add_argument("--out", "-o", help="Result file (default: overwrite)", required=False, type=str)
    args = parser.parse_args()

    pathToRom = args.romPath[0]
    outPutPath = args.out or pathToRom

    with open(pathToRom, "rb") as fileRom:
        romData = bytearray(fileRom.read())
   
    resultSum = sum(romData[0x0000:0x7FF0])
    resultSum &= 0xFFFF
    romData[0x7FFA] = resultSum & 0xFF
    romData[0x7FFB] = (resultSum & 0xFF00) >> 8

    with open(outPutPath, "wb") as fileOut:
        fileOut.write(romData)