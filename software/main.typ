= 关于 bit 操作：

```rust
num.bits(range).set()
// num 需要是可修改的。
num.bits(range).write(value)
num.bits(range).read()
```

由于 num 需要两种状态: `&mut` 和 `&`，因此 `bits(range)` 需要是一个 trait 中的方法。

= 关于额外的描述性语言：

通常在 C 语言中，可以方便得使用 bit field 来描述一个寄存器，或者某些非字节对齐得字段。
但是 bit field 并不是一个推荐得用法，因为这会让使用者误以为修改某一个 bit field 是一个原子操作。
此时，在一些实践中会采用读修写得方式使用掩码显式得修改内存中得某个 bit field。

如果采用掩码，则需要为每一个字段定义一个 bit mask，这通常有些 magic，因为 bit mask 不是非常得显意。
另外由于参数均为整型，这允许调用者任意的填充参数，造成不可预见的错误。


```c
struct RegField {
    uint32_t start;
    uint32_t end;
    bool readable;
};
const struct RegField UartTxEn = {.start = 30, .end = 31};

struct Register {
    uint32_t base;
    uint32_t offset;
};
const struct Register UART_CFG_REG = {.base = 0x10000000, .offset = 0xff};

uint32_t RegRead(struct Register* reg, struct RegField* field) {
    if (field->readable == false) {
        compile_const_panic("read an unreadable field");
    }
    volatile uint32_t* ptr = (volatile uint32_t*)(reg->base + reg->offset);
    uint32_t value = *ptr;
    return (value << (31 - field->end)) >> field->start;
}
```

以上是在 C 语言中的一种基于类型安全的做法。用户不会因为 RegRead 函数的参数错误，而导致不可预知的问题。
使用常量而非宏定义，可以方便 debug 调试。另外在优化编译中，由于编译器知道值不会被修改，因此并不会照成过多的负担。
在更为特定的情况下，我们还可能定义这样的函数：

```c
uint32_t UartRegRead(struct UartReg* reg, struct UartRegField* field)
```

唯一不好的地方，我们需要定义大量的具体字段（虽然这些字段相对于 mask 更具有描述性），
以及大量的更具体函数（虽然这样会更具有类型安全特性，防止读写一个寄存器中不存在的字段）

如果存在一个文档描述了这些字段的特性（包括是否可读，是否可写），那么我们可以根据这份文档自动生成那些更为具体的函数。

#include "./bindsl.typ"