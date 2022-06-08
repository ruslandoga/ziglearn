fn add(a: u32, b: u32) callconv(.C) u32 {
    return a + b;
}

const expect = @import("std").testing.expect;
const expectEqual = @import("std").testing.expectEqual;

const Data = extern struct { a: i32, b: u8, c: f32, d: bool, e: bool };

test "hmm" {
    const x = Data{
        .a = 10005,
        .b = 42,
        .c = -10.5,
        .d = false,
        .e = true,
    };

    const z = @ptrCast([*]const u8, &x);

    try expect(@ptrCast(*const i32, z).* == 10005);
    try expect(@ptrCast(*const u8, z + 4).* == 42);
    try expect(@ptrCast(*const f32, z + 8).* == -10.5);
    try expect(@ptrCast(*const bool, z + 12).* == false);
    try expect(@ptrCast(*const bool, z + 13).* == true);
}

test "aligned pointers" {
    const a: u32 align(8) = 5;
    try expectEqual(*align(8) const u32, @TypeOf(&a));
}

fn total(a: *align(64) const [64]u8) u32 {
    var sum: u32 = 0;
    for (a) |elem| sum += elem;
    return sum;
}

test "passing aligned data" {
    const x align(64) = [_]u8{10} ** 64;
    try expectEqual(@as(u32, 640), total(&x));
}

const MovementState = packed struct {
    running: bool,
    crouching: bool,
    jumping: bool,
    in_air: bool,
};

test "packed struct size" {
    try expectEqual(1, @sizeOf(MovementState));
    try expectEqual(4, @bitSizeOf(MovementState));
    const state = MovementState{ .running = true, .crouching = true, .jumping = true, .in_air = true };
    _ = state;
}

test "bit aligned pointers" {
    var x = MovementState{
        .running = false,
        .crouching = false,
        .jumping = false,
        .in_air = false,
    };

    const running = &x.running;
    running.* = true;

    const crouching = &x.crouching;
    crouching.* = true;

    try expectEqual(*align(1:0:1) bool, @TypeOf(running));
    try expectEqual(*align(1:1:1) bool, @TypeOf(crouching));

    try expect(@import("std").meta.eql(x, .{ .running = true, .crouching = true, .jumping = false, .in_air = false }));
}
