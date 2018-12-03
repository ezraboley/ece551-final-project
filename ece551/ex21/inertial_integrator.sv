module inertial_integrator(
    input clk,
    input rst_n,
    input vld,
    input signed [15:0] ptch_rt,
    input signed [15:0] AZ,
    input pwr_up;
    output reg signed [15:0] ptch
);

localparam PTCH_RT_OFFSET = 16'h03C2;
localparam AZ_OFFSET      = 16'hFE80;

reg signed [26:0] ptch_int;
reg signed [15:0] ptch_rt_comp;
reg signed [15:0] AZ_comp;
reg signed [26:0] fusion_ptch_offset;
reg signed [26:0] ptch_acc_product;
reg signed [15:0] ptch_acc;



always @(posedge clk, negedge rst_n) begin
    if (!rst_n) ptch_int <= 0;
    else begin
        if (
        else if (vld) ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset;
        else ptch_int <= ptch_int;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) ptch_rt_comp <= 0;
    else begin
        if (vld) ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
        else ptch_rt_comp <= ptch_rt_comp;
    end
end


always_comb begin
    ptch_acc_product = AZ_comp * $signed(327);
    ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};

    if (ptch_acc > ptch) 
        fusion_ptch_offset = 27'h400;
    else
        fusion_ptch_offset = -27'h400;
end

assign AZ_comp = AZ - AZ_OFFSET;

assign ptch = ptch_int[26:11];


endmodule
