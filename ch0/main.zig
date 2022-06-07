const std = @import("std");
const expect = std.testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    // std.debug.print("\nasdfsf\n", .{});
    // std.log.warn("asdf", .{});

    if (a) {
        x += 1;
    } else {
        x += 2;
    }

    try expect(x == 1);
}

test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}

fn computeTotal(heartbeats: []const u32) usize {
    if (heartbeats.len < 1) return 0;

    var t: usize = 0;
    var prev = heartbeats[0];

    for (heartbeats[1..]) |time| {
        const diff = time - prev;
        if (diff < 300) t += diff;
        prev = time;
    }

    return t;
}

test "computeTotal" {
    const array = [_]u32{ 1654534440, 1654534442, 1654534444 };
    try expect(computeTotal(array[0..]) == 4);
}

const Heartbeat = struct { time: u64, project: []u8 };

// fn computeTotals(heartbeats: []const Heartbeat) std.StringHashMap(u64) {}

// TODO break: ..., else: ...
test "while" {
    var i: u8 = 2;
    while (i < 100) i *= 2;
    try expect(i == 128);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) sum += i;
    try expect(sum == 55);
}

test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}

test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}

test "for" {
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |c| {
        _ = c;
    }

    for (string) |_, i| {
        _ = i;
    }

    for (string) |_| {}
}

fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}

test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}

test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    try expect(x == 4.5);
}

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
    };
}

fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
    };
}

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    const x: error{AccessDenied}!void = createFile();
    _ = x catch {};
}

test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => x = -x,
        10, 100 => x = @divExact(x, 10),
        else => {},
    }
    try expect(x == 1);
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}

// test "out of bounds" {
//     return error.SkipZigTest;
//     // const a = [3]i8{ 1, 2, 3 };
//     // var index: u8 = 5;
//     // const b = a[index];
//     // _ = b;
// }

test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}

// test "unreachable" {
//     return error.SkipZigTest;
//     // const x: i32 = 1;
//     // const y: u32 = if (x == 2) 5 else unreachable;
//     // _ = y;
// }

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}

fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}

// test "naughty pointer" {
//     return error.SkipZigTest;
//     // var x: u16 = 0;
//     // var y: *u8 = @intToPtr(*u8, x);
//     // _ = y;
// }

test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    // std.log.warn("{}", .{@TypeOf(y)});
    try expect(@TypeOf(y) == *const u8);
    // y.* += 1;
}

test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}

test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(@TypeOf(slice) == *const [3]u8);
    try expect(total(slice) == 6);
    try expect(@TypeOf(array[0..]) == *const [5]u8);
}
