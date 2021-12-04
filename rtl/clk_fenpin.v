module clk_fenpin(
	input clk,
	input rst_n,
	output reg clk_1m
);

	reg    [25:0]   clk_cnt     ;        //分频计数器
	//得到1Mhz分频时钟
	always @ (posedge clk or negedge rst_n) begin
		 if (!rst_n) begin
			  clk_cnt <= 5'd0;
			  clk_1m  <= 1'b0;
		 end 
		 else if (clk_cnt < 26'd24) 
			  clk_cnt <= clk_cnt + 1'b1;       
		 else begin
			  clk_cnt <= 5'd0;
			  clk_1m  <= ~ clk_1m;
		 end 
	end

endmodule