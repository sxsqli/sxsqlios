.global asm_inthandler21
.global asm_inthandler2c
.global load_gdtr
.global load_idtr

.global io_hlt
.global io_cli
.global io_sti

.global io_in8
.global io_in16
.global io_in32

.global io_out8
.global io_out16
.global io_out32

.global io_load_eflags
.global io_store_eflags

.global load_cr0
.global store_cr0

.code32
asm_inthandler21:
  pushw %es
  pushw %ds
  pushal
  movl %esp,%eax
  pushl %eax
  movw %ss,%ax
  movw %ax,%ds
  movw %ax,%es
  call inthandler21
  popl %eax
  popal
  popw %ds
  popW %es
  iretl

asm_inthandler2c:
	pushw %es
	pushw %ds
	pushal
	movl %esp, %eax
	pushl %eax
	movw %ss, %ax
	movw %ax, %ds
	movw %ax, %es
	call inthandler2c
	popl %eax
	popal
	popw %ds
	popw %es
	iretl


load_gdtr:		#; void load_gdtr(int limit, int addr);
  mov 4(%esp) ,%ax
  mov %ax,6(%esp)
  lgdt 6(%esp)
  ret


load_idtr:		#; void load_idtr(int limit, int addr);
  mov 4(%esp) ,%ax
  mov %ax,6(%esp)
  lidt 6(%esp)
  ret

io_hlt:
  hlt
  ret

io_cli:
  cli
  ret

io_sti:
  sti
  ret

io_in8:
  mov 4(%esp),%edx
  mov 0,%eax
  in %dx,%al
  ret

io_in16:
  mov 4(%esp),%edx
  mov 0,%eax
  in %dx,%ax
  ret

io_in32:
  mov 4(%esp),%edx
  in %dx,%eax
  ret

io_out8:
  mov 4(%esp),%edx
  mov 8(%esp),%eax
  out %al,%dx
  ret

io_out16:
  mov 4(%esp),%edx
  mov 8(%esp),%eax
  out %ax,%dx
  ret

io_out32:
  mov 4(%esp),%edx
  mov 8(%esp),%eax
  out %eax,%dx
  ret

io_load_eflags:
  pushfl
  popl %eax
  ret

io_store_eflags:
  mov 4(%esp),%eax
  pushl %eax
  popfl
  ret

load_cr0:
  mov %cr0,%eax
  ret

store_cr0:
  mov 4(%esp),%eax
  mov %eax,%cr0
  ret