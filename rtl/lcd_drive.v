module lcd_drive(
	input clk,		//时钟信号 50m
	input rst_n,	//按键复位
	output scl,		//iic scl
	inout sda		//iic sda
);

wire clk_1m;		//1m的时钟信号
wire done_write;	//一次数据/命令写完成
wire [7:0] data;	//写的字节
wire cmd_data;		//数据还是命令 0：命令，1：数据
wire ena_write;	//使能写数据/命令模块

//时钟分频模块 产生1M的时钟
clk_fenpin clk_fenpin_inst(
	.clk(clk),
	.rst_n(rst_n),
	.clk_1m(clk_1m)
);

//lcd初始化模块
lcd_init u_lcd_init(
	.clk(clk_1m),
	.rst_n(rst_n),
	.ena(1'b1),
	.done_write(done_write),
	.data(data),
	.cmd_data(cmd_data),
	.ena_write(ena_write)
);

//lcd写命令/数据模块
lcd_write_cmd_data u_lcd_write_cmd_data(
	.clk(clk_1m),
	.rst_n(rst_n),
	.ena(ena_write),
	.data(data),
	.cmd_data(cmd_data),
	.sda(sda),
	.scl(scl),
	.done(done_write)
);

endmodule