#include "linux/dev_printk.h"
#include "linux/gfp_types.h"
#include "linux/irqreturn.h"
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

#define DEV_NAME			  "de1_io"

#define DTMF_REG_BASE			  0x1000
#define DTMF_MEM_BASE			  0x2000
#define DTMF_WINDOW_START_ADDR		  DTMF_MEM_BASE
#define DTMF_REF_SIGNAL_START_ADDR	  (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

#define DTMF_REG(x)			  (DTMF_REG_BASE + x)
#define DTMF_REF_SIGNAL_START_ADDR	  (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

#define DTMF_EXPECTED_ID		  0xCAFE1234

/* Read DTMF_ID from it*/
#define DTMF_ID_REG_OFFSET		  DTMF_REG(0x00)
/* Read/Write register for testing purposes */
#define DTMF_TEST_REG_OFFSET		  DTMF_REG(0x04)
/* Write the number of windows to start calculation */
#define DTMF_START_CALCULATION_REG_OFFSET DTMF_REG(0x08)
/* IRQ status register. Write equivalent bit to ack it */
#define DTMF_IRQ_STATUS_REG_OFFSET	  DTMF_REG(0x0C)
#define DTMF_DOT_PRODUCT_LOW_OFFSET	  DTMF_REG(0x10)
#define DTMF_DOT_PRODUCT_HIGH_OFFSET	  DTMF_REG(0x14)

/* Window1 start offset */
#define DTMF_WINDOW_REG_START_OFFSET	  DTMF_REG(0x100)
/* Window2 start offset */
#define DTMF_REF_WINDOW_REG_START_OFFSET  DTMF_REG(0x184)

#define DTMF_IRQ_STATUS_CALCULATION_DONE  0x01

struct dtmf_fpga_controller {
	void *mem_ptr;
	uint16_t *signal_addr_user;
	uint16_t *ref_signal_addr_user;
	struct miscdevice miscdev;
	struct device *dev;
	bool result_pending;
	uint8_t window_samples;
	bool wr_in_progress;
};

#if 0 /*Disabled as using dma hangs the CPU*/
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
	printk("MSGDMA DESCRIPTION %#x %#x %d\n", rd_addr, wr_addr, len);
	iowrite32(rd_addr, reg + MSGDMA_DESC_READ_ADDR_REG);
	iowrite32(wr_addr, reg + MSGDMA_DESC_WRITE_ADDR_REG);
	iowrite32(len, reg + MSGDMA_DESC_LEN_REG);
	iowrite32(ctrl | MSGDMA_DESC_CTRL_GO, reg + MSGDMA_DESC_CTRL_REG);
}

static int dma_transfer(struct dtmf_fpga_controller *priv, void *buffer,
			phys_addr_t dst, size_t count)
{
	enum dma_data_direction direction = DMA_TO_DEVICE;
	uint32_t flags = MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN;
	dma_addr_t dma_handle =
		dma_map_single(priv->dev, buffer, count, direction);

	if (dma_mapping_error(priv->dev, dma_handle)) {
		dev_err(priv->dev, "Failed to do dma map\n");
		return -ENOMEM;
	}

	dev_info(priv->dev, "Msgdma push descr %d %zu", dst, count);
	msgdma_push_descr(priv->mem_ptr, dma_handle, dst, count, flags);
	dev_info(priv->dev, "Starting DMA transfer");
	wait_for_completion(&priv->dma_transfer_completion);
	dev_info(priv->dev, "DMA transfer done");

	dma_unmap_single(priv->dev, dma_handle, count, direction);
	return 0;
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

static ssize_t write_from_user_to_device(struct dtmf_fpga_controller *priv,
					 const char __user *buf,
					 phys_addr_t dst, size_t count)
{
	void *dma_buffer = kmalloc(count, GFP_DMA);

	int ret = 0;
	if (!dma_buffer) {
		return -ENOMEM;
	}

	if (copy_from_user(dma_buffer, buf, count)) {
		dev_err(priv->dev, "Failed to copy data from user\n");
		kfree(dma_buffer);
		return 0;
	}
	dev_info(priv->dev,
		 "write_from_user_to_device: copy from user completed\n");

	ret = dma_transfer(priv, dma_buffer, dst, count);
	dev_info(priv->dev,
		 "write_from_user_to_device: dma_transfer completed\n");

	kfree(dma_buffer);
	if (ret < 0) {
		return ret;
	}
	dev_info(priv->dev, "write_from_user_to_device: returning count\n");
	return count;
}
#endif

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
	uint64_t result = 0;
	if (buf == NULL || count != sizeof(result)) {
		return -EINVAL;
	}
	if (priv->result_pending) {
		return -EAGAIN;
	}
	result = ((uint64_t)ioread32(priv->mem_ptr +
				     DTMF_DOT_PRODUCT_HIGH_OFFSET))
		 << 32;
	dev_info(priv->dev, "Read %llu\n", result);
	result |= ioread32(priv->mem_ptr + DTMF_DOT_PRODUCT_LOW_OFFSET);
	dev_info(priv->dev, "Read %llu\n", result);

	if (copy_to_user(buf, &result, sizeof(result))) {
		dev_err(priv->dev, "Copy to user failed\n");
		return 0;
	}
	return count;
}

static irqreturn_t irq_handler(int irq, void *dev_id)
{
	struct dtmf_fpga_controller *priv =
		(struct dtmf_fpga_controller *)dev_id;
	uint32_t irq_status =
		ioread32(priv->mem_ptr + DTMF_IRQ_STATUS_REG_OFFSET);

	dev_info(priv->dev, "IRQ\n");
	iowrite32(irq_status, priv->mem_ptr + DTMF_IRQ_STATUS_REG_OFFSET);
	priv->result_pending = false;

	return IRQ_HANDLED;
}

static int transfer_window(struct dtmf_fpga_controller *priv,
			   uint16_t *user_signal, unsigned long buffer_offset,
			   size_t register_offset)
{
	int ret;
	uint32_t sample, reg;
	uint16_t *kernel_signal;
	if (user_signal == NULL) {
		dev_err(priv->dev,
			"Trying to set window without setting user buffer");
		return -EINVAL;
	}
	if (priv->window_samples == 0) {
		dev_err(priv->dev,
			"Trying to set window without setting window size");
		return -EINVAL;
	}
	if (priv->result_pending) {
		dev_err(priv->dev,
			"Trying to set window while calculation is in progrss");
		return -EBUSY;
	}

	kernel_signal = kmalloc(priv->window_samples * sizeof(*kernel_signal),
				GFP_KERNEL);
	if (!kernel_signal) {
		dev_err(priv->dev, "Failed to allocate memory for buffer");
		return -ENOMEM;
	}
	ret = copy_from_user(kernel_signal, user_signal + buffer_offset,
			     priv->window_samples * sizeof(*kernel_signal));
	if (ret) {
		return ret;
	}
	/* Each register can hold two samples */
	sample = 0;
	reg = 0;
	for (; sample < priv->window_samples; sample += 2, reg += 4) {
		uint32_t reg_value = kernel_signal[sample + 1] << 16 |
				     kernel_signal[sample];
		iowrite32(reg_value, priv->mem_ptr + reg + register_offset);
	}
	/*If the number of samples is odd, we have one missing sample that we still need to send*/
	if (priv->window_samples & 1) {
		iowrite32(kernel_signal[sample],
			  priv->mem_ptr + reg + register_offset);
	}

	kfree(kernel_signal);

	return 0;
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
	case IOCTL_SET_WINDOW_SAMPLES:
		if (value > MAX_WINDOW_SAMPLES) {
			return -EINVAL;
		}
		priv->window_samples = value;
		dev_info(priv->dev, "Set window size: %lu\n", value);
		return 0;
	case IOCTL_SET_SIGNAL_ADDR:
		priv->signal_addr_user = (void *)value;
		dev_info(priv->dev, "Set signal addr: 0x%lx\n", value);
		return 0;
	case IOCTL_SET_REF_SIGNAL_ADDR:
		priv->ref_signal_addr_user = (void *)value;
		dev_info(priv->dev, "Set ref signal addr: 0x%lx\n", value);
		return 0;
	case IOCTL_SET_WINDOW:
		dev_info(priv->dev, "Transfer window\n");
		return transfer_window(priv, priv->signal_addr_user, value,
				       DTMF_WINDOW_REG_START_OFFSET);
	case IOCTL_SET_REF_WINDOW:
		dev_info(priv->dev, "Transfer ref window\n");
		return transfer_window(priv, priv->ref_signal_addr_user, value,
				       DTMF_REF_WINDOW_REG_START_OFFSET);
	case IOCTL_START_CALCULATION:
		dev_info(priv->dev, "Starting calculation\n");
		priv->result_pending = true;
		iowrite32(1, priv->mem_ptr + DTMF_START_CALCULATION_REG_OFFSET);
		return 0;
	case IOCTL_RESET_DEVICE:
		priv->result_pending = false;
		priv->window_samples = 0;
		iowrite32(0x1, priv->mem_ptr + DTMF_IRQ_STATUS_REG_OFFSET);
		/* Clear registers */
		for (size_t i = 0; i < MAX_WINDOW_SAMPLES / 2; i++) {
			iowrite32(0, priv->mem_ptr +
					     DTMF_REF_WINDOW_REG_START_OFFSET +
					     i);
		}
		for (size_t i = 0; i < MAX_WINDOW_SAMPLES / 2; i++) {
			iowrite32(0, priv->mem_ptr +
					     DTMF_WINDOW_REG_START_OFFSET + i);
		}
		return 0;
	default:
		return -EINVAL;
	}
	return -EINVAL;
}

static const struct file_operations fops = {
	.owner = THIS_MODULE,
	.read = on_read,
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
	uint32_t test_value = 0x12345678;
	uint32_t reg_value;
	int dtmf_interrupt;
#if 0
	int dma_interrupt = platform_get_irq(pdev, 0);

	if (dma_interrupt < 0) {
		dev_err(&pdev->dev, "Failed to get DMA interrupt");
		return dma_interrupt;
	}
#endif
	dtmf_interrupt = platform_get_irq(pdev, 0);
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

#if 0
	if (devm_request_irq(&pdev->dev, dma_interrupt, msgdma_irq_handler, 0,
			     "dma_transfer", priv) < 0) {
		return -EBUSY;
	}
#endif
	if (devm_request_irq(&pdev->dev, dtmf_interrupt, irq_handler, 0,
			     "fpga_calculation", priv) < 0) {
		return -EBUSY;
	}

#if 0
	ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(32));
	BUG_ON(ret);
#endif

	/* Setup dev and miscdev */
	platform_set_drvdata(pdev, priv);
	priv->dev = &pdev->dev;
	priv->miscdev = (struct miscdevice){
		.minor = MISC_DYNAMIC_MINOR,
		.name = DEV_NAME,
		.fops = &fops,
	};
	priv->result_pending = false;

#if 0
	init_completion(&priv->dma_transfer_completion);
#endif

	/* Setup Memory related stuff */
	/* 
	 * First, get the reg node so we can calculate 
	 * the number of registers 
	 */
	iores = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	BUG_ON(!iores);

	/* Now use the devm function so we don't need to handle unmaping the memory pointer */
	priv->mem_ptr = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(priv->mem_ptr)) {
		dev_err(&pdev->dev, "Failed to remap memory");
		ret = PTR_ERR(priv->mem_ptr);
		goto return_fail;
	}

#if 0
	msgdma_reset(priv->mem_ptr);
#endif

	/* Do some sanity checks to make sure connection with our IP is ok*/
	reg_value = ioread32(priv->mem_ptr + DTMF_ID_REG_OFFSET);
	if (reg_value != DTMF_EXPECTED_ID) {
		dev_err(&pdev->dev,
			"Failed to read correct id. Expected %#08x but got %#08x\n",
			DTMF_EXPECTED_ID, reg_value);
		return -EIO;
	}

	iowrite32(test_value, priv->mem_ptr + DTMF_TEST_REG_OFFSET);
	reg_value = ioread32(priv->mem_ptr + DTMF_TEST_REG_OFFSET);
	if (reg_value != test_value) {
		dev_err(&pdev->dev,
			"Error: Read/Write test failed. Expected %#08x but got %#08x\n",
			test_value, reg_value);
		return -EIO;
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
