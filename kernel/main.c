/*
 * ==================================================
 *
 *       Filename:  bootpack.c
 *
 *    Description:
 *
 *        Version:  0.01
 *        Created:  2014年03月01日 星期六 22时03分34秒
 *         Author:  ChrisZZ, zchrissirhcz@163.com
 *        Company:  ZJUT
 *
 * ==================================================
 */
#include <header.h>
#include <fontascii.h>

// extern struct KEYBUF keybuf;
extern struct FIFO8 keyfifo;
extern struct FIFO8 mousefifo;

int test_add(int a, int b);

void _main(void)
{
	// clear_screen(15);
	// io_hlt();
	extern char hankaku[2048];

	struct BOOTINFO *binfo = (struct BOOTINFO *)ADR_BOOTINFO;
	char s[40], mcursor[228], background[228];
	unsigned char keybuf[32], mousebuf[128];
	int mx = binfo->scrnx / 2, my = binfo->scrny / 2;
	int d;
	unsigned int memtotal;
	struct MOUSE_DEC mdec;
	struct MEMMAN *memman = (struct MEMMAN *)MEMMAN_ADDR;

	fifo8_init(&keyfifo, 32, keybuf);
	fifo8_init(&mousefifo, 128, mousebuf);

	init_palette();
	init_screen8(binfo->vram, binfo->scrnx, binfo->scrny);

	init_gdtidt();
	init_pic();

	for (int y = 0; y < 19; y++)
	{
		for (int x = 0; x < 12; x++)
		{
			background[y * 12 + x] = binfo->vram[(my + y) * binfo->scrnx + (mx + x)];
		}
	}
	init_mouse_cursor8(mcursor, COL8_008484);
	putblock8_8(binfo->vram, binfo->scrnx, 12, 19, mx, my, mcursor, 12);

	io_sti();			  // 开启cpu级别中断
	outb(PIC0_IMR, 0xf9); // 11111001 PIC0开启1号、2号，1号对应键盘，2号对应PIC1
	outb(PIC1_IMR, 0xef); // 11101111 PIC1开启4号，对应IRQ12鼠标中断
	init_keyboard();
	enable_mouse(&mdec);

	sprintf(s, "(%d,%d)", mx, my);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, s);

	memtotal = memtest(0x00400000, 0xbfffffff);
	memman_init(memman);
	memman_free(memman, 0x00001000, 0x0009e000);
	memman_free(memman, 0x00400000, memtotal - 0x00400000);

	sprintf(s, "memory %dMB free: %dKB", memtotal / (1024 * 1024), memman_total(memman) / 1024);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 32, COL8_FFFFFF, s);

	sprintf(s, "_main: %x, add: %x, test_add: %x", _main, add, test_add);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 48, COL8_FFFFFF, s);

	sprintf(s, "1+2=%d,do(1+2)=%d", add(1, 2), do_something(1, 2, add));
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 64, COL8_FFFFFF, s);

	while (1)
	{
		io_cli();
		if (fifo8_status(&keyfifo) + fifo8_status(&mousefifo) == 0)
		{
			io_sti();
			io_hlt();
		}
		else
		{
			if (fifo8_status(&keyfifo) != 0)
			{
				boxfill8(binfo->vram, binfo->scrnx, COL8_840000, 0, 16, 31, 31); // chriszz添加。刷字符区域为蓝色。
				d = fifo8_get(&keyfifo);
				io_sti();
				sprintf(s, "%x", d);
				boxfill8(binfo->vram, binfo->scrnx, COL8_840000, 0, 16, 31, 31);
				putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
			}
			if (fifo8_status(&mousefifo) != 0)
			{
				// boxfill8(binfo->vram, binfo->scrnx, COL8_000084, 32, 16, 64, 31);//chriszz添加。刷字符区域为蓝色。
				d = fifo8_get(&mousefifo);
				io_sti();
				if (mouse_decode(&mdec, d) != 0)
				{
					putblock8_8(binfo->vram, binfo->scrnx, 12, 19, mx, my, background, 12); //刷[原]鼠标位置

					sprintf(s, "[lmr %d %d]", mdec.buf[1], mdec.buf[2]);
					if (mdec.btn & 0x1)
					{
						s[1] = 'L';
					}
					if (mdec.btn & 0x2)
					{
						s[3] = 'R';
					}
					if (mdec.btn & 0x4)
					{
						s[2] = 'M';
					}
					boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 32, 16, 150, 31);
					putfonts8_asc(binfo->vram, binfo->scrnx, 32, 16, COL8_FFFFFF, s);

					mx += mdec.x;
					my += mdec.y;
					mx = mx < 0 ? 0 : mx;
					mx = mx > binfo->scrnx - 12 ? binfo->scrnx - 12 : mx;
					my = my < 0 ? 0 : my;
					my = my > binfo->scrny - 19 ? binfo->scrny - 19 : my;
					sprintf(s, "(%d,%d)", mx, my);
					boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 0, 0, 79, 15);
					putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, s);

					for (int y = 0; y < 19; y++)
					{
						for (int x = 0; x < 12; x++)
						{
							background[y * 12 + x] = binfo->vram[(my + y) * binfo->scrnx + (mx + x)];
						}
					}

					putblock8_8(binfo->vram, binfo->scrnx, 12, 19, mx, my, mcursor, 12); //刷[新]鼠标位置
				}
			}
		}
	}
}

int test_add(int a, int b)
{
	return a + b;
}