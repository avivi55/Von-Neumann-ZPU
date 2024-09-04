pub const Mnemonics = enum {
    // Arithmetics
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    INC,
    DEC,

    // Logical
    AND,
    NOT,
    OR,
    XOR,
    LS,
    RS,

    // Memory
    MOV,

    // Programming
    JMP,
    JNZ,
    OUT,
    OUTC,
    IN,

    NOTHING,
};