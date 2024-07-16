const std = @import("std");
const Mutex = std.Thread.Mutex;

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        head: ?*Node,
        tail: ?*Node,
        mutex: ?*Mutex,
        length: usize,

        const Node = struct {
            data: T,
            next: ?*Node,
        };

        pub fn init(alloc: std.mem.Allocator, mutex: ?*Mutex) Self {
            _ = mutex;
            return Self{
                .allocator = alloc,
                .mutex = null,
                .head = null,
                .tail = null,
                .length = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            var current = self.head;

            while (current) |node| {
                current = node.next;
                self.allocator.destroy(node);
            }

            self.* = undefined;
        }

        pub fn enqueue(self: *Self, data: T) !void {
            const node = try self.allocator.create(Node);
            node.* = .{
                .data = data,
                .next = null,
            };

            self.length += 1;

            if (self.tail == null) {
                self.tail = node;
                self.head = self.tail;
                return;
            }

            self.tail.?.next = node;
            self.tail = node;
        }

        pub fn dequeue(self: *Self) !T {
            if (self.head == null or self.head == undefined) {
                return error.DequeuedEmptyQueue;
            }

            const data = self.head.?.data;
            const old_head = self.head;

            defer self.allocator.destroy(old_head.?);

            if (self.head != self.tail) {
                self.head = self.head.?.next;
            } else {
                self.head = null;
                self.tail = null;
            }

            self.length -= 1;

            return data;
        }
    };
}

test "can make a queue" {
    // var mutex: Mutex = .{};
    const alloc = std.testing.allocator;

    var queue = Queue(u16).init(alloc, null);
    defer queue.deinit();
}

test "can dequeue one node" {
    const alloc = std.testing.allocator;

    var queue = Queue(u16).init(alloc, null);
    defer queue.deinit();

    const uhh1: u16 = 5;

    try queue.enqueue(uhh1);

    const val1 = try queue.dequeue();
    try std.testing.expect(val1 == 5);
}

test "can queue simple data" {
    const alloc = std.testing.allocator;

    var queue = Queue(u16).init(alloc, null);
    defer queue.deinit();

    const uhh1: u16 = 5;
    const uhh2: u16 = 10;
    const uhh3: u16 = 3;

    try queue.enqueue(uhh1);
    try queue.enqueue(uhh2);
    try queue.enqueue(uhh3);

    const val1 = try queue.dequeue();
    std.debug.print("Val is {d}\n", .{val1});
    try std.testing.expect(val1 == 5);
    const val2 = try queue.dequeue();
    std.debug.print("Val is {d}\n", .{val2});
    try std.testing.expect(val2 == 10);
    const val3 = try queue.dequeue();
    std.debug.print("Val is {d}\n", .{val2});
    try std.testing.expect(val3 == 3);
}

test "can empty and refill queue and empty again" {
    const alloc = std.testing.allocator;

    var queue = Queue(u16).init(alloc, null);
    defer queue.deinit();

    try queue.enqueue(5);
    try queue.enqueue(7);

    const val1 = try queue.dequeue();
    const val2 = try queue.dequeue();

    try std.testing.expect(val1 == 5);
    try std.testing.expect(val2 == 7);

    std.debug.print("Enqueue 4\n", .{});
    try queue.enqueue(4);
    std.debug.print("Enqueue 8\n", .{});
    try queue.enqueue(8);

    const val3 = try queue.dequeue();
    const val4 = try queue.dequeue();

    try std.testing.expect(val3 == 4);
    try std.testing.expect(val4 == 8);
}

test "expect length to be 5 after adding 5 elements" {
    const alloc = std.testing.allocator;

    var queue = Queue(u16).init(alloc, null);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);
    try queue.enqueue(4);
    try queue.enqueue(5);

    try std.testing.expect(queue.length == 5);
}

test "expect length to be 3 after adding 5 elements and removing 2" {
    const alloc = std.testing.allocator;

    var queue = Queue(u16).init(alloc, null);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);
    try queue.enqueue(4);
    try queue.enqueue(5);

    _ = try queue.dequeue();
    _ = try queue.dequeue();

    try std.testing.expect(queue.length == 3);
}
