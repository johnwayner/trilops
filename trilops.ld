SECTIONS
{
	. = 0x0;
	.text : {
	      *(.reset)
	      *(.text)
	}
	.data : { *(.data) }
	.bss : { *(.bss) }
	__heap_start__ = .;
	. = 0xFFFFFF;
	__stack_start__ = .;
}
