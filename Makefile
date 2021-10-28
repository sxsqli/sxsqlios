subdir=./kernel

all:run

asm:mbr.asm test.asm asmhead.asm
	nasm -o mbr mbr.asm
	nasm -o test.bin test.asm
	nasm -o asmhead.bin asmhead.asm

img:asm
	dd if=mbr of=sxsqlios.img count=1 bs=512
	dd if=/dev/zero of=sxsqlios.img bs=512 seek=1 skip=1 count=2879

copy:img
	mkdir -p /tmp/floppy
	sudo mount sxsqlios.img /tmp/floppy
#	sleep 1
	sudo cp test.bin /tmp/floppy
	sudo cp asmhead.bin /tmp/floppy
#	sleep 1
	sudo umount /tmp/floppy

run:copy
	qemu-system-i386 -drive file=sxsqlios.img,if=floppy

clean:
	@echo "cleanning project"
	-rm -f mbr *.bin
	@echo "clean completed"
