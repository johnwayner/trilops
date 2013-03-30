	.include "raspi.inc"
	
	.section .reset
	.global __reset
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
	mov	r1, #0x1		@115200 baud @ 3Mhz
	str	r1, [r0, #PL011_IBRD]
	mov	r1, #41
	str	r1, [r0, #PL011_FBRD]
	mov	r1, #0x70
	str	r1, [r0, #PL011_LCR_H]	@8-N-1
	ldr	r1, [r0, #PL011_CR]
	orr	r1, #0x01
	str	r1, [r0, #PL011_CR]

__boot:
	mov	r1, #1
	adr	r0, booting
	bl	__print
	
	mov	r0, #1920
	ldr	r1, =1080
	mov	r2, #16
	bl	__setup_framebuffer
	bl	__color_screen

@ 	mov	r0, #0xF
@ 	mov	r1, #1080 / 8 
@ _Lrow:
@ 	add	r0, r0, #1
@ 	mov	r2, #1920 / 8 - 1
@ _Lloop:	
@ 	bl	__print_nibble_scr
@ 	subs	r2, r2, #1
@ 	bne	_Lloop
@ 	subs	r1, r1, #1
@ 	bne	_Lrow

	adr	r0, booting
	bl	__console_pr
	adr	r0, longtext
	bl	__console_pr

	b	.
	adr	r0, __color_screen
	bl	__disassembler
	b	.

booting:
	.asciz	"Booting...\n"
longtext:
	.asciz	"Seoul, South Korea (CNN) -- North Korea's threatening rhetoric has reached a fever pitch, but the Pentagon and the South Korean government have said it's nothing new.\n\"We have no indications at this point that it's anything more than warmongering rhetoric,\" a senior Washington Defense official said late Friday.\nThe official was not authorized to speak to the media and asked not to be named.\nState media: North Korea in 'state of war' with South The National Security Council, which advises the U.S. president on matters of war, struck a similar cord. Washington finds North Korea's statements \"unconstructive,\" and it does take the threats seriously."

	.align	2
__color_screen:
	add	r0, r0, r2
	mvn	r3, #0x0
_Lloopty:	
	str	r3, [r0], #-4
	cmp	r0, r2
	bne	_Lloopty
	mov	pc, lr

	.word 	0 			@This is here to stop the disassembler


