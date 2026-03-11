module sdram_control(
    input   wire    I_ref_clk,  
    input   wire    I_rst_n,    

    input   wire    I_wr0_req, output O_wr0_ack, input [23:0] I_wr0_addr, input [9:0] I_wr0_burst, input [31:0] I_wr0_data,
    input   wire    I_rd0_req, output O_rd0_ack, input [23:0] I_rd0_addr, input [9:0] I_rd0_burst, output [31:0] O_rd0_data,
    input   wire    I_rd1_req, output O_rd1_ack, input [23:0] I_rd1_addr, input [9:0] I_rd1_burst, output [31:0] O_rd1_data,
    input   wire    I_rd2_req, output O_rd2_ack, input [23:0] I_rd2_addr, input [9:0] I_rd2_burst, output [31:0] O_rd2_data,
    input   wire    I_wr1_req, output O_wr1_ack, input [23:0] I_wr1_addr, input [9:0] I_wr1_burst, input [31:0] I_wr1_data,

    output  wire    O_sdram_init_done,  

    output  wire    O_sdram_cke, O_sdram_cs_n, O_sdram_ras_n, O_sdram_cas_n, O_sdram_we_n,
    output  wire    [1:0]  O_sdram_bank,  
    output  wire    [12:0] O_sdram_addr, 
    inout   wire    [31:0] IO_sdram_dq   
);

    wire [4:0] sdram_init_state;
    wire [3:0] sdram_work_state;
    wire [9:0] cnt_clk;
    wire sdram_rd_wr;
    wire [2:0] active_port;
    wire [9:0] active_burst;

    reg [23:0] active_addr;
    reg [31:0] active_wr_data;
    wire [31:0] sdram_rd_data_bus;

    // 路由 MUX
    always @(*) begin
        case(active_port)
            3'd0: begin active_addr = I_wr0_addr; active_wr_data = I_wr0_data; end
            3'd1: begin active_addr = I_rd0_addr; active_wr_data = 32'd0; end
            3'd2: begin active_addr = I_rd1_addr; active_wr_data = 32'd0; end
            3'd3: begin active_addr = I_rd2_addr; active_wr_data = 32'd0; end
            3'd4: begin active_addr = I_wr1_addr; active_wr_data = I_wr1_data; end
            default: begin active_addr = 24'd0; active_wr_data = 32'd0; end
        endcase
    end

    // 读数据广播分配 (依赖各个FIFO自身的ACK信号来判断是否存入FIFO)
    assign O_rd0_data = sdram_rd_data_bus;
    assign O_rd1_data = sdram_rd_data_bus;
    assign O_rd2_data = sdram_rd_data_bus;

    sdram_cmd sdram_cmd(
        .I_sys_clk(I_ref_clk), .I_rst_n(I_rst_n),
        .I_sdram_addr(active_addr), .I_sdram_burst(active_burst),
        .I_init_state(sdram_init_state), .I_work_state(sdram_work_state), .O_cnt_clk(cnt_clk),
        .O_sdram_cke(O_sdram_cke), .O_sdram_cs_n(O_sdram_cs_n), .O_sdram_ras_n(O_sdram_ras_n),
        .O_sdram_cas_n(O_sdram_cas_n), .O_sdram_we_n(O_sdram_we_n),
        .O_sdram_bank(O_sdram_bank), .O_sdram_addr(O_sdram_addr)
    );

    sdram_ctrl sdram_ctrl(
        .I_ref_clk(I_ref_clk), .I_rst_n(I_rst_n),
        .I_wr0_req(I_wr0_req), .O_wr0_ack(O_wr0_ack), .I_wr0_burst(I_wr0_burst),
        .I_rd0_req(I_rd0_req), .O_rd0_ack(O_rd0_ack), .I_rd0_burst(I_rd0_burst),
        .I_rd1_req(I_rd1_req), .O_rd1_ack(O_rd1_ack), .I_rd1_burst(I_rd1_burst),
        .I_rd2_req(I_rd2_req), .O_rd2_ack(O_rd2_ack), .I_rd2_burst(I_rd2_burst),
        .I_wr1_req(I_wr1_req), .O_wr1_ack(O_wr1_ack), .I_wr1_burst(I_wr1_burst),
        .O_active_port(active_port), .O_active_burst(active_burst),
        .O_sdram_init_done(O_sdram_init_done), .O_sdram_init_state(sdram_init_state),
        .O_sdram_work_state(sdram_work_state), .O_cnt_clk(cnt_clk), .O_sdram_rd_wr(sdram_rd_wr)
    );

    sdram_data sdram_data(
        .I_sys_clk(I_ref_clk), .I_rst_n(I_rst_n),
        .I_sdram_data(active_wr_data), .O_sdram_data(sdram_rd_data_bus),
        .I_work_state(sdram_work_state), .I_cnt_clk(cnt_clk), .IO_sdram_data(IO_sdram_dq)
    );
endmodule