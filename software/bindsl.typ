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
    magic: UINT(::bit(3), )
}
```
确认 Encode 所需要具备的属性:

+ size
+ order
+ permission

确认 member 所需要的属性, member 的属性一般用于覆盖 Encode 的属性 ：

+ permission
+ order
