#ifndef ACCESS_H
#define ACCESS_H

#define IOCTL_SET_WINDOW_SIZE		       0
#define IOCTL_SET_SIGNAL_ADDR		       1
#define IOCTL_SET_REF_SIGNAL_ADDR	       2
#define IOCTL_SET_WINDOW		       3

#define IOCTL_MODE_SET_REFERENCE_SIGNALS       1
#define IOCTL_MODE_SET_WINDOWS		       2

#define DTMF_REG_BASE			       0x1000
#define DTMF_MEM_BASE			       0x2000
#define DTMF_WINDOW_START_ADDR		       DTMF_MEM_BASE
#define DTMF_REF_SIGNAL_START_ADDR	       (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

#define DTMF_REG(x)			       (DTMF_REG_BASE + x)
#define DTMF_REF_SIGNAL_START_ADDR	       (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

#define DTMF_EXPECTED_ID		       0xCAFE1234

/* Read DTMF_ID from it*/
#define DTMF_ID_REG_OFFSET		       DTMF_REG(0x00)
/* Read/Write register for testing purposes */
#define DTMF_TEST_REG_OFFSET		       DTMF_REG(0x04)
/* Write the number of windows to start calculation */
#define DTMF_START_CALCULATION_REG_OFFSET      DTMF_REG(0x08)
/* IRQ status register. Write equivalent bit to ack it */
#define DTMF_IRQ_STATUS_REG_OFFSET	       DTMF_REG(0x0C)
/* Dot product result register. Merge the 2 of them, to have the 64 bit result*/
#define DTMF_DOT_PRODUCT_LOW_OFFSET	           DTMF_REG(0x10)
#define DTMF_DOT_PRODUCT_HIGH_OFFSET	       DTMF_REG(0x14)

/* Window1 start offset */
#define DTMF_WINDOW_REG_START_OFFSET(n)	       DTMF_REG(0x100 + (n * 4))
/* Window2 start offset */
#define DTMF_REF_REG_START_OFFSET(n)	       DTMF_REG(0x184 + (n * 4))

#define DTMF_IRQ_STATUS_CALCULATION_DONE       0x01
