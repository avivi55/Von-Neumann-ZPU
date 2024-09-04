pub fn Register(comptime T: type) type {
    return  struct {
        data: T = 0,
    };
}

