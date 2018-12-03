module SPI_mstr16(
    input clk, rst_n,
    output reg SS_n, 	// Slave Select
    output reg SCLK, 
    input MISO,			
    input wrt,
    input [15:0] cmd,	//incoming command
    output reg done,	//transmission done
    output reg MOSI,
    output reg [15:0] rd_data	// full data reg
); 

typedef enum reg [1:0] {IDLE, FRONT_PORCH, SHIFT, BACK_PORCH} state_t;
state_t nxt_state, state;	// States, curr and next

// Definitions for clarity, mostly for counting thresholds
localparam DEFAULT_SCLK_DIV = 5'b10111;
localparam SCLK_DIV_FULL    = 5'b01111;
localparam SCLK_DIV_SHFT    = 5'b11111;
localparam MAX_BIT_SMPL_CNT = 5'd16;



reg [15:0] shft_reg;	// Register bits are shifted through

reg [4:0] sclk_div;		// Keeps track of SCLK
reg MISO_smpl;			// Incoming sample before it goes in shift reg

reg [4:0] bit_cnt, shft_cnt;	// how bits have been sampled/shifted

reg shft, smpl, init, set_done, clr_done, rst_cnt; // Flags for state machine

// State transition logic
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else state <= nxt_state;
end

// State machine
always_comb begin
    set_done = 0;
    clr_done = 0;
    rst_cnt = 0;
    shft = 0;
    smpl = 0;
    init = 0;
    nxt_state = IDLE;
    case(state)
        IDLE: begin	// Waits for a request to transmit and then sets it to not done
            if (wrt) begin
                clr_done = 1;
                nxt_state = FRONT_PORCH;
            end
            rst_cnt = 1;
            init = 1;
         end
            
        FRONT_PORCH: begin    // Starts the sclk count and SS_N is low, but shouldnt shift yet
            if (sclk_div == SCLK_DIV_SHFT) begin
                nxt_state = SHIFT;
            end
            else nxt_state = state;
        end
        SHIFT: begin	// Shifting and sampling until all 16 bits are sampled, and 15 shifts
            if (bit_cnt == MAX_BIT_SMPL_CNT) begin
                nxt_state = BACK_PORCH;
            end
            else if (sclk_div == SCLK_DIV_SHFT) begin
                shft = 1;
                nxt_state = SHIFT;
            end 
            else if (sclk_div == SCLK_DIV_FULL) begin
                smpl = 1;
                nxt_state = SHIFT;
            end
            else nxt_state = state;
        end
        BACK_PORCH: begin	// Last shift, then sets that data is ready
            if (shft_cnt == MAX_BIT_SMPL_CNT) begin
                set_done = 1;
            end
            else if (sclk_div == SCLK_DIV_SHFT) begin
                shft = 1;
                rst_cnt = 1;
                nxt_state = state;
            end 
            else nxt_state = state; 
        end
        default: begin
            nxt_state = IDLE;
        end
            
    endcase
end

// Sets SS_n based on if we are done
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) SS_n <= 1;
    else if (clr_done) SS_n <= 0;
    else if (set_done) SS_n <= 1;
    else SS_n <= SS_n;
end

// Sets done from SM
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) done <= 0;
    else if (clr_done) done <= 0;
    else if (set_done) done <= 1;
    else done <= done;
end

// Counts number of bits sampled
always @(posedge clk) begin
    if (init) bit_cnt <= 0;
    else if (smpl) bit_cnt <= bit_cnt + 1;
    else bit_cnt <= bit_cnt;
end
    
// Number of bits shifted
always @(posedge clk) begin
    if (init) shft_cnt <= 0;
    else if (shft) shft_cnt <= shft_cnt + 1;
    else shft_cnt <= shft_cnt;
end

always @(posedge clk) begin
    if (rst_cnt) sclk_div <= DEFAULT_SCLK_DIV;
    else sclk_div <= sclk_div + 1;
    SCLK <= sclk_div[4];
end

// Puts the new sample in a buffer reg before shifter
always @(posedge clk) begin
    if (smpl) MISO_smpl <= MISO;
    else MISO_smpl <= MISO_smpl;
end

assign rd_data = shft_reg;	// Data out is the shift reg

// Loads in a new command or shifts data in 
always @(posedge clk) begin
    if (wrt) begin
        shft_reg <= cmd;
    end
    else if (shft) begin
        shft_reg <= {shft_reg[14:0], MISO_smpl};
    end
    else begin
        shft_reg <= shft_reg;
    end
    MOSI <= shft_reg[15];
end

endmodule

