#include "asm-generic/io.h"
#include "linux/completion.h"
#include "linux/dev_printk.h"
#include "linux/dma-direction.h"
#include "linux/gfp_types.h"
#include <linux/err.h>
#include "access.h"
#include <linux/miscdevice.h> /* Needed for misc_register */
#include <linux/leds.h>
#include <linux/of.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/io.h>
#include <linux/workqueue.h>
#include <linux/math64.h>
#include <linux/workqueue.h>
#include <linux/fs.h> /* Needed for file_operations */
#include <linux/dma-mapping.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("André Costa");
MODULE_DESCRIPTION("FPGA DTMF Controller");

#define DEV_NAME		   "de1_io"

#define DTMF_WINDOW_START_ADDR	   0x40
#define DTMF_REF_SIGNAL_START_ADDR (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)
#define DTMF_REG(x)                                    \
	(DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE + \
	 REF_SIGNALS_REGION_SIZE + x)

#define DTMF_REF_SIGNAL_START_ADDR	    (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

/* Write the number of windows to start calculation */
#define DTMF_START_CALCULATION_REG_OFFSET   DTMF_REG(0x00)
/* Contains the window size in bytes. Each sample is 2 bytes */
#define DTMF_WINDOW_SIZE_REG_OFFSET	    DTMF_REG(0x04)
/* Contains the number of windows */
#define DTMF_WINDOW_NUMBER_REG_OFFSET	    DTMF_REG(0x08)
/* IRQ status register. Write equivalent bit to ack it */
#define DTMF_IRQ_STATUS_REG_OFFSET	    DTMF_REG(0x10)
/* Window result start offset. We should have 8 registers here */
#define DTMF_WINDOW_RESULT_REG_START_OFFSET DTMF_REG(0x20)

#define DTMF_IRQ_STATUS_CALCULATION_DONE    0x01

#define MSGDMA_CSR_STATUS_REG		    0x00
#define MSGDMA_CSR_CTRL_REG		    0x04
#define MSGDMA_CSR_FILL_LVL_REG		    0x08
#define MSGDMA_CSR_RESP_FILL_LVL_REG	    0x0C
#define MSGDMA_CSR_SEQ_NUM_REG		    0x10
#define MSGDMA_CSR_COMP_CONFIG1_REG	    0x14
#define MSGDMA_CSR_COMP_CONFIG2_REG	    0x18
#define MSGDMA_CSR_COMP_INFO_REG	    0x1C
#define MSGDMA_DESC_READ_ADDR_REG	    0x20
#define MSGDMA_DESC_WRITE_ADDR_REG	    0x24
#define MSGDMA_DESC_LEN_REG		    0x28
#define MSGDMA_DESC_CTRL_REG		    0x2C
#define MSGDMA_RESP_BYTES_TRANSFERRED_REG   0x30
#define MSGDMA_RESP_STATUS_REG		    0x34

#define MSGDMA_STATUS_IRQ		    (1 << 9)
#define MSGDMA_STATUS_STOPPED_EARLY_TERM    (1 << 8)
#define MSGDMA_STATUS_STOPPED_ON_ERR	    (1 << 7)
#define MSGDMA_STATUS_RESETTING		    (1 << 6)
#define MSGDMA_STATUS_STOPPED		    (1 << 5)
#define MSGDMA_STATUS_RESP_BUF_FULL	    (1 << 4)
#define MSGDMA_STATUS_RESP_BUF_EMPTY	    (1 << 3)
#define MSGDMA_STATUS_DESCR_BUF_FULL	    (1 << 2)
#define MSGDMA_STATUS_DESCR_BUF_EMTPY	    (1 << 1)
#define MSGDMA_STATUS_BUSY		    (1 << 0)

#define MSGDMA_CONTROL_STOP_DESCR	    (1 << 5)
#define MSGDMA_CONTROL_GLOBAL_INT_EN_MASK   (1 << 4)
#define MSGDMA_CONTROL_STOP_ON_EARLY_TERM   (1 << 3)
#define MSGDMA_CONTROL_STOP_ON_ERROR	    (1 << 2)
#define MSGDMA_CONTROL_RESET_DISPATCHER	    (1 << 1)
#define MSGDMA_CONTROL_STOP_DISPATCHER	    (1 << 0)

#define MSGDMA_DESC_CTRL_GO		    (1 << 31)
#define MSGDMA_DESC_CTRL_EARLY_DONE_EN	    (1 << 24)
#define MSGDMA_DESC_CTRL_TX_ERR_IRQ_EN	    (1 << 16)
#define MSGDMA_DESC_CTRL_EARLY_TERM_IRQ_EN  (1 << 15)
#define MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN (1 << 14)
#define MSGDMA_DESC_CTRL_END_ON_EOP	    (1 << 12)
#define MSGDMA_DESC_CTRL_PARK_WR	    (1 << 11)
#define MSGDMA_DESC_CTRL_PARK_RD	    (1 << 10)
#define MSGDMA_DESC_CTRL_GEN_EOP	    (1 << 9)
#define MSGDMA_DESC_CTRL_GEN_SOP	    (1 << 8)

struct dtmf_fpga_controller {
	void *mem_ptr;
	void *signal_addr;
	size_t current_window_offset;
	struct miscdevice miscdev;
	struct device *dev;
	uint8_t mode;
	uint32_t reg_count;
	struct completion calculation_completion;
	struct completion dma_transfer_completion;
	uint32_t curr_window_size;
	bool wr_in_progress;
	uint8_t *results;
};
static void msgdma_reset(void *reg)
{
	uint32_t ctrl = ioread32(reg + MSGDMA_CSR_CTRL_REG);
	iowrite32(ctrl | MSGDMA_CONTROL_RESET_DISPATCHER,
		  reg + MSGDMA_CSR_CTRL_REG);

	while (ioread32(reg + MSGDMA_CSR_STATUS_REG) & MSGDMA_STATUS_RESETTING)
		;
}

static void msgdma_push_descr(void *reg, dma_addr_t rd_addr,
			      phys_addr_t wr_addr, uint32_t len, uint32_t ctrl)
{
	iowrite32(rd_addr, reg + MSGDMA_DESC_READ_ADDR_REG);
	iowrite32(wr_addr, reg + MSGDMA_DESC_WRITE_ADDR_REG);
	iowrite32(len, reg + MSGDMA_DESC_LEN_REG);
	iowrite32(ctrl | MSGDMA_DESC_CTRL_GO, reg + MSGDMA_DESC_CTRL_REG);
}

static int dma_transfer(struct dtmf_fpga_controller *priv, void *buffer,
			phys_addr_t dst, size_t count, bool is_last)
{
	enum dma_data_direction direction = DMA_TO_DEVICE;
	uint32_t flags = is_last ? MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN : 0;
	dma_addr_t dma_handle =
		dma_map_single(priv->dev, buffer, count, direction);

	if (dma_mapping_error(priv->dev, dma_handle)) {
		dev_err(priv->dev, "Failed to do dma map\n");
		return -ENOMEM;
	}
	dev_info(priv->dev, "Starting DMA transfer");

	msgdma_push_descr(priv->mem_ptr, dma_handle, dst, count, flags);
	if (is_last) {
		wait_for_completion(&priv->dma_transfer_completion);
		dev_info(priv->dev, "DMA transfer done");
	}
	dma_unmap_single(priv->dev, dma_handle, count, direction);
	return 0;
}

/**
 * @brief Device file read callback to read the value of the selected register.
 *
 * @param filp  File structure of the char device from which the value is read.
 * @param buf   Userspace buffer to which the value will be copied.
 * @param count Number of available bytes in the userspace buffer.
 * @param ppos  Current cursor position in the file (ignored).
 *
 * @return Number of bytes written in the userspace buffer or 0 if we couldn't
 * write every byte.
 */
static ssize_t on_read(struct file *filp, char __user *buf, size_t count,
		       loff_t *ppos)
{
	struct dtmf_fpga_controller *priv = container_of(
		filp->private_data, struct dtmf_fpga_controller, miscdev);
	uint8_t *result = kmalloc(count, GFP_KERNEL);
	if (!result) {
		return -ENOMEM;
	}

	while (ioread32(priv->mem_ptr + MSGDMA_CSR_STATUS_REG) &
	       MSGDMA_STATUS_BUSY)
		;

	dev_info(priv->dev, "Starting calculation for %zu windows", count);
	iowrite32(count, priv->mem_ptr + DTMF_START_CALCULATION_REG_OFFSET);
	wait_for_completion(&priv->calculation_completion);
	dev_info(priv->dev, "Calculation done");

	for (size_t i = 0; i < count; ++i) {
		uint32_t reg =
			ioread32(priv->mem_ptr +
				 DTMF_WINDOW_RESULT_REG_START_OFFSET + (i * 4));
		result[i] = (uint8_t)reg;
	}

	if (copy_to_user(buf, &result, count)) {
		dev_err(priv->dev, "Copy to user failed\n");
		return 0;
	}

	return count;
}

static irqreturn_t msgdma_irq_handler(int irq, void *dev_id)
{
	struct dtmf_fpga_controller *priv =
		(struct dtmf_fpga_controller *)dev_id;

	if (ioread32(priv->mem_ptr + MSGDMA_CSR_STATUS_REG) &
	    MSGDMA_STATUS_IRQ) {
		const uint32_t value =
			ioread32(priv->mem_ptr + MSGDMA_CSR_STATUS_REG);
		iowrite32(value | MSGDMA_STATUS_IRQ,
			  priv->mem_ptr + MSGDMA_CSR_STATUS_REG);
		complete(&priv->dma_transfer_completion);
	}

	return IRQ_HANDLED;
}

static irqreturn_t irq_handler(int irq, void *dev_id)
{
	struct dtmf_fpga_controller *priv =
		(struct dtmf_fpga_controller *)dev_id;
	uint32_t irq_status =
		ioread32(priv->mem_ptr + DTMF_IRQ_STATUS_REG_OFFSET);

	if (irq_status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
		complete(&priv->calculation_completion);
	}

	iowrite32(irq_status, priv->mem_ptr + DTMF_IRQ_STATUS_REG_OFFSET);

	return IRQ_HANDLED;
}

static ssize_t write_from_user_to_device(struct dtmf_fpga_controller *priv,
					 const char __user *buf,
					 phys_addr_t dst, size_t count)
{
	void *dma_buffer = kmalloc(count, GFP_DMA);
	int ret = 0;
	if (!dma_buffer) {
		return -ENOMEM;
	}

	if (copy_from_user(&dma_buffer, buf, count)) {
		dev_err(priv->dev, "Failed to copy data from user\n");
		kfree(dma_buffer);
		return 0;
	}

	ret = dma_transfer(priv, dma_buffer, dst, count, true);

	kfree(dma_buffer);
	if (ret < 0) {
		return ret;
	}

	return count;
}

/**
 * @brief Device file write callback to write a value to the selected register.
 *
 * @param filp  File structure of the char device from which the value is read.
 * @param buf   Userspace buffer to which the value will be copied.
 * @param count Number of available bytes in the userspace buffer.
 * @param ppos  Current cursor position in the file (ignored).
 *
 * @return Number of bytes written to the register.
 */
static ssize_t on_write(struct file *filp, const char __user *buf, size_t count,
			loff_t *ppos)
{
	struct dtmf_fpga_controller *priv = container_of(
		filp->private_data, struct dtmf_fpga_controller, miscdev);

	if (buf == NULL || count == 0) {
		return count;
	}
	if (count > REF_SIGNALS_REGION_SIZE) {
		return -EINVAL;
	}

	return write_from_user_to_device(priv, buf, DTMF_REF_SIGNAL_START_ADDR,
					 count);
}

static int transfer_window_from_user(struct dtmf_fpga_controller *priv,
				     void *user_buf, bool is_last)
{
	int ret;
	size_t offset;
	if (priv->curr_window_size == 0) {
		dev_err(priv->dev,
			"Trying to set window without setting window size");
		return -EINVAL;
	}
	if (priv->current_window_offset + priv->curr_window_size >=
	    WINDOW_REGION_SIZE) {
		dev_err(priv->dev, "Too many windows pushed");
		return -ENOMEM;
	}
	ret = copy_from_user(&offset, user_buf, sizeof(offset));
	if (ret) {
		return ret;
	}
	return dma_transfer(priv, priv->signal_addr + offset,
			    priv->current_window_offset +
				    DTMF_WINDOW_START_ADDR,
			    priv->curr_window_size, is_last);
}
/**
 * @brief Device file ioctl callback. This is used to select the register that can
 * then be written or read using the read and write callbacks.
 *
 * @param filp File structure of the char device to which ioctl is performed.
 * @param cmd  Command value of the ioctl
 * @param arg  Optionnal argument of the ioctl
 *
 * @return 0 if ioctl succeed, -EINVAL otherwise.
 */
static long on_ioctl(struct file *filp, unsigned int code, unsigned long value)
{
	struct dtmf_fpga_controller *priv = container_of(
		filp->private_data, struct dtmf_fpga_controller, miscdev);
	int ret;

	dev_info(priv->dev, "IOCTL %d %lu \n", code, value);

	switch (code) {
	case IOCTL_SET_WINDOW_SIZE:
		priv->curr_window_size = value;
		iowrite32(value, priv->mem_ptr + DTMF_WINDOW_SIZE_REG_OFFSET);
		return 0;
	case IOCTL_SET_SIGNAL_ADDR:
		priv->signal_addr = (void *)value;
		return 0;
	case IOCTL_SET_WINDOW:
		return transfer_window_from_user(priv, (void *)value, false);
	case IOCTL_SET_LAST_WINDOW:
		ret = transfer_window_from_user(priv, (void *)value, true);
		priv->current_window_offset = 0;
		if (ret) {
			return ret;
		}
		return ret;
	default:
		return -EINVAL;
	}
	return -EINVAL;
}

static const struct file_operations fops = {
	.owner = THIS_MODULE,
	.read = on_read,
	.write = on_write,
	.unlocked_ioctl = on_ioctl,
};

/**
 * access_probe - Probe function of the platform driver.
 * @pdev:	Pointer to the platform device structure.
 * Return: 0 on success, negative error code on failure.
 */
static int access_probe(struct platform_device *pdev)
{
	int ret;
	struct resource *iores;
	uint32_t total_size = 0;
	int dma_interrupt = platform_get_irq(pdev, 0);
	int dtmf_interrupt = platform_get_irq(pdev, 1);

	if (dma_interrupt < 0) {
		dev_err(&pdev->dev, "Failed to get DMA interrupt");
		return dma_interrupt;
	}
	if (dtmf_interrupt < 0) {
		dev_err(&pdev->dev, "Failed to get DTMF interrupt");
		return dtmf_interrupt;
	}

	struct dtmf_fpga_controller *priv =
		devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);

	if (unlikely(!priv)) {
		dev_err(&pdev->dev,
			"Failed to allocate memory for private data\n");
		return -ENOMEM;
	}
	priv->signal_addr = kmalloc(WINDOW_REGION_SIZE, GFP_KERNEL);
	if (!priv->signal_addr) {
		dev_err(&pdev->dev,
			"Failed to allocate memory for window pool\n");
		return -ENOMEM;
	}

	if (devm_request_irq(&pdev->dev, dma_interrupt, msgdma_irq_handler, 0,
			     "dma_transfer", priv) < 0) {
		return -EBUSY;
	}

	if (devm_request_irq(&pdev->dev, dtmf_interrupt, irq_handler, 0,
			     "fpga_calculation", priv) < 0) {
		return -EBUSY;
	}

	ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(32));
	BUG_ON(ret);
	/* Setup dev and miscdev */
	platform_set_drvdata(pdev, priv);
	priv->dev = &pdev->dev;
	priv->miscdev = (struct miscdevice){
		.minor = MISC_DYNAMIC_MINOR,
		.name = DEV_NAME,
		.fops = &fops,
	};

	init_completion(&priv->calculation_completion);
	init_completion(&priv->dma_transfer_completion);
	msgdma_reset(priv->mem_ptr);

	/* Setup Memory related stuff */
	/* 
	 * First, get the reg node so we can calculate 
	 * the number of registers 
	 */
	iores = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	BUG_ON(!iores);

	total_size = iores->end - iores->start + 1;

	priv->reg_count = total_size / sizeof(uint32_t);

	/* Now use the devm function so we don't need to handle unmaping the memory pointer */
	priv->mem_ptr = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(priv->mem_ptr)) {
		dev_err(&pdev->dev, "Failed to remap memory");
		ret = PTR_ERR(priv->mem_ptr);
		goto return_fail;
	}

	dev_info(&pdev->dev, "Acess probe successful!");
	return misc_register(&priv->miscdev);

return_fail:
	/* No need to free priv as it's device managed */
	return ret;
}

/**
 * access_remove - Remove function of the platform driver.
 * @pdev:	Pointer to the platform device structure.
 */
static void acess_remove(struct platform_device *pdev)
{
	struct dtmf_fpga_controller *priv = platform_get_drvdata(pdev);

	kfree(priv->signal_addr);
	misc_deregister(&priv->miscdev);
	dev_info(&pdev->dev, "Access remove!");
}

/* Instanciate the list of supported devices */
static const struct of_device_id access_id[] = {
	{ .compatible = DEV_NAME },
	{ /* END */ },
};
MODULE_DEVICE_TABLE(of, access_id);

/* Instanciate the platform driver for this driver */
static struct platform_driver access_driver = {
	.driver = {
		.name = DEV_NAME,
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(access_id),
	},
	.probe = access_probe,
	.remove = acess_remove,
};

/*
 * As init and exit function only have to register and unregister the
 * platform driver, we can use this helper macros that will automatically
 * create the functions.
 */
module_platform_driver(access_driver);
