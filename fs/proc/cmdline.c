#include <linux/fs.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <asm/setup.h>

static char new_command_line[COMMAND_LINE_SIZE];

static int cmdline_proc_show(struct seq_file *m, void *v)
{
	seq_printf(m, "%s\n", new_command_line);
	return 0;
}

static int cmdline_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, cmdline_proc_show, NULL);
}

static const struct file_operations cmdline_proc_fops = {
	.open		= cmdline_proc_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int __init proc_cmdline_init(void)
{
	char *offset_addr, *cmd = new_command_line;

	strcpy(cmd, saved_command_line);

	/*
	 * Remove 'androidboot.' "bad" or duplicated flags from command line seen
	 * by userspace in order to pass SafetyNet CTS check.
	 */
	offset_addr = strstr(cmd, "androidboot.bl_state=2");
	if (offset_addr) {
		size_t i, len, offset;

		len = strlen(cmd);
		offset = offset_addr - cmd;
		for (i = 1; i < (len - offset); i++) {
			if (cmd[offset + i] == ' ') {
				break;
			}
		}

		/*
		 * if ((len - i - offset) == 0) argument is the last and have no space after
		* when that happens add a space before the argument just to remove it
		 */
		if ((len - i - offset) == 0) {
			offset_addr = strstr(cmd, " androidboot.bl_state=2");
			len = strlen(cmd);
			offset = offset_addr - cmd;
			i = i + 1;
			memmove(offset_addr, &cmd[offset + i + (i - 3)], i);
		} else {
			memmove(offset_addr, &cmd[offset + i + 1], len - i - offset);
		}
	}

	offset_addr = strstr(cmd, "androidboot.flash.locked=0");
	if (offset_addr) {
		size_t i, len, offset;

		len = strlen(cmd);
		offset = offset_addr - cmd;
		for (i = 1; i < (len - offset); i++) {
			if (cmd[offset + i] == ' ') {
				break;
			}
		}
		/*
		 * if ((len - i - offset) == 0) argument is the last and have no space after
		* when that happens add a space before the argument just to remove it
		 */
		if ((len - i - offset) == 0) {
			offset_addr = strstr(cmd, " androidboot.flash.locked=0");
			len = strlen(cmd);
			offset = offset_addr - cmd;
			i = i + 1;
			memmove(offset_addr, &cmd[offset + i + (i - 3)], i);
		} else {
			memmove(offset_addr, &cmd[offset + i + 1], len - i - offset);
		}
	}

	proc_create("cmdline", 0, NULL, &cmdline_proc_fops);
	return 0;
}
module_init(proc_cmdline_init);
