# (5x+4)/2 + 3y

mov $\n R0
# x
mov $x R9
outc R9
outc
in R9

# y
mov $y R8
outc R8
outc
in R8


mov $4 R2
mov $5 R1

# R0 = 5x
mul R9 R1

# R0 += 4
add R2 R0

# R0 /= 2
mov $2 R1
div R0 R1

# save the result in R1
mov R0 R1

# R0 = 3
mov $3 R0

# R0 *= y
mul R8 R0

add R1 R0

out

