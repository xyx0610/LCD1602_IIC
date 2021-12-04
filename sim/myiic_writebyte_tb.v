`timescale 1ns/1ns //仿真单位为1ns，精度为1ns
module myiic_writebyte_tb();
	reg clk;
	reg rst_n;
	reg en_write;
	reg [7:0]data;
	wire sda;
	wire scl;
	wire done;
	
	wire sda_dir;
	
	reg sda_in;
	
	assign sda = sda_dir ? 1'bz : sda_in;
	
	myiic_writebyte myiic_writebyte_inst(
		.clk(clk),
		.rst_n(rst_n),
		.en_write(en_write),
		.data(data),
		.sda(sda),
		.scl(scl),
		.sda_dir(sda_dir),
		.done(done)
	);
	
	initial begin
		#0 	clk = 0;
				rst_n = 0;
				data = 8'b11010100;
				en_write = 1;
				sda_in = 1;
			
		#20	rst_n = 1;
		
		#3000 sda_in = 0;
	end
	
	always #5 clk = ~clk;

endmodule