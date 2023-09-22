/*
 *  linux/lib/_exit.c
 *
 *  (C) 1991  Linus Torvalds
 *  ÍË³öº¯Êý
 */

#define __LIBRARY__
#include <unistd.h>

volatile void _exit(int exit_code)
{
	__asm__("int $0x80"::"a" (__NR_exit),"b" (exit_code));
}
