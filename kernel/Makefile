#
# Makefile fragment for the JOS kernel.
# This is NOT a complete makefile;
# you must run GNU make in the top-level directory
# where the GNUmakefile is located.
#
#entry.S  main.c
CC = gcc
LD = ld
OBJCOPY	:= $(GCCPREFIX)objcopy
OBJDUMP	:= $(GCCPREFIX)objdump
OBJDIR = .
entry_objs = entry.o
ccode_objs = main.o screen.o font.o print.o idtgdt.o int.o asmint32.o fifo.o mouse.o memory.o
CFLAGS := $(CFLAGS) -O0 -fno-builtin -I$(OBJDIR) -MD
CFLAGS += -fno-omit-frame-pointer
CFLAGS += -Wall -Wno-format -Wno-unused -gstabs -m32 -fno-stack-protector
LDFLAGS = -m elf_i386

%.o:%.c
	$(CC) -nostdinc $(CFLAGS) -c -o $@ $<

%.o:%.S
	$(CC) -nostdinc $(CFLAGS) -c -o $@ $<	
	
%.o:%.asm
	nasm  -f elf -o $@ $<

kernel:entry cobj
	cat entry>>kernel
	cat cobj>>kernel

entry:$(entry_objs)
	$(LD) $(LDFLAGS) -N -e entry -T entry.ld -o $@.out $^
	$(OBJDUMP) -S -D $@.out >$@.asm
	$(OBJCOPY) -S -O binary $@.out $@
	
cobj:$(ccode_objs)
	$(LD) $(LDFLAGS) -N -e bootmain -T kernel.ld -o $@.out $^
	$(OBJDUMP) -S -D $@.out >$@.asm
	$(OBJCOPY) -S -O binary $@.out $@


clean:
	-rm -f *.d *.o *.out kernel kernel.asm cobj* entry.o entry.asm entry
