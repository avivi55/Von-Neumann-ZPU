# Programs that calculates the fibonacci sequence

MOV $0 R1
MOV $1 R2

# a space char
MOV $\s R3

# loop counter
IN R9

# 0
OUT R1
# space
OUTC R3

# Fibonacci formula
ADD R1 R2
OUT R0
OUTC R3
MOV R1 R2
MOV R0 R1

# loop
DEC R9
JNZ $17
