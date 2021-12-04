module myiic_writebyte(
	input clk,					//时钟 1m
	input rst_n,				//按键复位
	input en_write,			//模块使能
	input [7:0] data,			//要写的数据
	inout  sda,					//iic sda
	output reg scl,			//iic scl
	output done,				//写一个字节完成
	output reg sda_dir		//sda的方向
);

parameter DELAY = 5;			//延时 每次信号拉低或者拉高都延时 5us
reg [20:0] us_cnt;			//us计数器
reg us_cnt_clr;				//计数器清零信号

//状态说明
//等待模块使能
//iic 开始	scl为高时，sda从高到低
//scl低电平
//scl高电平
//准备进入停止状态 scl拉低（我没有拉低的时候一直收不到ack，，）
//iic 停止	scl为高时，sda从低到高？？
parameter WaitEn=0,Start=1,WriteL=2,WriteH=3,ReadyStop=4,Stop=5,WaitAck=6,Done=7;
reg[2:0] state,next_state;	//当前状态和下一个状态
reg [3:0] cnt;					//位计数器
reg sda_out;					//sda输出
wire sda_in;					//sda输入

//sda由sda_dir控制输出还是输入，sda_dir为0时为输入，释放sda
assign sda = sda_dir ? sda_out : 1'bz;
assign sda_in = sda;			//得到sda输入


//1微秒计数器
always @ (posedge clk,negedge rst_n) begin
    if (!rst_n)
        us_cnt <= 21'd0;
    else if (us_cnt_clr)
        us_cnt <= 21'd0;
    else 
        us_cnt <= us_cnt + 1'b1;
end 

//下一个状态确认
always @(*) begin
	if(!rst_n)
		next_state <= WaitEn;//复位到初始状态
	else begin
		case(state)
			//等待模块使能
			WaitEn: next_state = en_write ? Start : WaitEn;
			
			//iic开始
			Start: next_state = (us_cnt == DELAY) ? WriteL : Start;
			
			//scl低电平
			WriteL: next_state = (us_cnt == DELAY) ? WriteH : WriteL;
			
			//scl高电平
			//延时到了且此时已经8位写完成 则准备进入停止状态，负责延时完成则继续写下一个位
			WriteH: next_state = (us_cnt == DELAY && cnt == 4'd8) ? ReadyStop : ((us_cnt == DELAY) ? WriteL : WriteH);
			
			//准备进入停止状态
			ReadyStop: next_state = (us_cnt == DELAY) ? Stop : ReadyStop;
			
			//停止
			Stop: next_state = (us_cnt == DELAY) ? WaitAck : Stop;
			
			//等待ack
			WaitAck: next_state = (sda_in == 1'b0) ? Done : WaitAck;
			
			//完成写
			Done: next_state = WaitEn;
		endcase
	end
end

//状态各变量赋值
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)begin
		sda_dir <= 1'b1;					//初始sda输出
		sda_out <= 1'b1;					//空闲状态sda为高
		scl <= 1'b1;						//空闲状态scl为高
		us_cnt_clr <= 1'b1;				//计数器复位
	end
	else begin
		case(state)
			WaitEn:begin
				sda_dir <= 1'b1;			//初始sda输出
				sda_out <= 1'b1;			//空闲状态sda为高
				scl <= 1'b1;				//空闲状态scl为高
				us_cnt_clr <= 1'b1;		//计数器复位
			end
			
			Start:begin
				sda_dir <= 1'b1;			//sda输出
				sda_out = 1'b0;			//sda拉低
				us_cnt_clr <= (us_cnt == DELAY-1) ? 1'b1 : 1'b0;//延时等待
			end
			
			WriteL:begin
				scl <= 1'b0;				//scl拉低 准备寄存数据
				sda_out <= data[7-(cnt-1)] ? 1'b1 : 1'b0;//数据数值
				us_cnt_clr <= (us_cnt == DELAY-1) ? 1'b1 : 1'b0;//延时等待
			end
			
			WriteH:begin
				scl <= 1'b1;				//scl拉高 发送数据
				us_cnt_clr <= (us_cnt == DELAY-1) ? 1'b1 : 1'b0;//延时等待
			end
			
			ReadyStop:begin
			scl <= 1'b0;					//scl 拉低（其实不是很明白这个位置为什么要拉低，，一直高电平不行吗）
				us_cnt_clr <= (us_cnt == DELAY-1) ? 1'b1 : 1'b0;//延时等待
			end
			
			Stop:begin
				sda_out <= 1'b1;			//sda拉高 产生停止信号
				scl <= 1'b1;				//scl拉低
				us_cnt_clr <= (us_cnt == DELAY-1) ? 1'b1 : 1'b0;//延时等待
			end
			
			//等待ack
			WaitAck:begin
				sda_dir <= 1'b0; 			//改变sda方向，释放sda，等待ack
				us_cnt_clr <= 1'b1;		//计数器复位
			end
			
			//完成写一个字节
			Done:begin			
				sda_dir <= 1'b1; 
				sda_out <= 1'b1;
				scl <= 1'b1;
				us_cnt_clr <= 1'b1;
			end
		endcase
	end
end

//状态流转
always @(posedge clk,negedge rst_n)begin
	if(!rst_n)
		state <= WaitEn;
	else
		state <= next_state;
end

//计数器计数
always @(posedge clk,negedge rst_n)begin
	if(!rst_n)
		cnt <= 4'd0;
	else begin
		case(state)
			//scl低电平且此时延时计数为0时，计数器加1，保证等待的时候不会一直加
			WriteL:cnt <=  (us_cnt == 1'b0) ? cnt + 1'b1 : cnt;
			//等待模块使能的时候要清零
			WaitEn:cnt <=4'd0;
			//完成状态也要清零
			Done:cnt <=4'd0;
			//其他状态保持不变
			default:cnt <= cnt;
		endcase
	end
		
end

//完成信号输出
assign done = (state == Done);

endmodule