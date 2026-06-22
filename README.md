# uart-hex-terminal
A UART-driven hexadecimal terminal implemented in VHDL on the Basys 3 FPGA.  

Characters entered through Tera Term are received over UART, decoded into hexadecimal digits, and displayed on the four-digit seven-segment display.

## Features

- UART receive/transmit
- FIFO buffering
- ASCII to hexadecimal conversion
- Four-digit scrolling display
- Backspace support
- Clear command
- Uppercase and lowercase hexadecimal support

## Hardware

- Digilent Basys 3
- Xilinx Artix-7 FPGA

## Commands

| Input | Action |
|---------|---------|
| 0-9 | Display digit |
| A-F | Display hex digit |
| a-f | Display hex digit |
| Backspace | Remove last digit |
| Space | Clear display |
