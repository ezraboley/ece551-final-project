module Auth_blk(RX, pwr_up, clk, rst_n, rider_off);
output reg pwr_up;
input rst_n, clk, RX, rider_off;

logic [7:0]rx_data;
logic rx_rdy;
logic clr_rx_rdy;
parameter [7:0]g = 8'h67;

parameter [7:0]s = 8'h73;

UART_rcv RECV( .clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rx_rdy), .rx_data(rx_data), .rdy(rx_rdy));

typedef enum reg[1:0]{IDLE, GO, WAIT_RD}state_t;
state_t state, nxt_state;

////////////////////////////////////////////////////////////////////////////////////////////
//SM starts
always_ff@(posedge clk, negedge rst_n)begin
	if(!rst_n) state <= IDLE;
	else state <= nxt_state;
	
end

always_comb begin
//default outputs 
pwr_up = 0;
clr_rx_rdy = 0;
nxt_state = IDLE;

case(state)
	IDLE : if( (!rider_off) && (rx_data == g) && (rx_rdy)) begin
				pwr_up = 1;
				nxt_state = GO;
	  	end
			else nxt_state =  IDLE;
			
			//when rider leaves and we received stop signal
	GO : if(rider_off && (rx_data == s ) && rx_rdy) begin
				pwr_up =0;
				nxt_state = IDLE;
				clr_rx_rdy = 1;
		end
			//but if rider is not off with stop signal, segway is still powered up
		else if( (!rider_off) && (rx_data == s ) && rx_rdy )begin
				pwr_up = 1;
				nxt_state = WAIT_RD;
			 end
			 else begin 
				nxt_state = GO;
				pwr_up =1;
			end

	WAIT_RD: if(rider_off) begin
			nxt_state = IDLE;
			clr_rx_rdy = 1;
			pwr_up = 0;
			end
		  else begin
			pwr_up = 1;
			nxt_state = WAIT_RD;
		  end
			
endcase


end


endmodule




