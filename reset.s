	.include "raspi.inc"
	
	.section .reset
	.globl __reset
__reset:
	b	__reset_handler
	b	.
	b	.
	b	.	
	b	.
	b	.
	b	.

__reset_handler:
	ldr	sp, =__stack_start__

__init_uart0:	
	ldr	r0, =UART0
	mov	r1, #0x30		@9600 baud @ 7.3728Mhz
	str	r1, [r0, #PL011_IBRD]
	mov	r1, #0x70
	str	r1, [r0, #PL011_LCR_H]	@8-N-1
	ldr	r1, [r0, #PL011_CR]
	orr	r1, #0x01
	str	r1, [r0, #PL011_CR]

__boot:
	adr	r0, booting
	bl	__print
	
	mov	r0, #1024
	mov	r1, #768
	mov	r2, #16			@This must be 16 to work in qemu at least.
	bl	__setup_framebuffer
	bl	__color_screen

	adr	r0, __color_screen
	ldr	r0, =UART0
	mov	r1, #0x10000
	bl	__xmodem_recv
	b	.

booting:
	.asciz	"Booting..."

	.align	2
__color_screen:
	add	r0, r0, r2
	mvn	r3, #0x0
_Lloopty:	
	str	r3, [r0], #-4
	cmp	r0, r2
	bne	_Lloopty
	mov	pc, lr

	addne	r1, r1, #4
	.word 	0 			@This is here to stop the disassembler


