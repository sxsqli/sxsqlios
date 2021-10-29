addr=0xc400
OBJDIR=.

CFLAGS:=$(CFLAGS) -O1 -fno-builtin -I$(OBJDIR) -MD
CFLAGS+=-fno-omit-frame-pointer
CFLAGS+=-Wall -Wno-format -Wno-unused -Werror -gstabs -m32

LDFLAGS=-m elf_i386

all:kernel

kernel:entry.o main.o screen.o
	ld $(LDFLAGS) -N -e start -Ttext $(addr) -o $@.out $^
	objdump -S $@.out >$@.asm
	objcopy -S -O binary -j .text $@.out $@

%.o:%.S
	gcc -nostdinc $(CFLAGS) -c -o $@ $<
%.o:%.c
	gcc -nostdinc $(CFLAGS) -c -o $@ $<

clean:
	-rm -f entry.o main.o screen.o kernel.out kernel.asm kernel *.d
