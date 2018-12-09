module Digital_Core(clk, rst_n, pwr_up, lft_ld, rght_ld, batt, nxt, SS_n, 
  SCLK, MOSI, MISO, INT, batt_low, ovr_spd, en_steer, rght_rev, rght_spd, lft_rev, lft_spd);

//inputs ans outputs
input clk, rst_n, pwr_up, MISO, INT;
input [11:0] lft_ld, rght_ld, batt;

output en_steer, ovr_spd, batt_low, MOSI, lft_rev, rght_rev, SS_n, SCLK, nxt;
output [10:0] lft_spd, rght_spd;

// internal wires
wire rider_off, vld;
wire [15:0] ptch;
wire [11:0] ld_cell_diff;

//instantiate modules
inert_intf iINERT(.ptch(ptch), .vld(vld), .SCLK(SCLK), .SS_n(SS_n), .MOSI(MOSI), .MISO(MISO), .INT(INT), .clk(clk), .rst_n(rst_n));

balance_cntrl iBAL(.clk(clk), .rst_n(rst_n), .too_fast(ovr_spd), .vld(vld), .ptch(ptch), .ld_cell_diff(ld_cell_diff), .lft_spd(lft_spd), .lft_rev(lft_rev), .rght_spd(rght_spd), .rght_rev(rght_rev), .rider_off(rider_off), .en_steer(en_steer), .pwr_up(pwr_up));

en_steer #(.fast_sim(0)) iENSTR(.clk(clk), .rst_n(rst_n), .lft_ld(lft_ld), .rght_ld(rght_ld), .en_steer(en_steer), .rider_off(rider_off), .ld_cell_diff(ld_cell_diff));

//determines batt_low
assign batt_low = batt < 12'h800 ? 1 : 0;
assign nxt = vld;




endmodule
