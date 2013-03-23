	.include "raspi.inc"

	.macro MEM_BARRIER
	.endm	

	.globl	__print
	@Prints null string at r0 to uart0
	@If r1 is !0 a new line is printed.
	@For now doesn't check ready bit so will only
	@work in qemu
__print:
	ldr	r2, =UART0
_Lprint_str_next_char:	
	ldrb	r3, [r0], #1
	cmp	r3, #0
	strne	r3, [r2, #PL011_DR]
	bne	_Lprint_str_next_char
_Lprint_str_done:
	cmp	r1, #0
	movne	r3, #'\n'
	strne	r3, [r2, #PL011_DR]
	bx	lr

	.globl __setup_framebuffer
	@Configures gpu to display a
	@framebuffer with
	@ r0 = width (in pixels)
	@ r1 = height (in pixels)
	@ r2 = depth (bits per pixel)
	@
	@Sets:
	@ r0 to framebuffer ptr or 0 on error
	@ r1 to pitch (bytes per row)
	@ r2 to fb size
__setup_framebuffer:

_Linit_req_struct:
	adr	r3, framebuffer_struct
	str	r0, [r3, #FB_Width]
	str	r0, [r3, #FB_Width_Virt]
	str	r1, [r3, #FB_Height]
	str	r1, [r3, #FB_Height_Virt]
	str	r2, [r3, #FB_Depth]
_Lcheck_mb_status:
	MEM_BARRIER
	ldr	r0, =MAILBOX_0
	ldr	r1, [r0, #MAILBOX_Status]
	tst	r1, #MAILBOX_Status_Full
	bne	_Lcheck_mb_status

_Lwrite_to_mb:
	adr	r1, framebuffer_struct
	orr	r1, #0x40000000
	orr	r1, #MB_Channel_Framebuffer
	str	r1, [r0, #MAILBOX_Write]


_Lread_from_mb:	
	MEM_BARRIER
	ldr	r1, [r0, #MAILBOX_Status]
	tst	r1, #MAILBOX_Status_Empty
	bne	_Lread_from_mb
	MEM_BARRIER
	ldr	r1, [r0, #MAILBOX_Read]
	tst	r1, #MB_Channel_Framebuffer
	beq	_Lread_from_mb

	ldr	r0, [r3, #FB_Ptr]
	sub	r0, r0, #0x40000000
	ldr	r1, [r3, #FB_Pitch]
	ldr	r2, [r3, #FB_Size]
	bx	lr
@end __setup_framebuffer	

	.align 4
framebuffer_struct:
	.skip	0x28

	
