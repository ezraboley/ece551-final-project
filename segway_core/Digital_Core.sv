module Digital_Core(clk, rst_n, pwr_up, lft_ld, rght_ld, batt, nxt, SS_n, 
  SCLK, MOSI, MISO, INT, batt_low, ovr_spd, en_steer, rght_rev, rght_spd, lft_rev, lft_spd);

//inputs ans outputs
input clk, rst_n, pwr_up, MISO, INT;
input [11:0] lft_ld, rght_ld, batt;

output en_steer, ovr_spd, batt_low, MOSI, lft_rev, rght_rev, SS_n, SCLK, nxt;
output [10:0] lft_spd, rght_spd;

// internal wires
wire rider_off, vld, steer_en;
wire [15:0] ptch;
wire [11:0] ld_cell_diff;

//instantiate modules
inert_intf iINERT(ptch, vld, SCLK, SS_n, MOSI, MISO, INT, clk, rst_n);

balance_cntrl iBAL(clk, rst_n, ovr_spd, vld, ptch, ld_cell_diff, lft_spd, lft_rev, rght_spd, rght_rev, rider_off, steer_en, pwr_up);

en_steer iENSTR(clk, rst_n, lft_ld, rght_ld, steer_en, rider_off);

//determines batt_low
assign batt_low = batt < 12'h800 ? 1 : 0;





endmodule
