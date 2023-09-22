/*head头文件,定义了段描述符的简单结构,和几个选择符常量*/
#ifndef _HEAD_H
#define _HEAD_H

typedef struct desc_struct {  // 段描述符结构,CPU中描述符的简单格式
	unsigned long a,b;        // 符是由8个字节构成每个描述符表共有 256 项
} desc_table[256];

extern unsigned long pg_dir[1024];
extern desc_table idt,gdt;

#define GDT_NUL 0
#define GDT_CODE 1
#define GDT_DATA 2
#define GDT_TMP 3

#define LDT_NUL 0
#define LDT_CODE 1
#define LDT_DATA 2

#endif
