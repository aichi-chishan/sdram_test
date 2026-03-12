module sdram_fifo_ctrl(
    input   wire    I_ref_clk, I_rst_n, I_sdram_init_done,
    
    // WR0 (Camera)
    input I_wr0_clk, I_wr0_req, I_wr0_load,
    input [31:0] I_wr0_data, input [23:0] I_wr0_saddr, I_wr0_eaddr, input [9:0] I_wr0_burst,
    output reg O_sdram_wr0_req, input I_sdram_wr0_ack, output reg [23:0] O_sdram_wr0_addr, output [31:0] O_sdram_wr0_data,
    
    // RD0 (Screen)
    input I_rd0_clk, I_rd0_req, I_rd0_load,
    output [31:0] O_rd0_data, input [23:0] I_rd0_saddr, I_rd0_eaddr, input [9:0] I_rd0_burst,
    output reg O_sdram_rd0_req, input I_sdram_rd0_ack, output reg [23:0] O_sdram_rd0_addr, input [31:0] I_sdram_rd0_data,
    
    // RD1 (Algo A)
    input I_rd1_clk, I_rd1_req, I_rd1_load,
    output [31:0] O_rd1_data, input [23:0] I_rd1_saddr, I_rd1_eaddr, input [9:0] I_rd1_burst,
    output reg O_sdram_rd1_req, input I_sdram_rd1_ack, output reg [23:0] O_sdram_rd1_addr, input [31:0] I_sdram_rd1_data,
    
    // RD2 (Algo B)
    input I_rd2_clk, I_rd2_req, I_rd2_load,
    output [31:0] O_rd2_data, input [23:0] I_rd2_saddr, I_rd2_eaddr, input [9:0] I_rd2_burst,
    output reg O_sdram_rd2_req, input I_sdram_rd2_ack, output reg [23:0] O_sdram_rd2_addr, input [31:0] I_sdram_rd2_data,
    
    // WR1 (Algo Write)
    input I_wr1_clk, I_wr1_req, I_wr1_load,
    input [31:0] I_wr1_data, input [23:0] I_wr1_saddr, I_wr1_eaddr, input [9:0] I_wr1_burst,
    output reg O_sdram_wr1_req, input I_sdram_wr1_ack, output reg [23:0] O_sdram_wr1_addr, output [31:0] O_sdram_wr1_data
);

    // ====== 通用边沿检测宏定义 ======
    reg wr0_ld_r1, wr0_ld_r2; wire wr0_ld_p = ~wr0_ld_r2 & wr0_ld_r1;
    reg rd0_ld_r1, rd0_ld_r2; wire rd0_ld_p = ~rd0_ld_r2 & rd0_ld_r1;
    reg rd1_ld_r1, rd1_ld_r2; wire rd1_ld_p = ~rd1_ld_r2 & rd1_ld_r1;
    reg rd2_ld_r1, rd2_ld_r2; wire rd2_ld_p = ~rd2_ld_r2 & rd2_ld_r1;
    reg wr1_ld_r1, wr1_ld_r2; wire wr1_ld_p = ~wr1_ld_r2 & wr1_ld_r1;

    reg wr0_ack_r1, wr0_ack_r2; wire wr0_ack_n = wr0_ack_r2 & ~wr0_ack_r1;
    reg rd0_ack_r1, rd0_ack_r2; wire rd0_ack_n = rd0_ack_r2 & ~rd0_ack_r1;
    reg rd1_ack_r1, rd1_ack_r2; wire rd1_ack_n = rd1_ack_r2 & ~rd1_ack_r1;
    reg rd2_ack_r1, rd2_ack_r2; wire rd2_ack_n = rd2_ack_r2 & ~rd2_ack_r1;
    reg wr1_ack_r1, wr1_ack_r2; wire wr1_ack_n = wr1_ack_r2 & ~wr1_ack_r1;

    always @(posedge I_ref_clk) begin
        wr0_ld_r1<=I_wr0_load; wr0_ld_r2<=wr0_ld_r1; rd0_ld_r1<=I_rd0_load; rd0_ld_r2<=rd0_ld_r1;
        rd1_ld_r1<=I_rd1_load; rd1_ld_r2<=rd1_ld_r1; rd2_ld_r1<=I_rd2_load; rd2_ld_r2<=rd2_ld_r1;
        wr1_ld_r1<=I_wr1_load; wr1_ld_r2<=wr1_ld_r1;
        wr0_ack_r1<=I_sdram_wr0_ack; wr0_ack_r2<=wr0_ack_r1; rd0_ack_r1<=I_sdram_rd0_ack; rd0_ack_r2<=rd0_ack_r1;
        rd1_ack_r1<=I_sdram_rd1_ack; rd1_ack_r2<=rd1_ack_r1; rd2_ack_r1<=I_sdram_rd2_ack; rd2_ack_r2<=rd2_ack_r1;
        wr1_ack_r1<=I_sdram_wr1_ack; wr1_ack_r2<=wr1_ack_r1;
    end

    // ====== 地址生成逻辑 ======
    always @(posedge I_ref_clk or negedge I_rst_n) begin
        if(!I_rst_n) O_sdram_wr0_addr <= 0;
        else if(wr0_ld_p) O_sdram_wr0_addr <= I_wr0_saddr;
        else if(wr0_ack_n) O_sdram_wr0_addr <= (O_sdram_wr0_addr < I_wr0_eaddr-I_wr0_burst) ? O_sdram_wr0_addr+I_wr0_burst : I_wr0_saddr;
    end
    always @(posedge I_ref_clk or negedge I_rst_n) begin
        if(!I_rst_n) O_sdram_rd0_addr <= 0;
        else if(rd0_ld_p) O_sdram_rd0_addr <= I_rd0_saddr;
        else if(rd0_ack_n) O_sdram_rd0_addr <= (O_sdram_rd0_addr < I_rd0_eaddr-I_rd0_burst) ? O_sdram_rd0_addr+I_rd0_burst : I_rd0_saddr;
    end
    always @(posedge I_ref_clk or negedge I_rst_n) begin
        if(!I_rst_n) O_sdram_rd1_addr <= 0;
        else if(rd1_ld_p) O_sdram_rd1_addr <= I_rd1_saddr;
        else if(rd1_ack_n) O_sdram_rd1_addr <= (O_sdram_rd1_addr < I_rd1_eaddr-I_rd1_burst) ? O_sdram_rd1_addr+I_rd1_burst : I_rd1_saddr;
    end
    always @(posedge I_ref_clk or negedge I_rst_n) begin
        if(!I_rst_n) O_sdram_rd2_addr <= 0;
        else if(rd2_ld_p) O_sdram_rd2_addr <= I_rd2_saddr;
        else if(rd2_ack_n) O_sdram_rd2_addr <= (O_sdram_rd2_addr < I_rd2_eaddr-I_rd2_burst) ? O_sdram_rd2_addr+I_rd2_burst : I_rd2_saddr;
    end
    always @(posedge I_ref_clk or negedge I_rst_n) begin
        if(!I_rst_n) O_sdram_wr1_addr <= 0;
        else if(wr1_ld_p) O_sdram_wr1_addr <= I_wr1_saddr;
        else if(wr1_ack_n) O_sdram_wr1_addr <= (O_sdram_wr1_addr < I_wr1_eaddr-I_wr1_burst) ? O_sdram_wr1_addr+I_wr1_burst : I_wr1_saddr;
    end

    // ====== FIFO 例化及请求逻辑 ======
    wire [9:0] wr0_use, rd0_use, rd1_use, rd2_use, wr1_use;
    
    // 修改读请求判断（深度为1024时，10位宽最大值为1023）
    O_sdram_rd0_req <= ((10'd1023 - rd0_use) >= I_rd0_burst); 
    O_sdram_rd1_req <= ((10'd1023 - rd1_use) >= I_rd1_burst);
    O_sdram_rd2_req <= ((10'd1023 - rd2_use) >= I_rd2_burst);

    always @(posedge I_ref_clk or negedge I_rst_n) begin
    if(!I_rst_n) begin 
        O_sdram_wr0_req<=0; O_sdram_rd0_req<=0; O_sdram_rd1_req<=0; O_sdram_rd2_req<=0; O_sdram_wr1_req<=0; 
    end
    else if(I_sdram_init_done) begin
        // 写FIFO：判断FIFO内已有的数据是否足够一个Burst
        O_sdram_wr0_req <= (wr0_use >= I_wr0_burst);
        O_sdram_wr1_req <= (wr1_use >= I_wr1_burst);
        
        // 读FIFO：判断FIFO内剩余的空间是否足够容纳从SDRAM读出的一个Burst
        O_sdram_rd0_req <= ((11'd1024 - rd0_use) >= I_rd0_burst);
        O_sdram_rd1_req <= ((11'd1024 - rd1_use) >= I_rd1_burst);
        O_sdram_rd2_req <= ((11'd1024 - rd2_use) >= I_rd2_burst);
    end
end

    async_fifo_32x1024 fifo_wr0 (
        .wrclk(I_wr0_clk), 
        .rdclk(I_ref_clk), 
        .wrreq(I_wr0_req), 
        .rdreq(I_sdram_wr0_ack), 
        .data(I_wr0_data), 
        .q(O_sdram_wr0_data), 
        .aclr(~I_rst_n|wr0_ld_p), 
        .rdusedw(wr0_use)
    );
    async_fifo_32x1024 fifo_rd0 (.wrclk(I_ref_clk), .rdclk(I_rd0_clk), .wrreq(I_sdram_rd0_ack), .rdreq(I_rd0_req), .data(I_sdram_rd0_data), .q(O_rd0_data), .aclr(~I_rst_n|rd0_ld_p), .wrusedw(rd0_use));
    async_fifo_32x1024 fifo_rd1 (.wrclk(I_ref_clk), .rdclk(I_rd1_clk), .wrreq(I_sdram_rd1_ack), .rdreq(I_rd1_req), .data(I_sdram_rd1_data), .q(O_rd1_data), .aclr(~I_rst_n|rd1_ld_p), .wrusedw(rd1_use));
    async_fifo_32x1024 fifo_rd2 (.wrclk(I_ref_clk), .rdclk(I_rd2_clk), .wrreq(I_sdram_rd2_ack), .rdreq(I_rd2_req), .data(I_sdram_rd2_data), .q(O_rd2_data), .aclr(~I_rst_n|rd2_ld_p), .wrusedw(rd2_use));
    async_fifo_32x1024 fifo_wr1 (.wrclk(I_wr1_clk), .rdclk(I_ref_clk), .wrreq(I_wr1_req), .rdreq(I_sdram_wr1_ack), .data(I_wr1_data), .q(O_sdram_wr1_data), .aclr(~I_rst_n|wr1_ld_p), .rdusedw(wr1_use));

endmodule