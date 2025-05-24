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

#define DEV_NAME			 "de1_io"

/* Write the number of windows to start calculation */
#define START_CALCULATION_REG_OFFSET	 0x00
/* Contains the window size in bytes. Each sample is 2 bytes */
#define WINDOW_SIZE_REG_OFFSET		 0x04
/* Contains the number of windows */
#define WINDOW_NUMBER_REG_OFFSET	 0x08
/* IRQ status register. Write equivalent bit to ack it. See */
#define IRQ_STATUS_REG_OFFSET		 0x10
/* DMA transfer address */
#define DMA_ADDR_REG_OFFSET		 0x14
/* DMA transfer size */
#define DMA_SIZE_REG_OFFSET		 0x18
/* Write one of DMA_TRANSFER_TYPE_XXX to start specific transfer*/
#define DMA_START_TRANSFER_REG_OFFSET	 0x1C

#define DMA_TRANSFER_TYPE_REF_SIGNALS	 0x1
#define DMA_TRANSFER_TYPE_WINDOWS	 0x2
#define DMA_TRANSFER_TYPE_WINDOW_RESULTS 0x3

#define IRQ_STATUS_DMA_TRANSFER_DONE	 0x1
#define IRQ_STATUS_CALCULATION_DONE	 0x2

struct dtmf_fpga_controller {
	void *mem_ptr;
	uint8_t *window_pool;
	size_t window_pool_offset;
	struct miscdevice miscdev;
	struct device *dev;
	uint8_t mode;
	uint32_t reg_count;
	struct completion calculation_completion;
	struct completion dma_transfer_completion;
	uint32_t curr_window_size;
};

static int dma_transfer(struct dtmf_fpga_controller *priv, void *buffer,
			size_t count, bool to_device, uint32_t transfer_type)
{
	enum dma_data_direction direction = to_device ? DMA_TO_DEVICE :
							DMA_FROM_DEVICE;
	dma_addr_t dma_handle =
		dma_map_single(priv->dev, buffer, count, direction);

	if (dma_mapping_error(priv->dev, dma_handle)) {
		dev_err(priv->dev, "Failed to do dma map\n");
		return -ENOMEM;
	}
	dev_info(priv->dev, "Starting DMA transfer");

	iowrite32(dma_handle, priv->mem_ptr + DMA_ADDR_REG_OFFSET);
	iowrite32(count, priv->mem_ptr + DMA_SIZE_REG_OFFSET);
	iowrite32(transfer_type, priv->mem_ptr + DMA_START_TRANSFER_REG_OFFSET);

	wait_for_completion(&priv->dma_transfer_completion);
	dev_info(priv->dev, "DMA transfer done");

	dma_unmap_single(priv->dev, dma_handle, count, direction);
	return 0;
}

static ssize_t read_from_device_to_user(struct dtmf_fpga_controller *priv,
					char __user *buf, size_t count,
					uint32_t transfer_type)
{
	void *dma_buffer = kmalloc(count, GFP_KERNEL);
	int ret = 0;
	if (!dma_buffer) {
		return -ENOMEM;
	}

	ret = dma_transfer(priv, dma_buffer, count, false, transfer_type);
	if (ret < 0) {
		kfree(dma_buffer);
		return ret;
	}

	if (copy_to_user(buf, dma_buffer, count)) {
		dev_err(priv->dev, "Failed to copy data from user\n");
		kfree(dma_buffer);
		return 0;
	}

	kfree(dma_buffer);
	return count;
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
	int ret;

	if (!result) {
		return 0;
	}

	dev_info(priv->dev, "Transfering windows\n");
	ret = dma_transfer(priv, priv->window_pool, priv->window_pool_offset,
			   true, DMA_TRANSFER_TYPE_WINDOWS);
	priv->window_pool_offset = 0;

	wait_for_completion(&priv->dma_transfer_completion);

	dev_info(priv->dev, "Starting calculation\n");
	iowrite32(count, priv->mem_ptr + START_CALCULATION_REG_OFFSET);

	wait_for_completion(&priv->calculation_completion);

	dev_info(priv->dev, "Result ready!\n");
	read_from_device_to_user(priv, buf, count,
				 DMA_TRANSFER_TYPE_WINDOW_RESULTS);

	if (copy_to_user(buf, &result, count)) {
		dev_err(priv->dev, "Copy to user failed\n");
		return 0;
	}

	return count;
}

static irqreturn_t irq_handler(int irq, void *dev_id)
{
	struct dtmf_fpga_controller *priv =
		(struct dtmf_fpga_controller *)dev_id;
	uint32_t irq_status = ioread32(priv->mem_ptr + IRQ_STATUS_REG_OFFSET);

	if (irq_status & IRQ_STATUS_DMA_TRANSFER_DONE) {
		complete(&priv->dma_transfer_completion);
	}
	if (irq_status & IRQ_STATUS_CALCULATION_DONE) {
		complete(&priv->calculation_completion);
	}

	iowrite32(irq_status, priv->mem_ptr + IRQ_STATUS_REG_OFFSET);

	return IRQ_HANDLED;
}

static ssize_t write_from_user_to_device(struct dtmf_fpga_controller *priv,
					 const char __user *buf, size_t count,
					 uint32_t transfer_type)
{
	void *dma_buffer = kmalloc(count, GFP_KERNEL);
	int ret = 0;
	if (!dma_buffer) {
		return -ENOMEM;
	}

	if (copy_from_user(&dma_buffer, buf, count)) {
		dev_err(priv->dev, "Failed to copy data from user\n");
		kfree(dma_buffer);
		return 0;
	}

	ret = dma_transfer(priv, dma_buffer, count, true, transfer_type);

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

	switch (priv->mode) {
	case IOCTL_MODE_SET_REFERENCE_SIGNALS:
		if (count > REF_SIGNALS_REGION_SIZE) {
			return -EINVAL;
		}
		return write_from_user_to_device(priv, buf, count,
						 DMA_TRANSFER_TYPE_REF_SIGNALS);
	case IOCTL_MODE_SET_WINDOWS:
		if (count + priv->window_pool_offset > WINDOW_REGION_SIZE) {
			return -EINVAL;
		}
		int ret = copy_from_user(priv->window_pool +
						 priv->window_pool_offset,
					 buf, count);
		if (ret == 0) {
			priv->window_pool_offset += count;
		}
		return ret;
	default:
		return 0;
	}
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

	dev_info(priv->dev, "IOCTL %d %lu \n", code, value);

	switch (code) {
	case IOCTL_SET_MODE:
		if (!(value == IOCTL_MODE_SET_REFERENCE_SIGNALS ||
		      value == IOCTL_MODE_SET_WINDOWS)) {
			return -EINVAL;
		}
		priv->mode = value;
		return 0;
	case IOCTL_SET_WINDOW_SIZE:
		iowrite32(value, priv->mem_ptr + WINDOW_SIZE_REG_OFFSET);
		return 0;
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
	int btn_interrupt = platform_get_irq(pdev, 0);

	if (btn_interrupt < 0) {
		return btn_interrupt;
	}

	struct dtmf_fpga_controller *priv =
		devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);

	if (unlikely(!priv)) {
		dev_err(&pdev->dev,
			"Failed to allocate memory for private data\n");
		return -ENOMEM;
	}
	priv->window_pool = kmalloc(WINDOW_REGION_SIZE, GFP_KERNEL);
	if (!priv->window_pool) {
		dev_err(&pdev->dev,
			"Failed to allocate memory for window pool\n");
		return -ENOMEM;
	}

	if (devm_request_irq(&pdev->dev, btn_interrupt, irq_handler, 0,
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

	kfree(priv->window_pool);
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
