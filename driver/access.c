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

MODULE_LICENSE("GPL");
MODULE_AUTHOR("André Costa");
MODULE_DESCRIPTION("AXI Lite Slave Controller");

#define DEV_NAME "de1_io"

struct axi_slave_controller {
	void *mem_ptr;
	struct miscdevice miscdev;
	struct device *dev;
	uint8_t selected_offset;
	uint32_t reg_count;
};

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
	struct axi_slave_controller *priv = container_of(
		filp->private_data, struct axi_slave_controller, miscdev);
	uint32_t reg_value = 0;

	printk("Read %p %zu %zu\n", buf, count, sizeof(reg_value));

	if (buf == NULL || count < sizeof(reg_value)) {
		return 0;
	}

	reg_value = ioread32(priv->mem_ptr + priv->selected_offset);

	if (copy_to_user(buf, &reg_value, sizeof(reg_value))) {
		printk("Copy to user failed\n");
		return 0;
	}
	return sizeof(reg_value);
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
	struct axi_slave_controller *priv = container_of(
		filp->private_data, struct axi_slave_controller, miscdev);
	uint32_t reg_value = 0;

	if (buf == NULL || count < sizeof(reg_value)) {
		return 0;
	}

	if (copy_from_user(&reg_value, buf, sizeof(reg_value))) {
		return 0;
	}

	iowrite32(reg_value, priv->mem_ptr + priv->selected_offset);

	return sizeof(reg_value);
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
	struct axi_slave_controller *priv = container_of(
		filp->private_data, struct axi_slave_controller, miscdev);

	printk("IOCTL %d %lu \n", code, value);

	if (code != IOCTL_ACCESS_SELECT_REGISTER) {
		return -EINVAL;
	}

	if (value >= priv->reg_count) {
		return -EINVAL;
	}
	priv->selected_offset = value * sizeof(uint32_t);
	return 0;
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

	struct axi_slave_controller *priv =
		devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);

	if (unlikely(!priv)) {
		dev_err(&pdev->dev,
			"Failed to allocate memory for private data\n");
		ret = -ENOMEM;
		goto return_fail;
	}

	/* Setup dev and miscdev */
	platform_set_drvdata(pdev, priv);
	priv->dev = &pdev->dev;
	priv->miscdev = (struct miscdevice){
		.minor = MISC_DYNAMIC_MINOR,
		.name = DEV_NAME,
		.fops = &fops,
	};

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
	// Retrieve the private data from the platform device
	struct axi_slave_controller *priv = platform_get_drvdata(pdev);
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
