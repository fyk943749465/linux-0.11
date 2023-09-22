/*
 *  linux/lib/execve.c
 *
 *  (C) 1991  Linus Torvalds
 *  Ö´ÐÐ³ÌÐòº¯Êý
 */

#define __LIBRARY__
#include <unistd.h>

_syscall3(int,execve,const char *,file,char **,argv,char **,envp)
