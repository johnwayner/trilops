@ Stuff for the Versatile board Qemu emulates

UART0		= 0x20201000 
MAILBOX_0	= 0x2000B880

@
@PL011 Register Offsets
@
PL011_DR	= 0x000
PL011_RSR	= 0x004
PL011_ECR	= 0x004
PL011_FR	= 0x018
PL011_IBRD	= 0x024
PL011_FBRD	= 0x028
PL011_LCR_H	= 0x02C
PL011_CR	= 0x030
PL011_IFLS	= 0x034
PL011_IMSC	= 0x038
PL011_RIS	= 0x03C
PL011_MIS	= 0x040
PL011_ICR	= 0x044
PL011_DMACR	= 0x048
PL011_PeriphID0	= 0xFE0
PL011_PeriphID1	= 0xFE4
PL011_PeriphID2	= 0xFE8
PL011_PeriphID3	= 0xFEC
PL011_PCellID0	= 0xFF0
PL011_PCellID1	= 0xFF4
PL011_PCellID2	= 0xFF8
PL011_PCellID3	= 0xFFC

@
@PL011 FR (status) masks
@
PL_Send_Empty	= 0x80
PL_Recv_Full	= 0x40
PL_Send_Full	= 0x20
PL_Recv_Empty	= 0x10
PL_Busy		= 0x08
PL_CTS		= 0x01


@
@ Mailbox offsets
@
MAILBOX_Read	= 0x00
MAILBOX_Peek	= 0x10
MAILBOX_Sender	= 0x14
MAILBOX_Status	= 0x18
MAILBOX_Config	= 0x1C
MAILBOX_Write	= 0x20

@ Mailbox Masks
MAILBOX_Status_Empty	= 0x40000000
MAILBOX_Status_Full	= 0x80000000

@ Mailbox Channels
MB_Channel_Power	= 0
MB_Channel_Framebuffer	= 1
MB_Channel_VirtUART	= 2
MB_Channel_VCHIQ	= 3
MB_Channel_LEDs		= 4
MB_Channel_Buttons	= 5
MB_Channel_Touch	= 6

@Framebuffer struct
FB_Width	= 0x00
FB_Height    	= 0x04
FB_Width_Virt	= 0x08
FB_Height_Virt	= 0x0C
FB_Pitch	= 0x10
FB_Depth	= 0x14
FB_XOffset	= 0x18
FB_YOffset	= 0x1C
FB_Ptr		= 0x20
FB_Size		= 0x24

