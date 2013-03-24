	.macro CAT mask val handler
	.word	\mask
	.word	\val
	.word	\handler
	.endm

	.extern __print
	.text
	.globl	__disassembler
	@This is a little test program to help
	@me learn arm asm better.  It takes an
	@address in r0 and disassembles the arm
	@instructions it finds there until it hits
	@a #0 value word.
	@It prints the results using __print and
	@returns nothing useful.
__disassembler:
	push	{r4-r6, lr}
_Lnext_instr:	
	ldr	r1, [r0], #4
	cmp	r1, #0
	beq	_Ldone

_Lfind_cat:
	@r0 = instr ptr
	@r1 = instr
	@r2 = next cat ptr
	@r3 = scratch/work
	@r4 = cat mask
	@r5 = cat match val
	@r6 = cat handler
	

	adr	r2, categories
_Lfind_cat_next:
	ldmia	r2!, {r4-r6}
	cmp	r4, #0xFFFFFFFF
	beq	_Lfind_cat_missing
	and	r3, r1, r4
	cmp	r3, r5
	bxeq	r6
	b	_Lfind_cat_next

_Lfind_cat_missing:
	b	_Ldone

categories:
	@The order here is important as some cats are catch alls
	CAT	0x0E000010, 0x00000000, _Lcat_data_proc
	CAT	0x0F900010, 0x01000000, _Lcat_misc_1
	CAT	0x0F900090, 0x01000010, _Lcat_misc_2
	CAT	0x0E000090, 0x00000090, _Lcat_mult_xtra_ldstr
	CAT	0x0E000090, 0x00000010, _Lcat_data_proc
	CAT	0x0FB00000, 0x03000000, _Lcat_undef
	CAT	0x0FB00000, 0x03200000, _Lcat_mov_imm_status
	CAT	0x0E000000, 0x02000000, _Lcat_data_proc
	CAT	0x0E000000, 0x04000000, _Lcat_ldstr_imm_offset
	CAT	0x0E000010, 0x06000000, _Lcat_ldstr_reg_offset
	CAT	0x0E000010, 0x60000010, _Lcat_media
	CAT	0x0FF000F0, 0x07F000F0, _Lcat_undef
	CAT	0x0E000000, 0x08000000, _Lcat_ldstr_mult
	CAT	0x0E000000, 0x0A000000, _Lcat_bl
	CAT	0x0E000000, 0x0C000000, _Lcat_copro_ldrstr
	CAT	0x0F000010, 0x0E000000, _Lcat_copro_data_proc
	CAT	0x0F000010, 0x0E000010, _Lcat_copro_reg_xfer
	CAT	0x0F000000, 0x0F000000, _Lcat_swi

	CAT	0xF0000000, 0xF0000000, _Lcat_uncond
	.word 	0xFFFFFFFF


	.align 2
_Lprint_cond:
	push	{lr}
	mov	r2, r1, ror #28
	and	r2, #0xF
	add	r2, r2, r2, lsl #1
	mov	r1, #0
	adr	r0, cond_opcodes
	add	r0, r0, r2
	bl	__print
	pop	{pc}
cond_opcodes:
	.ascii	"EQ\0NE\0CS\0CC\0MI\0PL\0VS\0VC\0HI\0LS\0GE\0LT\0GT\0LE\0AL\0!!\0"
_Lcat_data_proc:
	mov	r5, r0
	mov	r6, r1
	mov	r4, r1, lsr #21
	and	r4, r4, #0xF
	adr	r0, data_proc_opcodes
	add	r0, r0, r4, lsl #2
	mov	r1, #0
	bl	__print
	mov	r1, r6
	bl	_Lprint_cond
	mov	r1, #1
	tst	r6, #0x100000
	adreq	r0, blank
	adrne	r0, s_code
	bl	__print
	mov	r1, r6
	mov	r0, r5
	b	_Lnext_instr
data_proc_opcodes:
	.ascii	"AND\0EOR\0SUB\0RSB\0ADD\0ADC\0SBC\0RSC\0TST\0TEQ\0CMP\0CMN\0ORR\0MOV\0BIC\0MVN\0"
s_code:	
	.asciz	"S"
blank:	.asciz	""
	.align 2
_Lcat_misc_1:
_Lcat_misc_2:	
_Lcat_mult_xtra_ldstr:	
_Lcat_undef:	
_Lcat_mov_imm_status:	
_Lcat_ldstr_imm_offset:	
_Lcat_ldstr_reg_offset:	
_Lcat_media:	
_Lcat_undef:	
_Lcat_ldstr_mult:	
_Lcat_bl:	
_Lcat_copro_ldrstr:	
_Lcat_copro_data_proc:	
_Lcat_copro_reg_xfer:	
_Lcat_swi:	
_Lcat_uncond:
	mov	r4, r0
	adr	r0, unknown_opcode
	mov	r1, #1
	bl	__print
	mov	r0, r4
	b	_Lnext_instr

unknown_opcode:	
	.asciz "???"

_Ldone:
	pop	{r4-r6, lr}
	bx	lr



	
