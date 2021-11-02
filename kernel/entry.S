# Start the CPU: switch to 32-bit protected mode, jump into C.
# The BIOS loads this code from the first sector of the hard disk into
# memory at physical address 0x7c00 and starts executing in real mode
# with %cs=0 %ip=7c00.
# AT&T格式汇编
#include <mmu.h>

#define VBEMODE   0x0105

#define CYLS      0x0ff0
#define LEDS      0x0ff1
#define VMODE     0x0ff2
#define SCRNX     0x0ff4
#define SCRNY     0x0ff6
#define VRAM      0x0ff8

#define BOTPAK    0X00280000
#define DSKCAC    0x00100000
#define DSKCAC0   0X00008000 


.globl entry
entry:
    .code16                     # Assemble for 16-bit mode
    jmp     start

msg:
    .asciz  "\r\n\r\nsxsqlios kernel is runing"

puts:
    movb    (%si),%al
    add     $1,%si
    cmp     $0,%al
    je      over
    movb    $0x0e,%ah
    movw    $15,%bx
    int     $0x10
    jmp     puts
over:
    ret

start:
    movw    $0x9000,%ax
    movw    %ax,%es
    movw    $0,%di
    movw    $0x4f00,%ax
    int     $0x10
    cmp     $0x004f,%ax
    jne     scrn320

    movw    %es:4(%di),%ax
    cmp     $0x0200,%ax
    jb      scrn320

    movw    $VBEMODE,%cx
    movw    $0x4f01,%ax
    int     $0x10
    cmp     $0x004f,%ax
    jne     scrn320

    cmpb    $8,%es:0x19(%di)        # 颜色数必须为8
    jne     scrn320
    cmpb    $4,%es:0x1b(%di)
    jne     scrn320
    movw    %es:0x00(%di),%ax
    and     $0x0080,%ax
    jz      scrn320

    movw    $(VBEMODE+0x4000),%bx
    movw    $0x4f02,%ax
    int     $0x10
    movb    $8,(VMODE)              # 模式
    movw    %es:0x12(%di),%ax
    movw    %ax,(SCRNX)
    movw    %es:0x14(%di),%ax
    movw    %ax,(SCRNY)
    movl    %es:0x28(%di),%eax
    movl    %eax,(VRAM)
    jmp     keystatus
    
scrn320:
    # 利用中断int 0x10来改变显示模式
    movb    $0x13,%al       # vga 320x200x8 位,color mode 
    movb    $0x00,%ah  
    int     $0x10   
    movb    $10,(CYLS)      # save color mode in ram 0x0ff0
    movb    $8,(VMODE)
    movw    $320,(SCRNX)
    movw    $200,(SCRNY)
    movl    $0x000a0000,(VRAM)

keystatus:
    # get keyboard led status
    movb    $0x02,%ah 
    int     $0x16           # keyboard interrupts
    movb    %al,(LEDS)
    # diplay "my kernel is runing jos"
    movw  $msg,%si
    call  puts
  

    # 禁用所有PIC
    movb    $0xff,%al
    outb    %al,$0x21       # 禁止主PIC的全部中断
    nop                     # 如果连续执行OUT指令，有些机种会无法正常运行
    out     %al,$0xa1       # 禁止从PIC的全部中断
    cli                     # 禁止CPU级别的中断

    # Enable A20:
    #   For backwards compatibility with the earliest PCs, physical
    #   address line 20 is tied low, so that addresses higher than
    #   1MB wrap around to zero by default.  This code undoes this. 
seta20.1:
    inb     $0x64,%al               # Wait for not busy
    testb   $0x02,%al               # if 1 :busy ,if 0:idle
    jnz     seta20.1
    # 对port 0x64  写0xd1
    movb    $0xd1,%al               # 0xd1 -> port 0x64
    outb    %al,$0x64
seta20.2:
    inb     $0x64,%al               # Wait for not busy
    testb   $0x02,%al
    jnz     seta20.2
    # 对port 0x60 写0xdf
    movb    $0xdf,%al               # 0xdf -> port 0x60
    outb    %al,$0x60 
    # 通过对上面的Port的操作，实现enable A20
    # Switch from real to protected mode, using a bootstrap GDT       this is vip ,but i don`t know it clearly now
    # and segment translation that makes virtual addresses 
    # identical to their physical addresses, so that the 
    # effective memory map does not change during the switch.
    # movw $msg,%si
    # call puts
  
    lgdt    gdtdesc                # 设定临时GDT
    movl    %cr0,%eax
    andl    $0x7fffffff,%eax       # 设bit31为0（为了禁止颁）
    orl     $0x00000001,%eax       # 设bit0为1（为了切换到保护模式）
    movl    %eax,%cr0  
    # 这个地方非常的重要，一但这条movl %eax,%cr0把cr0的pe位打开后，下面的
    # 代码就是32位的，所以空上ljmp的指令是条过度指令，选择 用的gdt是1*8,
    # 也就是第一个gdt(从0开始的)。

    # Jump to next instruction, but in 32-bit code segment.
    # Switches processor into 32-bit mode.  这一个跳转的意义重大
    # jmp     protcseg
    ljmp    $(3*8),$protcseg # 32位的跳转指令。 ljmp selector,offset

    # ######################################################################
    # 正式进入32位的保护模式。
    # ######################################################################
    .code32                        # Assemble for 32-bit mode
protcseg:
    # Set up the protected-mode data segment registers
    # movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    movw    $(1*8),%ax
    movw    %ax,%ds                # -> DS: Data Segment  //vip
    movw    %ax,%es                # -> ES: Extra Segment
    movw    %ax,%fs                # -> FS
    movw    %ax,%gs                # -> GS
    movw    %ax,%ss                # -> SS: Stack Segment

    # Set up the stack pointer and call into C.
    # stack range: 0x00300000 - 0x003fffff
    movl    $0x3fffff,%esp
  
ccode: 
    # 把c代码部分复制到其它的memory的地址  1024个扇区的内容
    # memcopy(bootmain,BOTPAK,size=512*1024/4);#BOTPAK =0X00280000
    movl    $main,%esi
    movl    $BOTPAK,%edi
    movl    $(512*1024/4),%ecx
    call    memcpy
bootsector:  
    # 把bootsector的内容复制到 0x100000的位置  
    movl    $0x7c00,%esi
    movl    $DSKCAC,%edi  # DSKCAC=0x00100000 把bootsector的内容复制到0x100000地址处
    movl    $(512/4),%ecx
    call    memcpy
all:
    # 把整个软盘上的内容复制到 0x100000内存地址处
    movl    $(DSKCAC0+512),%esi
    movl    $(DSKCAC+512) ,%edi  
    movl    $0,%ecx
    movb    (CYLS),%cl
    imul    $(512*18*2/4),%ecx
    subl    $(512/4),%ecx
    call    memcpy
  
  
  # 下面的这部分不明白，先不管了   这 一部分还真有可能是bootpack的头文件。  这一部分是小日本自己写的一个header,用了小日本自己的工具，所以我没有要这个header
  # movl $BOTPAK ,%ebx  ；ebx=0x280000
  # movl 16(%ebx),%ecx    ecx= int (*0x280010) 跳过16个字节
  # addl  $3     ,%ecx    ecx=ecx+3
  # shr   $2     ,%ecx    ecx=ecx/4   ecx中放的是c部分代码的大小
  # jz   skip
  # movl 20(%ebx),%esi
  # addl %ebx    ,%esi
  # movl 12(%ebx),%edi
  # call memcpy  
  
    ljmp    $(2*8),$0x0000


memcpy:
    movl    (%esi),%eax
    addl    $4,%esi
    movl    %eax,(%edi)
    addl    $4,%edi
    subl    $1,%ecx
    jnz     memcpy
    ret

# Bootstrap GDT
.p2align 4                               # force 8 byte alignment
gdt:
    .word   0x0000,0x0000,0x0000,0x0000  # null seg  0
    .word   0xffff,0x0000,0x9200,0x00cf  # data selector 1
    .word   0xffff,0x0000,0x9a28,0x0047  # c code        3
    .word   0xffff,0x0000,0x9a00,0x0047  # entry code    2
    .word   0x00
  
gdtdesc:
    .word   31         # 4*8-1                 # sizeof(gdt) - 1
    .long   gdt                             # address gdt

.p2align 4                              # force 16 byte alignment
main: