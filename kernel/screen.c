#include <font.h>
#include <header.h>

void clear_screen(char *vram, int size, unsigned char c)  // 15:pure white
{
  for (int i = 0; i < size; i++) {
    write_mem8(vram + i,
               c);  // if we write 15 ,all pixels color will be white,15 mens
                    // pure white ,so the screen changes into white
  }
}

void color_screen(char *vram, int size)  // 15:pure white
{
  for (int i = 0; i < size; i++) {
    write_mem8(vram + i,
               i & 0x0f);  // if we write 15 ,all pixels color will be white,15
                           // mens pure white ,so the screen changes into white
  }
}

void set_palette(int start, int end, unsigned char *rgb) {
  int i, eflags;
  eflags = io_load_eflags();  // 替代作者的io_load_eflags()
  io_cli();
  io_out8(0x03c8, start);  // 替代作者的io_out8()
  for (i = start; i <= end; i++) {
    io_out8(0x03c9, rgb[0] / 4);
    io_out8(0x03c9, rgb[1] / 4);
    io_out8(0x03c9, rgb[2] / 4);
    rgb += 3;
  }
  io_store_eflags(eflags);  // 替代作者的io_store_eflags(eflags)
  return;
}

void init_palette(void) {
  // 16种color，每个color三个字节。
  const unsigned char table_rgb[16 * 3] = {
      0x00, 0x00, 0x00, /*0:black*/
      0xff, 0x00, 0x00, /*1:light red*/
      0x00, 0xff, 0x00, /*2:light green*/
      0xff, 0xff, 0x00, /*3:light yellow*/

      0x00, 0x00, 0xff, /*4:light blue*/
      0xff, 0x00, 0xff, /*5:light purper*/
      0x00, 0xff, 0xff, /*6:light blue*/
      0xff, 0xff, 0xff, /*7:white*/

      0xc6, 0xc6, 0xc6, /*8:light gray*/
      0x84, 0x00, 0x00, /*9:dark red*/
      0x00, 0x84, 0x00, /*10:dark green*/
      0x84, 0x84, 0x00, /*11:dark yellow*/

      0x00, 0x00, 0x84, /*12:dark 青*/
      0x84, 0x00, 0x84, /*13:dark purper*/
      0x00, 0x84, 0x84, /*14:light blue*/
      0x84, 0x84, 0x84, /*15:dark gray*/
  };
  set_palette(0, 15, table_rgb);
  return;
}

void boxfill8(char *vram, int xsize, unsigned char c, int x0, int y0, int x1,
              int y1) {
  int x, y;
  for (y = y0; y <= y1; y++) {
    for (x = x0; x <= x1; x++) {
      vram[y * xsize + x] = c;
    }
  }
  return;
}

/*
   void init_screen(struct BOOTINFO* binfo){
   binfo->vram = (char*) VRAM;
   binfo->color_mode = 8;
   binfo->xsize = 320;
   binfo->ysize = 200;
   }
   */
void init_screen8(char *vram, int x, int y) {
  boxfill8(vram, x, COL8_008484, 0, 0, x - 1, y - 29);
  boxfill8(vram, x, COL8_C6C6C6, 0, y - 28, x - 1, y - 28);
  boxfill8(vram, x, COL8_FFFFFF, 0, y - 27, x - 1, y - 27);
  boxfill8(vram, x, COL8_C6C6C6, 0, y - 26, x - 1, y - 1);

  boxfill8(vram, x, COL8_FFFFFF, 3, y - 24, 59, y - 24);
  boxfill8(vram, x, COL8_FFFFFF, 2, y - 24, 2, y - 4);
  boxfill8(vram, x, COL8_848484, 3, y - 4, 59, y - 4);
  boxfill8(vram, x, COL8_848484, 59, y - 23, 59, y - 5);
  boxfill8(vram, x, COL8_000000, 2, y - 3, 59, y - 3);
  boxfill8(vram, x, COL8_000000, 60, y - 24, 60, y - 3);

  boxfill8(vram, x, COL8_848484, x - 47, y - 24, x - 4, y - 24);
  boxfill8(vram, x, COL8_848484, x - 47, y - 23, x - 47, y - 4);
  boxfill8(vram, x, COL8_FFFFFF, x - 47, y - 3, x - 4, y - 3);
  boxfill8(vram, x, COL8_FFFFFF, x - 3, y - 24, x - 3, y - 3);
  return;
}

void putfont8(char *vram, int xsize, int x, int y, char c, char *font) {
  int i;
  char *p, d /* data */;
  for (i = 0; i < 16; i++) {
    p = vram + (y + i) * xsize + x;
    d = font[i];
    if ((d & 0x80) != 0) {
      p[0] = c;
    }
    if ((d & 0x40) != 0) {
      p[1] = c;
    }
    if ((d & 0x20) != 0) {
      p[2] = c;
    }
    if ((d & 0x10) != 0) {
      p[3] = c;
    }
    if ((d & 0x08) != 0) {
      p[4] = c;
    }
    if ((d & 0x04) != 0) {
      p[5] = c;
    }
    if ((d & 0x02) != 0) {
      p[6] = c;
    }
    if ((d & 0x01) != 0) {
      p[7] = c;
    }
  }
  return;
}

void putfonts8_asc(char *vram, int xsize, int x, int y, char c, char *s) {
  // 其实这就是一个简易版本的printf
  for (; *s != 0x00; s++) {
    putfont8(vram, xsize, x, y, c, (char *)(font_8_16 + (*s) * 16));
    x += 8;
  }
  return;
}

void init_mouse_cursor8(char *mouse, char bg) {
  const char cursor[19][12] = {
      "*...........", "**..........", "*O*.........", "*OO*........",
      "*OOO*.......", "*OOOO*......", "*OOOOO*.....", "*OOOOOO*....",
      "*OOOOOOO*...", "*OOOOOOOO*..", "*OOOOOOOOO*.", "*OOOOOOOOOO*",
      "*OOOOOO*****", "*OOO*OO*....", "*OO*.*OO*...", "*O*..*OO*...",
      "**....*OO*..", "......*OO*..", ".......**..."};

  int x, y;
  for (y = 0; y < 19; y++) {
    for (x = 0; x < 12; x++) {
      switch (cursor[y][x]) {
        case '.':
          mouse[y * 12 + x] = bg;
          break;
        case '*':
          mouse[y * 12 + x] = COL8_000000;
          break;
        case 'O':
          mouse[y * 12 + x] = COL8_FFFFFF;
          break;
      }
    }
  }
}

void putblock8_8(char *vram, int xsize, int pxsize, int pysize, int px0,
                 int py0, char *buf, int bxsize) {
  // 显示鼠标,display_mouse
  int x, y;
  for (y = 0; y < pysize; y++) {
    for (x = 0; x < pxsize; x++) {
      vram[(py0 + y) * xsize + (px0 + x)] = buf[y * bxsize + x];
    }
  }
}
