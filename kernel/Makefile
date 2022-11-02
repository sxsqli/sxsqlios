AS = nasm
CC = gcc
LD = ld
OBJCOPY	= objcopy
OBJDUMP	= objdump

OBJDIR = .
entry_objs = entry.o
ccode_objs = main.o screen.o font.o print.o idtgdt.o int.o asmint32.o fifo.o mouse.o memory.o

CFLAGS := $(CFLAGS) -I$(OBJDIR) -O0 -MD -m32 -ggdb
CFLAGS += -nostdinc -fno-builtin -fno-omit-frame-pointer -fno-stack-protector
CFLAGS += -Wall -Wno-format -Wno-unused
LDFLAGS = -m elf_i386

kernel:entry cobj
	cat entry>>kernel
	cat cobj>>kernel

%.o:%.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o:%.S
	$(CC) $(CFLAGS) -c -o $@ $<

entry:$(entry_objs)
	$(LD) $(LDFLAGS) -N -e entry -T entry.ld -o $@.out $^
	$(OBJDUMP) -S -D $@.out >$@.asm
	$(OBJCOPY) -S -O binary $@.out $@

cobj:$(ccode_objs)
	$(LD) $(LDFLAGS) -N -e _main -T kernel.ld -o $@.out $^
	$(OBJDUMP) -S -D $@.out >$@.asm
	$(OBJCOPY) -S -O binary $@.out $@

clean:
	-rm -f *.d *.o *.out kernel kernel.asm cobj* entry.o entry.asm entry
