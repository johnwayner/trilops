

ARCH = /opt/arm-none-eabi/bin/arm-none-eabi
AS = ${ARCH}-as
LD = ${ARCH}-ld
OBJCOPY = ${ARCH}-objcopy
GDB = ${ARCH}-gdb
QEMU = qemu-system-arm -kernel kernel.elf -cpu arm1176 -m 512 -M raspi  -serial stdio

DEBUG = -g

ASFLAGS = -mcpu=arm1176jzf-s $(DEBUG)
LDFLAGS = -nostdlib -static --error-unresolved-symbols
SRC_DIR = src

%.o: %.s
	$(AS) $(ASFLAGS) -o $*.o $<

kernel.img: kernel.elf
	${OBJCOPY} -O binary $< $@

kernel.elf: trilops.ld reset.o utilities.o disassembler.o xmodem.o
	${LD} ${LDFLAGS} -T trilops.ld reset.o utilities.o disassembler.o xmodem.o -o $@

clean:
	rm -f *.o *.img *.elf

all: kernel.img

run: kernel.elf
	${QEMU}

run-debug: kernel.elf
	${QEMU} -S -s


debug: kernel.elf
	exec ${GDB} -x "./gdbinit" --tui $<
