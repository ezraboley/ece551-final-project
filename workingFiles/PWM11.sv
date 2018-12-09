module PWM11(clk, rst_n, duty, PWM_sig);

input clk, rst_n;
input [10:0] duty;
output reg PWM_sig;

reg [10:0] cnt;
wire set, reset;

assign set = |cnt ? 0 : 1;

assign reset = (cnt >= duty) ? 1 : 0;

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        cnt <= 11'h000;
    else
        cnt <= cnt + 1;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        PWM_sig <= 0;
    else if(reset)
	PWM_sig <= 0;
    else if(set)
        PWM_sig <= 1;
    
end

endmodule
