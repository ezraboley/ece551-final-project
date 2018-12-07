module SPI_mstr16(clk, rst_n, wrt,cmd, done, rd_data, SS_n, SCLK, MOSI, MISO);
input clk, rst_n, MISO, wrt;
output reg done, MOSI, SS_n;
output reg [15:0]rd_data;
input [15:0]cmd;
output SCLK;


logic smpl, rst_cnt, shft,MISO_smpl;
logic [4:0]sclk_div;
logic [15:0]shft_reg;
logic [4:0]shift_cnt;		//count how many bits have shifted, total is 16 bits
logic last_bit_count;
logic clr_done, set_done;


typedef enum reg[1:0]{IDLE, FRST_PRCH, SHIFT, DONE_SHIFT} state_t;
state_t state, nxt_state;


////////////////////////////////////////////////////////////////////////////////////////////
assign SCLK = sclk_div[4];
assign MOSI = shft_reg [15];

// since we only care abt rd_data in the end when done is asserted, so it can equals to shft_reg 
assign rd_data = shft_reg;

//generate SLCK lock
always_ff@(posedge clk, negedge rst_n)begin
if(~rst_n) sclk_div <= 0;
else if(rst_cnt) sclk_div <= 5'b10111;
else if(~rst_cnt) sclk_div <= sclk_div +1;
end 

//Taking MISO in block
always_ff@(posedge clk, negedge rst_n)begin
if(~rst_n) MISO_smpl<= 0;
else if(smpl) 		MISO_smpl <= MISO;
end

//shifting and produce MOSI block
always_ff@(posedge clk, negedge rst_n)begin
if(~rst_n) shft_reg <= 0;
else if(clr_done) 	shft_reg <= cmd;
else if(shft) 	shft_reg <= {shft_reg[14:0], MISO_smpl};
end

//counter on 15bits and 16bits done
always_ff@(posedge clk, negedge rst_n)begin
if(~rst_n) shift_cnt <= 0;
else if (clr_done)
	shift_cnt <= 0;
else if(smpl) shift_cnt <= shift_cnt +1;
end

assign last_bit_count = (shift_cnt == 16)? 1:0;		// on last bit 

////////////////////////////////////////////////////////////////////////////////////////////
///state machine////////////////////////////////////////////////////////////////////////////
always_ff@(posedge clk, negedge rst_n)begin
if(~rst_n) state <= IDLE;
else state <= nxt_state;
end

always_comb begin
//default state outputs and nxt_state
rst_cnt = 0;
shft =0;
smpl =0;
set_done =0;
clr_done =0;
nxt_state = IDLE;


case(state)

	IDLE:
		  if(wrt)  begin
			clr_done = 1;
			rst_cnt = 1;
			nxt_state = FRST_PRCH;
			end
		  else begin
		    nxt_state = IDLE;
			rst_cnt = 1;
		  end
		  
		  
	FRST_PRCH: if(sclk_div == 5'b11111) begin 
					nxt_state = SHIFT;	//at first falling edge, we have already loaded MSB
					end
		   else begin
		   nxt_state = FRST_PRCH;
		   end
	
	SHIFT: //at rising edge
			if(sclk_div == 5'b01111) begin
			smpl = 1; 
			nxt_state = SHIFT;
			end
			//at falling edge 
		   else if (sclk_div == 5'b11111) begin 		
		    	shft = 1;
			nxt_state = SHIFT;
			end
		   else if (last_bit_count) begin
			nxt_state = DONE_SHIFT;
			end
			else nxt_state = SHIFT;
	
	DONE_SHIFT: //If it's abt to be falling edge on the last bit
			if(sclk_div == 5'b11111)begin
			shft = 1;
			rst_cnt = 1;		//so that SCLK keeps high
			set_done = 1;
			nxt_state = IDLE;
			end
		    else nxt_state = DONE_SHIFT;
	endcase
end


//last logic on setting output 

//ss_n only knock off when start transmitting.
always_ff@(posedge clk, negedge rst_n)begin
if(~rst_n) begin
SS_n <= 1;
done <= 0;
end 

else if(clr_done) begin
SS_n <= 0;
done <= 0;
end

else if(set_done) begin
SS_n <= 1;
done <= 1;
end

end		

			
			

endmodule
