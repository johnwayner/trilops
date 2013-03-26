	.include "raspi.inc"

	.extern framebuffer_struct
	@
	@ Xmodem-1k-CRC impl
	@
	@ IN:
	@ r0 uart ptr
	@ r1 memory address of destination
	@
	@ OUT:
	@ r0 num bytes read, -1 = failure
	@

	.globl __xmodem_recv
__xmodem_recv:
	mov	r4, #0		@ Sequence tracker
	ldr	r5, =framebuffer_struct
	ldr	r8, [r5, #FB_Ptr]
	mov	r9, #0
	strh	r9, [r8], #2


_Luart_ready:	
	@ wait for uart to be ready
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Send_Full
	bne	_Luart_ready

	@ send 'C' to signal start
	mov	r3, #C
	str	r3, [r0, #PL011_DR]


_Lsender_wait:
	@ wait for sender
	ldr	r3, [r0, #PL011_FR]
	tst	r3, #PL_Recv_Empty
	movne	r9, #0b0000000000011111
	strneh	r9, [r8], #2
	bne	_Lterrible_wait

	@ read char to determine state
	ldr	r3, [r0, #PL011_DR]
	cmp	r3, #STX		@Only support 1k
	beq	_Lread_packet
	cmp	r3, #EOT
	beq	_Ldone

	@ should wait 10 if not seen SOH
	@ or 3 otherwise?

	@ some terrible waiting code
_Lterrible_wait:

	mov	r3, #0x1000000
_Lterrible_wait_loop:
	subs	r3, r3, #1
	bne	_Lterrible_wait_loop
	b	_Luart_ready

_Ldone:	
	bx	lr

_Lread_packet:
	@ r0 = uart
	@ r1 = dest ptr for this packet
	@ r2 = free
	@ r3 = free
	@ r4 = expected seq number

	mov	r9, #0b1111100000000000
	strh	r9, [r8], #2
_Lrp_sender_wait:
	@ wait for sender
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Recv_Empty
	beq	_Lrp_sender_wait

	@ Read seq and complement
	ldr	r2, [r0, #PL011_DR]
	ldr	r3, [r0, #PL011_DR]
	mvn	r3, r3
	cmp	r2, r3
	movne	r3, #NAK
	bne	_Lsend_char_and_next	@ seq nums messed up, NAK
	cmp	r2, r4			@ seq ok, expected seq?
	blt	_Lflush			@ seq we've seen, just flush it
	movgt	r3, #NAK
	bgt	_Lsend_char_and_next	@ seq greater, NAK it

	@ seq should be good at this point
	@ read the data
	@ r2 = data
	@ r3 = running crc
	@ r5 = 1k - byte count
	mov	r5, #0x2000
	mov	r3, #0
_Lrp_read_byte:
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Recv_Empty
	beq	_Lrp_read_byte

	ldr	r2, [r0, #PL011_DR]
	strb	r2, [r1], #1

	@ update CRC
	mov	r6, #8
	ldr	r7, =0x1021	
_Lrp_crc_loop:
	subs	r6, r6, #1
	beq	_Lrp_crc_loop_done	
	movs	r3, r3, lsl #1	
	bcs	_Lrp_crc_eor
	mov	r2, r2, lsl #1
	tst	r2, #0x100
	addne	r3, #1
	b	_Lrp_crc_loop
_Lrp_crc_eor:	
	mov	r2, r2, lsl #1
	tst	r2, #0x100
	addne	r3, #1
	eor	r3, r3, r7
	b	_Lrp_crc_loop
_Lrp_crc_loop_done:
	subs	r5, r5, #1
	bne	_Lrp_read_byte

	@ 1k read now read crc
_Lrp_read_crc:
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Recv_Empty
	beq	_Lrp_read_crc

	ldr	r2, [r0, #PL011_DR]
	cmp	r2, r3, lsr #8
	mov	r3, #NAK
	bne	_Lsend_char_and_next
_Lrp_read_crc2:	
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Recv_Empty
	beq	_Lrp_read_crc2

	ldr	r2, [r0, #PL011_DR]
	and	r3, r3, #0xFF
	cmp	r2, r3
	moveq	r3, #ACK
	addeq	r4, #1			@Inc expected seq
	movne	r3, #NAK
	subne	r1, #1024		@Move dest ptr back 1k for retry
	b	_Lsend_char_and_next

_Lsend_char_and_next:
	@r2 consumed
	@Char to send in r3
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Send_Full
	bne	_Lsend_char_and_next

	str	r3, [r0, #PL011_DR]
	b	_Lsender_wait

_Lflush:
	@Read all data, then send ACK
	ldr	r2, [r0, #PL011_FR]
	tst	r2, #PL_Recv_Empty
	ldrne	r2, [r0, #PL011_DR]
	bne	_Lflush
	mov	r3, #NAK
	b	_Lsend_char_and_next

	.equ	SOH, 0x01	@Starts 128 byte packet
	.equ	STX, 0x02	@Starts 1k byte packet
	.equ	EOT, 0x04	@Ends transmission
	.equ	ACK, 0x06	@Acknowledges goodness
	.equ	NAK, 0x15	@Acknowledges badness/ready to recv checksum-based packet
	.equ	CAN, 0x18	@Signals a desire to cancel
	.equ	C, 'C'		@Signals ready to recv CRC packet
