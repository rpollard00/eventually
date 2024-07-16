const std = @import("std");
const Thread = std.Thread;
const Semaphore = std.Thread.Semaphore;

const MAX_ITERATIONS = 200;

const Event = struct {
    name: []const u8,
    completed: bool,
    arena: std.heap.ArenaAllocator,

    pub fn create(parent_allocator: std.mem.Allocator, event_name: []const u8, event_counter: usize) !*Event {
        var arena = std.heap.ArenaAllocator.init(parent_allocator);
        var alloc = arena.allocator();

        var event = try alloc.create(Event);

        event.arena = arena;
        event.name = try std.fmt.allocPrint(alloc, "{s}{d}", .{ event_name, event_counter });
        event.completed = false;

        return event;
    }

    pub fn destroy(self: *Event) void {
        self.arena.deinit();
    }
};

const EventLoop = struct {
    allocator: std.mem.Allocator,
    queue: std.ArrayList(*Event),
    running: bool,

    pub fn init(allocator: std.mem.Allocator) !EventLoop {
        return EventLoop{
            .allocator = allocator,
            .queue = std.ArrayList(*Event).init(allocator),
            .running = true,
        };
    }
    pub fn enqueueEvent(self: *EventLoop, event: *Event) !void {
        try self.queue.append(event);
    }

    pub fn run(self: *EventLoop) !void {
        var i: usize = 0;

        while (self.running and i < MAX_ITERATIONS) : (i += 1) {
            if (self.queue.items.len == 0) continue;

            const eventToProcess = self.queue.pop();
            defer eventToProcess.destroy();
            std.debug.print("Event: {s}\n", .{eventToProcess.*.name});
        }
        std.debug.print("Out of events\n", .{});
    }

    pub fn deinit(self: *EventLoop) void {
        self.queue.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var eventLoop = try EventLoop.init(allocator);
    defer eventLoop.deinit();

    try eventLoop.enqueueEvent(try Event.create(allocator, "event", 1));
    try eventLoop.enqueueEvent(try Event.create(allocator, "event", 2));
    try eventLoop.enqueueEvent(try Event.create(allocator, "event", 3));

    try eventLoop.run();
}
