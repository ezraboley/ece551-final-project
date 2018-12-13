module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;

output reg rst_n;

reg stability_val;

always_ff@(negedge clk, negedge RST_n) begin
    if(!RST_n)
         stability_val <= 0;
    else
         stability_val <= 1;
end

always_ff@(negedge clk) begin
    if(!RST_n)
         rst_n <= 0;
    else
         rst_n <= stability_val;
end

endmodule
