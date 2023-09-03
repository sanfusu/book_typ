#show raw: set text(font: "Fira Code")
= 二进制描述语言

二进制描述性语言需要能够转换成其编程语言。

由于可变长度字段的存在，该语言需要具备基本计算功能。

需要能够覆盖寄存器，机器指令，ELF 文件，IP 协议基本一个用场景

```pest
alpha = { 'a'..'z' | 'A'..'Z' }
digit = { '0'..'9' }
math_op = { '+' | '-' | '*' | '/'}
bitwise_op = { '<<' | '>>' | '^' }

identifier = { !digit ~ (alpha | digit)+ }

hex_num = { '0x' ~ digit }
```

```
UINT {
    // predefine encode
    align: bit(1)
}

SINT {
    // predefine encode
}

FLOAT {
    // predefine encode
}

BOOL {
    // predefine encode
}

Header {
    version:  UINT::byte(8)
    magic: UINT::bit(3)
    next_header_ptr: UINT::byte(4)
    next_header: Optional when next_header_ptr != NULL
}
```

基本块：编码(encode)
encode 由字段组成，每一个字段也是一个 encode。
encode 包含默认属性和上下文属性。当其作为某一个 encode 的字段时，可以覆盖其默认属性。

属性：对齐方式，布局范围，访问权限（可读可写）

如何访问属性和字段？


任何一个编码都应该有其可取的值。
浮点数表示的值是 IEE754 规范中定的有理数取值。是的，不认为 IEE754 能够表示无理数，甚至不能表示部分有理数。

```
UINT {
    ::bits(N) { // start of constraint
      ::range(0..=pow(2,N)-1)
    }
}
```

字段中 `::` 开头表示是 encode 的固有属性。比如 bits 表示 UINT 占有多少个 bit。

```
Header {
    magic: UINT[bits(5)] {
        OFFSET(10)
    }
}
```
确认 Encode 所需要具备的属性:

+ size
+ order
+ permission

确认 member 所需要的属性, member 的属性一般用于覆盖 Encode 的属性 ：

+ size
+ order
+ permission
+ offset, 带有 offset 属性的字段一般是位置不固定的字段。

所有的格式应当精简，避免过多属性字样，比如 OFFSET(0x100)。
应当使用符号代替如 `#0x100` 表示偏移，`0..=4` 表示 bit0 到 bit4 包含。`[0, 4]` 表示 byte0 到 byte4 包含。

符号一定是使用特殊符号，不能是常见的运算符（包括逻辑运算）。
`@ $ #` 这三个可以单独使用，另外有些符号组合起来也可以使用 `|> <|`

offset 可以是 `#0x100` 表示偏移量是 0x100，也可以是 `#encode.offset` 表示偏移量由 offset 字段的值决定。

组符号：`{} [] ()`，其中 `{}` 可以用作成员组，`[]` 可以用作属性组。

```
Header {
    magic: UINT:[#0x0, @rw, bits(0..=3)]
}
```

`@` 可以用于关键字属性（不带参数的），比如 
+ `@acc::rw` 表示可读性
+ `@endian::le` 表示小端字节序
+ `@endian::be` 表示大端字节序

但是可以带 namespace。

另外需要一种常见 bit 映射。比如一个 8bit 整型 A 是一个 32bit 寄存器 REG 中的某一个虚拟字段。
+ `A.bits(0..=3)` 对应 `REG.bits(9..=12)`
+ `A.bits(4..=7)` 对应 `REG.bits(20..=23)`

这种需要一般是由于后期更改，并且需要考虑兼容性引起的。

除此之外还有字段数组的要求，即一组连续的具有相同编码的字段。

对于 bit 映射，要求我们在虚拟字段中可以访问父容器。

如何访问父节点：`..bits(0..=3), ..@acc, ..#` 这几个分别表示访问父节点 `0..=3` bits，访问权限属性，偏移属性。

```
REG: UINT[bits(0..=31)] {
    virtual field: UINT[bits(0..=7)] {
        .bits(0..=3) => ..bits(4..=7),
        .bits(4..=7) => ..bits(12..=15),
    }
}
```

虚拟字段不应当是一个常用的字段。所以用来标注的关键词记号可以长一点，比如 virtual，不使用缩写。

`=>` 是一个常见的映射符号。

对于数组，在编程语言中一般使用 `[]` 来表示，并且可以使用 `[x]` 来访问第 x 个元素。但是在 bindsl 中不存在访问下标的需求。
另外 `[]` 已经用于属性列表了。

数组可以简单的理解为重复。

```
REG: UINT[bits(0..=31)] {
    field: UINT[bits(0..=8)] * 4
}
```
表示 REG 中有四个重复的 field 字段。

或者使用上下文的 `[]` 仅在 field 之后才判断为数组：


```
REG: UINT[bits(0..=31)] {
    field[4]: UINT[#bits(0..=8)]
}
```

需要将逻辑处理直接定义在编码定义过程中:
```
Header {
    magic: MAGIC
#if(Header::magic.width == 64) {
    length: UINT<w:64>
} else {
    length: UINT<w:32>
}
}
```