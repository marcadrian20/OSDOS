# Define the directories and files
KERNEL_NAME = kernel
BOOTLOADER_NAME = bootloader
OUTPUT_IMG = disk.img

# Define the assembler and tools
NASM = nasm
DD = dd
RM = rm

# Paths to the source files
KERNEL_SRC = kernel.asm
BOOTLOADER_SRC = bootloader.asm

# Assembly flags
NASM_FLAGS = -f bin

# The default target
all: $(OUTPUT_IMG)

# Build the bootloader and kernel
$(KERNEL_NAME).bin: $(KERNEL_SRC)
	$(NASM) $(NASM_FLAGS) -o $(KERNEL_NAME).bin $(KERNEL_SRC)

$(BOOTLOADER_NAME).bin: $(BOOTLOADER_SRC)
	$(NASM) $(NASM_FLAGS) -o $(BOOTLOADER_NAME).bin $(BOOTLOADER_SRC)

# Create a disk image with bootloader and kernel
$(OUTPUT_IMG): $(BOOTLOADER_NAME).bin $(KERNEL_NAME).bin
	$(RM) -f $(OUTPUT_IMG)  # Clean up any existing disk image
	dd if=/dev/zero of=$(OUTPUT_IMG) bs=512 count=2880
# mkfs.fat -F 12 $(OUTPUT_IMG)
	mformat -i disk.img -v "OSDOS" ::/
	dd if=$(BOOTLOADER_NAME).bin of=$(OUTPUT_IMG) bs=512 seek=0 conv=notrunc
# dd if=$(KERNEL_NAME).bin of=$(OUTPUT_IMG) bs=512 seek=18 conv=notrunc
# mcopy -i $(OUTPUT_IMG) kernel.asm ::/
	mcopy -i $(OUTPUT_IMG) kernel.bin ::/
# mcopy -i $(OUTPUT_IMG) bootloader.asm ::/

# Clean up build artifacts
clean:
	$(RM) -f $(KERNEL_NAME).bin $(BOOTLOADER_NAME).bin $(OUTPUT_IMG)

# For debugging purposes
debug:
	hexdump -C disk.img | head -n 64
# qemu-system-x86_64 -drive format=raw,file=$(OUTPUT_IMG) -s -S &
# @gdb -ex "target remote localhost:1234" \
#      -ex "symbol-file $(KERNEL_NAME).bin" \
#      -ex "layout asm" \
#      -ex "layout regs"
run:
	qemu-system-x86_64 -drive format=raw,file=$(OUTPUT_IMG)

.PHONY: all clean debug
