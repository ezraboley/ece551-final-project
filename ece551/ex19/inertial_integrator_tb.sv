module inertial_integrator_tb();

reg clk, rst_n, vld;
reg [15:0] ptch_rt, AZ, ptch;


inertial_integrator iDUT(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch_rt(ptch_rt), .AZ(AZ), .ptch(ptch));

localparam PTCH_RT_OFFSET = 16'h03C2;


initial begin
    clk = 0;
    rst_n = 0;
    ptch_rt = 0;
    vld = 0;
    AZ = 0;
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    @(posedge clk); 
    vld = 1;
    AZ = 16'h0000;
    ptch_rt = 16'h1000 + PTCH_RT_OFFSET;
    repeat(500) @(posedge clk);
    
    ptch_rt = PTCH_RT_OFFSET;
    repeat(1000) @(posedge clk);

    ptch_rt = PTCH_RT_OFFSET - 16'h1000;
    repeat(500) @(posedge clk);

    ptch_rt = PTCH_RT_OFFSET;
    repeat(1000) @(posedge clk);
        
    AZ = 16'h0800;
    repeat(500) @(posedge clk);
	
    $display("SUCCESS");
    $stop();
end


always #5 clk = ~clk;

endmodule
