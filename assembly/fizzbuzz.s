in r1

mov $5 r5
mov $3 r3

mod r1 r3
mov r0 r9

# if not divisible by 3 -> skip print fizz
jnz $21
# else -> fizz print
jmp $13

mov $F r0
outc
mov $i r0
outc
mov $z r0
outc
outc

mod r1 r5
mov r0 r9
jnz $35
jmp $26

mov $B r0
outc
mov $u r0
outc
mov $z r0
outc
outc
jmp $37

out r1

