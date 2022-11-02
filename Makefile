kernel_dir=kernel

all:run

mbr:mbr.asm
	nasm -o mbr mbr.asm

img:mbr
	dd if=mbr of=sxsqlios.img count=1 bs=512
	dd if=/dev/zero of=sxsqlios.img bs=512 seek=1 count=2879

.PHONY: kernel
kernel:
	make -C $(kernel_dir) $@

copy:img kernel
	mkdir -p /tmp/floppy
	-sudo mount sxsqlios.img /tmp/floppy
	-sudo cp $(kernel_dir)/kernel /tmp/floppy
	sudo umount /tmp/floppy

run:copy
	qemu-system-i386 -drive file=sxsqlios.img,format=raw,if=floppy

clean:
	@echo "cleanning project"
	-rm -f mbr *.bin
	make -C $(kernel_dir) clean
	@echo "clean completed"
