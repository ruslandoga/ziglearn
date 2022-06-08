const std = @import("std");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}

test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}

test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("TEST FAIL");
    }

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}

const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();

    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    try expect(eql(u8, list.items, "Hello World!"));
}

test "createFile, write, seekTo, read" {
    const file = try std.fs.cwd().createFile("junk_file.txt", .{ .read = true });
    defer file.close();

    const bytes_written = try file.writeAll("Hello File!");
    _ = bytes_written;

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);

    try expect(eql(u8, buffer[0..bytes_read], "Hello File!"));
}

test "file stat" {
    const file = try std.fs.cwd().createFile("junk_file2.txt", .{ .read = true });
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .File);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}

test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    const dir = try std.fs.cwd().openDir("test-tmp", .{ .iterate = true });
    defer {
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }

    _ = try dir.createFile("x", .{});
    _ = try dir.createFile("y", .{});
    _ = try dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count == 3);
}

test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello World!"));
}

test "io reader usage" {
    const message = "Hello File!";

    const file = try std.fs.cwd().createFile("junk_file2.txt", .{ .read = true });
    defer file.close();

    try file.writeAll(message);
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(test_allocator, message.len);
    defer test_allocator.free(contents);

    try expect(eql(u8, contents, message));
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}

// test "read until next line" {
//     const stdout = std.io.getStdOut();
//     const stdin = std.io.getStdIn();

//     try stdout.writeAll(
//         \\ Enter your name:
//     );

//     var buffer: [100]u8 = undefined;
//     const input = (try nextLine(stdin.reader(), &buffer)).?;
//     try stdout.writer().print("Your name is: \"{s}\"\n", .{input});
// }

const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    const Writer = std.io.Writer(
        *MyByteList,
        error{EndOfBuffer},
        appendWrite,
    );

    fn appendWrite(self: *MyByteList, data: []const u8) error{EndOfBuffer}!usize {
        if (self.items.len + data.len > self.data.len) {
            return error.EndOfBuffer;
        }

        std.mem.copy(u8, self.data[self.items.len..], data);
        self.items = self.data[0 .. self.items.len + data.len];
        return data.len;
    }

    fn writer(self: *MyByteList) Writer {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};
    _ = try bytes.writer().write("Hello");
    _ = try bytes.writer().write(" Writer!");
    try expect(eql(u8, bytes.items, "Hello Writer!"));
}

test "fmt" {
    const string = try std.fmt.allocPrint(test_allocator, "{d} + {d} = {d}", .{ 9, 10, 19 });
    defer test_allocator.free(string);
    try expect(eql(u8, string, "9 + 10 = 19"));
}

test "print" {
    var list = std.ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.writer().print("{} + {} = {}", .{ 9, 10, 19 });
    try expect(eql(u8, list.items, "9 + 10 = 19"));
}

// test "hello world" {
//     const out_file = std.io.getStdOut();
//     try out_file.writer().print("Hello, {s}!\n", .{"World"});
// }

test "array printing" {
    const string = try std.fmt.allocPrint(test_allocator, "{any} + {any} = {any}", .{
        @as([]const u8, &[_]u8{ 1, 4 }),
        @as([]const u8, &[_]u8{ 2, 5 }),
        @as([]const u8, &[_]u8{ 3, 9 }),
    });
    defer test_allocator.free(string);

    try expect(eql(u8, string, "{ 1, 4 } + { 2, 5 } = { 3, 9 }"));
}

const Person = struct {
    name: []const u8,
    birth_year: i32,
    death_year: ?i32,

    pub fn format(self: Person, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} ({}-", .{ self.name, self.birth_year });
        if (self.death_year) |year| try writer.print("{}", .{year});
        try writer.writeAll(")");
    }
};

test "custom fmt" {
    const john = Person{ .name = "John Carmack", .birth_year = 1970, .death_year = null };
    const john_string = try std.fmt.allocPrint(test_allocator, "{s}", .{john});
    defer test_allocator.free(john_string);

    try expect(eql(u8, john_string, "John Carmack (1970-)"));

    const claude = Person{ .name = "Claude Shannon", .birth_year = 1916, .death_year = 2001 };
    const claude_string = try std.fmt.allocPrint(test_allocator, "{s}", .{claude});
    defer test_allocator.free(claude_string);

    try expect(eql(u8, claude_string, "Claude Shannon (1916-2001)"));
}

const Place = struct { lat: f32, long: f32 };

test "json parse" {
    var stream = std.json.TokenStream.init(
        \\{ "lat": 40.684540, "long": -74.401422 }
    );
    const x = try std.json.parse(Place, &stream, .{});

    try expect(x.lat == 40.684540);
    try expect(x.long == -74.401422);
}

test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(x, .{}, string.writer());

    try expect(eql(u8, string.items,
        \\{"lat":5.19976654e+01,"long":-7.40687012e-01}
    ));
}

test "json parse with strings" {
    var stream = std.json.TokenStream.init(
        \\{ "name": "Joe", "age": 25 }
    );

    const User = struct { name: []u8, age: u16 };

    const x = try std.json.parse(User, &stream, .{ .allocator = test_allocator });
    defer std.json.parseFree(User, x, .{ .allocator = test_allocator });

    try expect(eql(u8, x.name, "Joe"));
    try expect(x.age == 25);
}
