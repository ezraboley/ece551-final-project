module AUTH_blk(pwr_up, clk, rst_n, rider_off, RX);
	input clk, rst_n, rider_off, RX;
	output reg pwr_up;
	reg clr_rx_rdy, rx_rdy;
	reg[7:0] rx_data;
	wire stop, go;
	typedef enum{WAIT, PWR1, PWR2} state_t;
	state_t next_state, state;

	UART_rcv receiver(.RX(RX), .clk(clk), .rst_n(rst_n), .clr_rdy(clr_rx_rdy), .rx_data(rx_data), .rdy(rx_rdy));

	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= WAIT;
		else state <= next_state;
	end

	assign stop = (rx_data == 8'h73);
	assign go = (rx_data == 8'h67);

	always_comb begin
		clr_rx_rdy = 0;
		pwr_up = 0;
		next_state = WAIT;
		case(state)
			WAIT:
			begin
				if(go && rx_rdy) begin
					next_state = PWR1;
					clr_rx_rdy = 1;
				end
				else next_state = state;
			end
			PWR1:
			begin
				pwr_up = 1;
				if(rx_rdy && stop) begin
					if(rider_off) begin
						next_state = WAIT;
						clr_rx_rdy = 1;
					end
					else begin
						next_state = PWR2;
						clr_rx_rdy = 1;
					end
				end
				else next_state = state;
			end
			PWR2:
			begin
				pwr_up = 1;
				if(rider_off) begin
					next_state = WAIT;
					clr_rx_rdy = 1;
				end
				else if(go && rx_rdy) begin
					next_state = PWR1;
					clr_rx_rdy = 1;
				end
				else next_state = state;
			end
			default: next_state = WAIT;
		endcase
	end

endmodule
