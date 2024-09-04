mov $3141 R1
mov $1000 R2
mov $1000000 R3

# the radius
in R0

mul R0 R0

mul R2 R0

mul R1 R0
mov R0 R1

mod R0 R3
mov R0 R2

mov R1 R0
div R0 R3

out R0
# '.' character
mov $. R3
outc R3
out R2
