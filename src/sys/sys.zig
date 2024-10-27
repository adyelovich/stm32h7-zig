// Peripherals
pub const rcc = @import("rcc.zig");
pub const gpio = @import("gpio.zig");

// Utils
pub const bitutils = @import("bitutils.zig");

pub const RCC: *volatile rcc.Base = @ptrFromInt(0x5802_4400);

pub const GPIOA: *volatile gpio.Base = @ptrFromInt(0x5802_0000);
pub const GPIOB: *volatile gpio.Base = @ptrFromInt(0x5802_0400);
pub const GPIOC: *volatile gpio.Base = @ptrFromInt(0x5802_0800);
pub const GPIOD: *volatile gpio.Base = @ptrFromInt(0x5802_0C00);
pub const GPIOE: *volatile gpio.Base = @ptrFromInt(0x5802_1000);
pub const GPIOF: *volatile gpio.Base = @ptrFromInt(0x5802_1400);
pub const GPIOG: *volatile gpio.Base = @ptrFromInt(0x5802_1800);
pub const GPIOH: *volatile gpio.Base = @ptrFromInt(0x5802_1C00);
pub const GPIOI: *volatile gpio.Base = @ptrFromInt(0x5802_2000);
pub const GPIOJ: *volatile gpio.Base = @ptrFromInt(0x5802_2400);
pub const GPIOK: *volatile gpio.Base = @ptrFromInt(0x5802_2800);

pub extern fn get_CONTROL_REG() u32;
