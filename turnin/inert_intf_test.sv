module inert_intf_test(clk, RST_n, MISO, MOSI, INT, SS_n, SCLK, LED);

//inputs and outputs
input MISO, INT, clk, RST_n;
output SS_n, SCLK, MOSI;
output [7:0] LED;

//internal wires
wire rst_n;
reg[15:0] ptch;

//instantiate rst_symch and inert_intf
rst_synch RS(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

inert_intf iDUT(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT),
 	.ptch(ptch));
	
assign LED = ptch[8:1];


endmodule
