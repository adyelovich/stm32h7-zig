pub fn bitfill(comptime T: type, len: u6, elt: u32) T {
    var rounds: usize = @as(u32, @bitSizeOf(T)) / len + 1;
    var filled: T = 0;

    if (len & 32 != 0) {
        return @as(T, elt);
    }
    
    while (rounds > 0) : (rounds -= 1) {
        filled = filled << @intCast(len);
        filled |= elt;
    }

    return filled;
}

// "multiplies" the first len LSBs of input so that the first mul LSBs are
// now mul copies of the first LSB of input, the next mul LSBs are now mul
// copies of the second LSB of input, and so on
//
// For example: input = abcd, len = 3, mul = 3 returns bbbcccddd
pub fn bitmul(input: u16, len: u6, mul: u6) u32 {
    var ret: u32 = 0;
    var sparse: u32 = 0;
    var i: u6 = 0;

    const fixlen = if (len > 32) 32 else len;
    const fixmul = if (mul > 32) 32 else mul;
    
    // first disperse the bits
    while (i < fixlen) : (i += 1) {
        const bit = input & (@as(u32, 1) << @intCast(i));
        sparse |= bit << (@as(u5, @intCast(i)) * @as(u5, @intCast(fixmul - 1)));
    }

    // now fill in the rest
    i = 0;
    while (i < fixmul) : (i += 1) {
        ret |= sparse << @intCast(i);
    }

    return ret;
}

// Updates a register in the following way so that the previous configuration
// is not overwritten where changes are not desired:
//
// Extend the desired config to 32 bits using bitfill(), get a mask that
// addresses the bits in the register we wish to set using bitmul().
// Now get the old configuration by reading followed by ANDing with NOT mask
// (i.e. the bits we do _not_ wish to change)
// Then extract the bits we wish to write by ANDing the mask with the extended
// config, OR them together, and write (so that the effect is that things
// we did not want to change match up with what we write)
pub fn rwconfig(comptime T: type, reg: *volatile T, pin: u16,
                config: u32, config_len: u6) T {
    const config_extend = bitfill(T, config_len, config);
    const mask = bitmul(pin,
                        @intCast(@as(u16, @bitSizeOf(T)) / @as(u16, config_len)),
                        config_len);
    const old_state = reg.* & ~mask;
    const new_state = config_extend & mask;
    const ret = old_state | new_state;

    reg.* = ret;

    return ret;
}

fn rwconfigdbg(comptime T: type, reg: T, pin: u16,
               config: u32, config_len: u5) T {
    const config_extend = bitfill(T, config_len, config);
    const mask = bitmul(pin,
                        @intCast(@as(u16, @bitSizeOf(T)) / @as(u16, config_len)),
                        config_len);
    const old_state = reg & ~mask;
    const new_state = config_extend & mask;
    const ret = old_state | new_state;

    //reg.* = ret;

    return ret;
}

const expect = @import("std").testing.expect;
const print = @import("std").debug.print;

test "bitfill" {
    const input = 0b1011;

    try expect(bitfill(u32, 4, input) == 0xBBBBBBBB);
}

test "bitmul" {
    const input = 0b1011;

    try expect(bitmul(input, 4, 1) == input);
    try expect(bitmul(input, 4, 2) == 0b11001111);
    try expect(bitmul(input, 4, 3) == 0b111000111111);
    try expect(bitmul(input, 4, 4) == 0b1111000011111111);
}

test "bitmulbad" {
    const input = 0b101011;

    try expect(bitmul(input, 6, 6) == 0b11000000111111000000111111111111);
}

test "rwconfig" {
    const old = 0xAB10_0000;

    try expect(rwconfigdbg(u32, old, 0x80FE, 0b10, 2) == 0xAB10_AAA8);
    try expect(rwconfigdbg(u32, old, 0x80FE, 0b11, 2) == 0xEB10_FFFC);
}
