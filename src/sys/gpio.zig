const rwconfig = @import("bitutils.zig").rwconfig;

pub const Base = packed struct {
    MODER: u32,
    OTYPER: u32,
    OSPEEDR: u32,
    PUPDR: u32,
    IDR: u32,
    ODR: u32,
    BSRR: u32,
    LCKR: u32,
    AFRL: u32,
    AFRH: u32,

    pub fn config_pin(self: *volatile Base, pin: u16, mode: Mode,
                      output: ?Output, speed: ?Speed, pupd: ?Pupd,
                      alt_func: ?u8) void {
        self.config_mode(pin, mode, alt_func);
        self.config_output(pin, output);
        self.config_speed(pin, speed);
        self.config_pupd(pin, pupd);
    }

    pub fn config_mode(self: *volatile Base, pin: u16, mode: Mode, alt_func: ?u8) void {
        _ = rwconfig(u32, &self.MODER, pin, @intFromEnum(mode), 2);

        if (alt_func) |af| {
            // do the low ones first
            _ = rwconfig(u32, &self.AFRL, pin & 0xFF, af, 4);
            // now do the high ones
            _ = rwconfig(u32, &self.AFRH, (pin & 0xFF00) >> 8, af, 4);
        }
    }
    
    pub fn config_output(self: *volatile Base, pin: u16, output: ?Output) void {
        if (output) |out_c| {
            _ = rwconfig(u32, &self.OTYPER, pin, @intFromEnum(out_c), 1);
        }
    }

    pub fn config_speed(self: *volatile Base, pin: u16, speed: ?Speed) void {
        if (speed) |speed_c| {
            _ = rwconfig(u32, &self.OSPEEDR, pin, @intFromEnum(speed_c), 2);
        }
    }

    pub fn config_pupd(self: *volatile Base, pin: u16, pupd: ?Pupd) void {
        if (pupd) |pupd_c| {
            _ = rwconfig(u32, &self.PUPDR, pin, @intFromEnum(pupd_c), 2);
        }
    }

    pub fn toggle(self: *volatile Base, pin: u16) void {
        const old_config = self.ODR;

        // if a bit is clear in old_config, set in in lower word
        const low = ~old_config & @as(u32, pin);

        // if a bit is set in old_config, set it in higher word
        const high = (old_config & @as(u32, pin)) << 16;

        self.BSRR = high | low;
    }
};

pub const Mode = enum(u2) {
    input = 0,
    general_output,
    alt_func,
    analog,
};

pub const Output = enum(u1) {
    push_pull = 0,
    open_drain,
};

pub const Speed = enum(u2) {
    low = 0,
    medium,
    high,
    very_high,
};

pub const Pupd = enum(u2) {
    none = 0,
    up,
    down,
};
