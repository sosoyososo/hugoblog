---
title: 'Objc load方法怎么被调用？(五)'
date: Fri, 13 Oct 2017 18:55:54 +0000
draft: false
tags: ['iOS', 'Objective-C']
---

现在是时候看看 getsectiondata 是如何获取内容的了，这个函数属于apple开源代码 cctool 中libmacho代码的一部分，这里只看一下64为的版本：
```

uint8\_t \* 
getsectiondata(
const struct mach\_header \*mhp,
const char \*segname,
const char \*sectname,
unsigned long \*size)
{
    struct segment\_command \*sgp;
    struct section \*sp;
    uint32\_t i, j;
    intptr\_t slide;
    
    slide = 0;
    sp = 0;
    sgp = (struct segment\_command \*)
          ((char \*)mhp + sizeof(struct mach\_header));
    for(i = 0; i < mhp->ncmds; i++){
        if(sgp->cmd == LC\_SEGMENT){
        if(strcmp(sgp->segname, "\_\_TEXT") == 0){
            slide = (uintptr\_t)mhp - sgp->vmaddr;
        }
        if(strncmp(sgp->segname, segname, sizeof(sgp->segname)) == 0){
            sp = (struct section \*)((char \*)sgp +
             sizeof(struct segment\_command));
            for(j = 0; j < sgp->nsects; j++){
            if(strncmp(sp->sectname, sectname,
               sizeof(sp->sectname)) == 0 &&
               strncmp(sp->segname, segname,
               sizeof(sp->segname)) == 0){
                \*size = sp->size;
                return((uint8\_t \*)(sp->addr) + slide);
            }
            sp = (struct section \*)((char \*)sp +
                 sizeof(struct section));
            }
        }
        }
        sgp = (struct segment\_command \*)((char \*)sgp + sgp->cmdsize);
    }
    return(0);
}

struct section\_64 { /\* for 64-bit architectures \*/
    char        sectname\[16\];   /\* name of this section \*/
    char        segname\[16\];    /\* segment this section goes in \*/
    uint64\_t    addr;       /\* memory address of this section \*/
    uint64\_t    size;       /\* size in bytes of this section \*/
    uint32\_t    offset;     /\* file offset of this section \*/
    uint32\_t    align;      /\* section alignment (power of 2) \*/
    uint32\_t    reloff;     /\* file offset of relocation entries \*/
    uint32\_t    nreloc;     /\* number of relocation entries \*/
    uint32\_t    flags;      /\* flags (section type and attributes)\*/
    uint32\_t    reserved1;  /\* reserved (for offset or index) \*/
    uint32\_t    reserved2;  /\* reserved (for count or sizeof) \*/
    uint32\_t    reserved3;  /\* reserved \*/
};

```
这里我们知道返回了section addr指向位置的一段内存指针即可。那么加载到内存中的又是什么东西呢？这部分指向的又是什么？我们下一小结继续解说。