module A2D_intf(clk, rst_n, nxt, lft_ld, rght_ld, batt, SS_n, SCLK, MOSI, MISO);
//inputs
input clk, rst_n, MISO;
input reg nxt;
// outputs
output reg [11:0] lft_ld, rght_ld, batt;
output MOSI, SS_n, SCLK;

//internal wires
logic done, wrt, rght_en, lft_en, batt_en, counter_in;
wire [15:0] cmd, rd_data;
reg counter_out;

//SM output
logic update;

// instantiate SPI master
SPI_mstr16 SPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .done(done), .cmd(cmd), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .rd_data(rd_data));

//create counter
always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)
    counter_out <= 2'h0;
  else
    counter_out <= counter_in;

assign counter_in = update ? (counter_out == 2'h2 ? 2'h0 : counter_out + 1'b1) : counter_out;

//enable assigns
assign lft_en = update ? (counter_out == 2'h0 ? 1'b1 : 1'b0) : 1'b0;
assign rght_en = update ? (counter_out == 2'h1 ? 1'b1 : 1'b0) : 1'b0;
assign batt_en = update ? (counter_out == 2'h2 ? 1'b1 : 1'b0) : 1'b0;

//state machine
typedef enum reg[1:0]{IDLE, FIRST, WAIT, DONE}state_t;
state_t state, nxt_state;

always_ff@(posedge clk, negedge rst_n)begin
	if(~rst_n) state <= IDLE;
	else state <= nxt_state;

end

always_comb begin
//default output
wrt = 0;
done =0;
nxt_state = IDLE;

case(state)
		//wait for nxt to start on first channel transaction
	IDLE: if(nxt)begin
			wrt = 1;
			nxt_state = FIRST;
		  end
		  else nxt_state = IDLE;
	
	DONE: //wait for done to notify that we finished receiving first rd_data/result
		  if(done)	nxt_state = WAIT;
		  else nxt_state = FIRST;
		  
	WAIT: //wait for one clock cycle to sych/hold the result
		  begin
			wrt = 1;
		  	nxt_state = DONE;
		  end
		  
	DONE: if(done)begin
			update = 0;
			wrt = 0;
			nxt_state = IDLE;
		  end
		  else nxt_state = DONE;

endcase
end

// assign cmd
assign cmd = counter_out == 2'h0 ? 16'h0000 : (counter_out == 2'h1 ? 16'h2000 : 16'h2800);

// output flip flops
always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)
    lft_ld <= 12'h000;
  else if(lft_en)
    lft_ld <= rd_data;

always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)
    rght_ld <= 12'h000;
  else if(rght_en)
    rght_ld <= rd_data;

always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)
    batt <= 12'h000;
  else if(batt_en)
    batt <= rd_data;
  
endmodule
