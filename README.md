# DOS-like Operating System

This project is a lightweight DOS-like operating system written in Assembly. It features a functional bootloader and kernel, with foundational support for keyboard input and basic command-line functionality. Future updates will expand its capabilities to include a proper FAT filesystem and advanced file-related commands.

## Features

### Current Functionality
- **Bootloader:**
  - Loads the kernel successfully into memory.

- **Kernel:**
  - **Keyboard Input:** Interactive input from the keyboard.
  - **Command-Line Interface:**
    - Commands supported:
      - `cls`: Clears the screen.
      - `help`: Displays help information for available commands.
      - `version`: Shows the current version of the OS.

### Planned Features
- **FAT12/16 Filesystem Support:**
  - Read and write operations for files.
  - Proper directory handling.

- **Command-Line Enhancements:**
  - `MKDIR`: Create new directories.
  - `DIR`: List directory contents.
  - Additional file management commands.

## System Requirements

- x86-compatible hardware or emulator (e.g., QEMU, VirtualBox, or Bochs).
- Assembly programming tools (e.g., NASM or MASM).

## How to Build and Run

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/dos-like-os.git
    ```
2. Run the `make` command to assemble the bootloader, kernel, and create the disk image:
    ```bash
    make
    ```
3. Run the OS in an emulator (e.g., QEMU):
    ```bash
    make run
    ```

## Architecture

- **Bootloader:**
  - Loads the kernel into memory.
  - Transfers control to the kernel after successful loading.

- **Kernel:**
  - Handles basic I/O and command-line interactions.
  - Keyboard interrupt handling for input.


## Future Development Goals

1. **Filesystem Integration:**
    - Full FAT12/16 support.
    - Ability to read/write files and navigate directories.

2. **Enhanced Command-Line:**
    - Add advanced commands like `COPY`, `DELETE`, and `RENAME`.

3. **System Utilities:**
    - Basic utilities for file and disk management.

4. **Basic demo applets like games**
   
## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments
- Inspiration from classic DOS systems.
- Assembly programming resources and tutorials.

---

Feel free to contribute or suggest ideas for improving this project!

