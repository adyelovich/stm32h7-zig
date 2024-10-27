const zeroInit = @import("std").mem.zeroInit;
const print = @import("std").debug.print;
const sys = @import("sys");

pub export fn main() void {
    var gpioreg: sys.gpio.Base = zeroInit(sys.gpio.Base, .{});
    var rccreg: sys.rcc.Base = zeroInit(sys.rcc.Base, .{});

    gpioreg.MODER = 0xFFFFFFFF;
    
    // config the LED
    gpioreg.config_pin(1, sys.gpio.Mode.general_output, null, null, null, null);
    
    // enable the clock
    rccreg.gpio_clk_rst(1 << 4);
    
    // toggle it
    gpioreg.toggle(1);

    print("{x} {x}\n", .{rccreg.AHB4RSTR, gpioreg.MODER});
}
