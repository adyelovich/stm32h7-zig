const sys = @import("sys");

export fn main() void {

    _ = sys.get_CONTROL_REG();

    // enable the clock
    sys.RCC.gpio_clk_on(0x12);
    
    // config the LED
    sys.GPIOB.config_pin(0x4001, sys.gpio.Mode.general_output, null, null, null, null);
    sys.GPIOE.config_pin(2, sys.gpio.Mode.general_output, null, null, null, null);
    
    // toggle it
    sys.GPIOB.toggle(0x4001);
    sys.GPIOE.toggle(2);
}
