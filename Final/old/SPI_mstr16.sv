module SPI_mstr16(rd_data, MOSI, done, SCLK, SS_n, clk, rst_n, MISO, wrt, cmd);
    	input clk, rst_n, MISO, wrt;
	input [15:0] cmd;
  	output reg SS_n, SCLK, done, MOSI; 
    	output reg [15:0] rd_data;

	reg [15:0] shft_reg;
	reg [4:0] sclk_div, smpl_cnt, shft_cnt;
	reg MISO_smpl, init, shft, smpl, set_done, clr_done, rst_cnt;

	typedef enum {IDLE, FRONT, SHIFT, BACK} state_t;
	state_t next_state, state;

	localparam SCLK_DIV_DEF = 5'b10111; //Param for given default sclk value
	localparam SCLK_DIV_SMPL = 5'b01111; //Param for rising edge of sclk
	localparam SCLK_DIV_SHFT = 5'b11111; //Param for falling edge of sclk
	
	//sclk counter
	always @(posedge clk) begin
    		if (rst_cnt) sclk_div <= SCLK_DIV_DEF;
    		else sclk_div <= sclk_div + 1;
    		SCLK <= sclk_div[4];
	end

	//shfr_reg flop, shifts in sample of MISO on falling sclk edge
	always @(posedge clk) begin
    		if (wrt) shft_reg <= cmd;
    		else if (shft) shft_reg <= {shft_reg[14:0],MISO_smpl};
    		else shft_reg <= shft_reg;
    		MOSI <= shft_reg[15];
	end

	//Counter to track number of samples taken
	always @(posedge clk) begin
    		if (init) smpl_cnt <= 0;
    		else if (smpl) smpl_cnt <= smpl_cnt + 1;
    		else smpl_cnt <= smpl_cnt;
	end
    
	//Counter to track number of shifts that have been performed
	always @(posedge clk) begin
    		if (init) shft_cnt <= 0;
    		else if (shft) shft_cnt <= shft_cnt + 1;
    		else shft_cnt <= shft_cnt;
	end

	//MISO_smpl samples MISO on rising sclk edge
	always @(posedge clk) begin
    		if (smpl) MISO_smpl <= MISO;
    		else MISO_smpl <= MISO_smpl;
	end

	//SS_n block, with preset
	always @(posedge clk, negedge rst_n) begin
    		if (!rst_n) SS_n <= 1;
    		else if (clr_done) SS_n <= 0;
    		else if (set_done) SS_n <= 1;
    		else SS_n <= SS_n;
	end

	//done block, asserted when all 16 bits have been processed and shifted in
	always @(posedge clk, negedge rst_n) begin
    		if (!rst_n) done <= 0;
    		else if (clr_done) done <= 0;
    		else if (set_done) done <= 1;
    		else done <= done;
	end

	//State transition flop
	always_ff @(posedge clk, negedge rst_n) begin
    		if (!rst_n) state <= IDLE;
    		else state <= next_state;
	end

	assign rd_data = shft_reg;

	always_comb begin
    		rst_cnt = 0;
    		shft = 0;
    		smpl = 0;
    		init = 0; //Value to reset shift and sample counts when in IDLE
		set_done = 0;
    		clr_done = 0;
		next_state = IDLE;
    		case(state)
        		IDLE: 
			begin
				rst_cnt = 1;
            			init = 1;
            			if (wrt) begin
               		 		clr_done = 1; //After done is asserted it should stay high until the next wrt is asserted
                			next_state = FRONT;
            			end
         		end
            
       		 	FRONT: 
			begin    
				//The first falling edge of sclk should initialize shifting, but should not shift
            			if (sclk_div == SCLK_DIV_SHFT) begin
               	 			next_state = SHIFT;
            			end
            			else next_state = state;
        		end
        		SHIFT: 
			begin
				//Check if all necessary bits have been sampled
            			if (smpl_cnt == 5'd16) begin
                			next_state = BACK;
            			end
				//Shift on falling edge
            			else if (sclk_div == SCLK_DIV_SHFT) begin
                			shft = 1;
                			next_state = SHIFT;
            			end 
				//Sample on rising edge
            			else if (sclk_div == SCLK_DIV_SMPL) begin
                			smpl = 1;
                			next_state = SHIFT;
            			end
            			else next_state = state;
        		end
        		BACK: 
			begin
				//Check if all bits have been shifted in 
            			if (shft_cnt == 5'd16) begin
                			set_done = 1;
                			next_state = IDLE;
           	 		end
				//If all bits have been sampled, but not shifted, perform the final shift
            			else if (sclk_div == SCLK_DIV_SHFT) begin
                			rst_cnt = 1; //Assures that shift will be performed BUT sclk will not actually output a falling edge
					shft = 1;
                			next_state = BACK;
            			end 
            			else next_state = state; 
        		end
        		default: next_state = IDLE;
    		endcase
	end

endmodule


