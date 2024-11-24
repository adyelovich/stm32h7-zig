const rwconfig = @import("bitutils.zig").rwconfig;

// change these values depending on the board
pub const HSI: u32 = 64_000_000;
pub const CSI: u32 = 4_000_000;
pub const HSE: u32 = 8_000_000;

pub const Base = packed struct {
    CR: u32,
    HSICFGR: u32,
    CRRCR: u32,
    CSICFGR: u32,
    CFGR: u32,
    res0: u32,
    CDCFGR1: u32,
    CDCFGR2: u32,
    SRDCFGR: u32,
    res24: u32,
    PLLCKSELR: u32,
    PLLCFGR: u32,
    PLL1DIVR: u32,
    PLL1FRACR: u32,
    PLL2DIVR: u32,
    PLL2FRACR: u32,
    PLL3DIVR: u32,
    PLL3FRACR: u32,
    res1: u32,
    CDCCIPR: u32,
    CDCCIP1R: u32,
    CDCCIP2R: u32,
    SRDCCIPR: u32,
    res2: u32,
    CIER: u32,
    CIFR: u32,
    CICR: u32,
    res3: u32,
    BDCR: u32,
    CSR: u32,
    res4: u32,
    AHB3RSTR: u32,
    AHB1RSTR: u32,
    AHB2RSTR: u32,
    AHB4RSTR: u32,
    APB3RSTR: u32,
    APB1LRSTR: u32,
    APB1HRSTR: u32,
    APB2RSTR: u32,
    APB4RSTR: u32,
    resA0: u32,
    res5: u32,
    SRDAMR: u32,
    res6: u32,
    CKGAENR: u32,
    res7: u992,
    RSR: u32,
    AHB3ENR: u32,
    AHB1ENR: u32,
    AHB2ENR: u32,
    AHB4ENR: u32,
    APB3ENR: u32,
    APB1LENR: u32,
    APB1HENR: u32,
    APB2ENR: u32,
    APB4ENR: u32,
    res8: u32,
    AHB3LPENR: u32,
    AHB1LPENR: u32,
    AHB2LPENR: u32,
    AHB4LPENR: u32,
    APB3LPENR: u32,
    APB1LLPENR: u32,
    APB1HLPENR: u32,
    APB2LPENR: u32,
    APB4LPENR: u32,

    pub fn config_pll_src(self: *volatile Base, src: PllSrc) void {
        _ = rwconfig(u32, &self.PLLCKSELR, 0x3, @intFromEnum(src), 2);
    }

    // TODO: WRITE VCO WIDTH SETTER

    pub fn config_pll(self: *volatile Base, comptime clkno: comptime_int,
                      div: PllDiv, wait: bool) PllErr!void {
        // setting some compile time constants, these magic hex numbers are
        // taken from the manual
        const PLLDIVR,
        const CLKM_MSK,
        const CFG_MSK,
        const EN_MSK,
        const PLLCR_MSK = 
        switch (clkno) {
            1 => .{ &self.PLL1DIVR, 0x3F0, 0xF, 0x7_0000, 0x0100_0000 },
            2 => .{ &self.PLL2DIVR, 0x2_F000, 0xF0, 0x28_0000, 0x0400_0000 },
            3 => .{ &self.PLL3DIVR, 0x02F0_0000, 0xF00, 0x1C0_0000, 0x1000_0000 },
            else => { return PllErr.InvalidClock; },
        };

        // assume clock source is already set
        // init pre-divider (PLLM)
        const clk_rate = switch (@as(PllSrc, @enumFromInt(self.PLLCKSELR & 0x3))) {
            PllSrc.hsi => HSI,
            PllSrc.csi => CSI,
            PllSrc.hse => HSE,
            PllSrc.none => { return PllErr.InvalidConfiguration; },
        };
        const vco_input = clk_rate / div.M;
        
        _ = rwconfig(u32, &self.PLLCKSELR, CLKM_MSK, div.M, 6);

        // write the rest of the config to CFG, EN, and PLL{N,P,Q,R}, and set
        // the appropriate N values
        const temp = vco_input / 1_000_000;
        
        const rge: u32 = switch (temp) {
            1 => 0,
            2, 3 => 1,
            4...7 => 2,
            8...16 => 3, // note that this also includes 16000001-16999999
            else => 0,
        };
        _ = rwconfig(u32, &self.PLLCFGR, CFG_MSK, (rge << 2) | 2, 4);

        const div_ens: u32 = (@as(u32, if (div.R) |_| 1 else 0) << 2)
            | (@as(u32, if (div.Q) |_| 1 else 0) << 1)
            | @as(u32, if (div.P) |_| 1 else 0);
        _ = rwconfig(u32, &self.PLLCFGR, EN_MSK, div_ens, 3);
        
        const div_settings = (@as(u32, div.R orelse 0) << 24)
            | (@as(u32, div.Q orelse 0) << 16)
            | (@as(u32, div.P orelse 0) << 9)
            | div.N;
        PLLDIVR.* = (PLLDIVR.* & 0x8080_0000) | div_settings;

        // now turn on the PLL
        _ = rwconfig(u32, &self.CR, PLLCR_MSK, 1, 1);
        
        // wait for PLL if desired
        if (wait) {
            while (self.CR & (PLLCR_MSK << 1) != 1) {}
        }
        // return @as(u64, CFG_MSK) + globals.sysclk + @intFromPtr(PLLDIVR) + EN_MSK + PLLCR_MSK == 0
        //     and wait;
    }
    
    pub fn gpio_clk_on(self: *volatile Base, config: u10) void {
        _ = rwconfig(u32, &self.AHB4ENR, config, 1, 1);
    }

    pub fn gpio_clk_off(self: *volatile Base, config: u10) void {
        _ = rwconfig(u32, &self.AHB4ENR, config, 0, 1);
    }
};

pub const PllErr = error {
    InvalidConfiguration,
};

pub const PllDiv = struct {
    M: u6,
    N: u9,
    P: ?u7,
    Q: ?u7,
    R: ?u7,
};

pub const PllSrc = enum(u2) {
    hsi = 0,
    csi,
    hse,
    none,
};


