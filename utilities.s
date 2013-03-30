	.include "raspi.inc"
	.include "font8x8.inc"

	.text

	.align 2

	.macro CACHE_MCR reg, val1, val2=0
	mcr	p15, 0, \reg, c7, \val1, \val2
	.endm
	
	.macro MEM_BARRIER reg
	mov	\reg, #0
	CACHE_MCR \reg, c6	@Invalidate entire data cache
	CACHE_MCR \reg, c10	@Clean entire data cache
	CACHE_MCR \reg, c14	@Clean and invalidate entire data cache
	CACHE_MCR \reg, c10, 4	@Data sync barrier
	CACHE_MCR \reg, c10, 5	@Data memory barrier
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
	MEM_BARRIER r2
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
	MEM_BARRIER r2
	ldr	r1, [r0, #MAILBOX_Status]
	tst	r1, #MAILBOX_Status_Empty
	bne	_Lread_from_mb
	MEM_BARRIER r2
	ldr	r1, [r0, #MAILBOX_Read]
	tst	r1, #MB_Channel_Framebuffer
	beq	_Lread_from_mb

	ldr	r0, [r3, #FB_Ptr]
	sub	r0, r0, #0x40000000
	str	r0, [r3, #FB_Ptr]
	ldr	r1, [r3, #FB_Pitch]
	ldr	r2, [r3, #FB_Size]
	bx	lr
@end __setup_framebuffer	

	.align 4
	.globl framebuffer_struct
framebuffer_struct:
	.skip	0x28
scr_current_row:
	.word	0
scr_current_col:
	.word 	0
scr_current_font:
	.word	font8x8
	
	.align 2
	.globl __print_char_scr
	@
	@ print 7-bit char of r0 at row r1 col r2 with font r3
	@
__print_char_scr:
	push	{r0-r6}
	ldr	r3, =font8x8
	and	r0, r0, #0xF
	add	r3, r3, r0, lsl #3
	adr	r0, framebuffer_struct
	ldr	r4, [r0, #FB_Pitch]
	ldr	r0, [r0, #FB_Ptr]
	mov	r1, r1, lsl #3
	mul	r1, r4, r1
	add	r0, r0, r1
	add	r0, r0, r2, lsl #4
	mov	r1, #0


	mov	r6, #0x8		@8 rows
_Lprint_nib_next_row:
	ldrb	r5, [r3], #1
	mov	r5, r5, lsl #24
	mov	r2, #0x8		@8 bits
_Lprint_nib_loop1:
	movs	r5, r5, lsl #1
	strcsh	r1, [r0], #2
	addcc	r0, r0, #2
	subs	r2, #1
	bne	_Lprint_nib_loop1
	add	r0, r0, r4		@Add pitch for next row, minus 16
	sub	r0, r0, #16
	subs	r6, #1
	bne	_Lprint_nib_next_row

	pop	{r0-r6}
	bx	lr
	
	.globl print_word_scr
	@
	@ print r0 value to screen current row, inc row
	@
print_word_scr:
	bx	lr
	

	.globl __console_pr
	@
	@ print null-term-string (r0) to console at current loc.
	@
__console_pr:
	ldr	r1, =font8x8
	mov	r4, #0			@ Black
	adr	r5, framebuffer_struct
	Ldr	r6, [r5, #FB_Pitch]
	ldr	r5, [r5, #FB_Ptr]
	adr	r7, scr_current_row
	ldr	r7, [r7]
	mov	r7, r7, lsl #3		@ row_num * 8 (8 lines per char) =rasterlines
	mul	r7, r6, r7		@ raster_lines*pitch = ptr-offset
	add	r5, r5, r7		@ ptr + ptr-offset = y position adr = ptr
	adr	r7, scr_current_col
	ldr	r7, [r7]
	add	r5, r5, r7, lsl #4	@ col_num * (8*2) (2bytes*8chars) + ptr = ptr
	mov	r8, r7			@ column counter
	
_Lconpr_next_char:	
	ldrb	r2, [r0], #1		@ load char
	cmp	r2, #0
	beq	_Lconpr_done
	cmp	r2, #'\n'
	beq	_Lconpr_next_line
	add	r8, r8, #1		@ counting chars to update positions
	

	mov	r2, r2, lsl #3		@ find fontchar = char*8 + font_adr
	ldr	r3, [r1, r2]		@ Read top half of fontchar
	rev	r3, r3			@ big endian it
	mov	r7, #32
	sub	r5, r6			@ mov ptr back one pitch, it'll get moved up first time thru loop
	add	r5, #2*8
_Lconpr_char_half:
	mov	r9, r7, lsl #29
	tst	r9, #0xE0000000
	addeq	r5, r5, r6		@If 8th bit of font-row, pitch up
	subeq	r5, #2*8		@and back up 16 bytes to get back to beginning font col

	movs	r3, r3, lsl #1
	subcc	r4, #1
	strh	r4, [r5], #2
	addcc	r4, #1

	subs	r7, #1
	bne	_Lconpr_char_half
	

	cmp	r2, #0			@ on bottom half, r2 = 0
	subeq	r5, r5, r6, lsl #3	@ ptr =  ptr - 7*pitch
	addeq	r5, r5, r6		
	beq	_Lconpr_next_char
	
	add	r2, #4			@ after top half r2 = ptr for top half. add 4 for bottom
	ldr	r3, [r1, r2]		@ load bottom
	rev	r3, r3			@ big endian it
	mov	r2, #0			@ and set r2 = 0 to bail next loop around
	mov	r7, #32
	b	_Lconpr_char_half

_Lconpr_done:
	adr	r7, scr_current_col
	str	r8, [r7]
	bx	lr

_Lconpr_next_line:
	adr	r1, scr_current_row	@ Hacks... 
	ldr	r2, [r1]		@ row++
	add	r2, r2, #1
	cmp	r2, #1080 / 8
	movgt	r2, #0			@ row = 0 if we go off the screen.
	str	r2, [r1], #4		@ ! -> mov to col
	mov	r2, #0			@ col = 0
	str	r2, [r1]
	b	__console_pr		@ r0 points to next char already :) :)
