module digital_core_tb();
`include "./tb_tasks.sv"
input clk, rst_n, pwr_up, MISO, INT;
input [11:0] lft_ld, rght_ld, batt;

output en_steer, ovr_spd, batt_low, MOSI, lft_rev, rght_rev, SS_n, SCLK, nxt;
output [10:0] lft_ld, rght_ld, batt;


Digital_Core iDUT(.clk(clk), .rst_n(rst_n), .pwr_up(pwr_up), .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt), .nxt(nxt), .SS_n(SS_n), .SCLK(.SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT), .batt_low(batt_low), .ovr_spd(ovr_spd), .en_steer(en_steer), .rght_rev(rght_rev), .rght_spd(rght_spd), .lft_rev(lft_rev), .lft_spd(lft_spd));

initial begin
    clk = 0;
    rstDUT_n;
    init_digital_core;

    debug(.name("EN_STEER", 0, en_steer);
end

always #5 clk = ~clk
