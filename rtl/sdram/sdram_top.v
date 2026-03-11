module sdram_top(
    input wire I_ref_clk, 
    input wire I_out_clk, 
    input wire I_rst_n,
    
    // WR0 (Camera)
    input wire I_wr0_clk, 
    input wire I_wr0_req, 
    input wire I_wr0_load,
    input wire [31:0] I_wr0_data, 
    input wire [23:0] I_wr0_saddr, 
    input wire I_wr0_eaddr, 
    input wire [9:0] I_wr0_burst,

    // RD0 (Screen)
    input wire I_rd0_clk, 
    input wire I_rd0_req, 
    input wire I_rd0_load,
    output wire [31:0] O_rd0_data, 
    input wire [23:0] I_rd0_saddr, 
    input wire I_rd0_eaddr, 
    input wire [9:0] I_rd0_burst,

    // RD1 (Algo A)
    input wire I_rd1_clk, 
    input wire I_rd1_req, 
    input wire I_rd1_load,
    output wire [31:0] O_rd1_data, 
    input wire [23:0] I_rd1_saddr, 
    input wire I_rd1_eaddr, 
    input wire [9:0] I_rd1_burst,

    // RD2 (Algo B)
    input wire I_rd2_clk, 
    input wire I_rd2_req, 
    input wire I_rd2_load,
    output wire [31:0] O_rd2_data, 
    input wire [23:0] I_rd2_saddr, 
    input wire I_rd2_eaddr, 
    input wire [9:0] I_rd2_burst,

    // WR1 (Algo Write)
    input wire I_wr1_clk, 
    input wire I_wr1_req, 
    input wire I_wr1_load,
    input wire [31:0] I_wr1_data, 
    input wire [23:0] I_wr1_saddr, 
    input wire I_wr1_eaddr, 
    input wire [9:0] I_wr1_burst,

    // SDRAM initialization complete flag
    output  wire    O_sdram_init_done,  

    // SDRAM chip interface
    output  wire  O_sdram_clk, 
    output  wire  O_sdram_cke, 
    output  wire  O_sdram_cs_n, 
    output  wire  O_sdram_ras_n, 
    output  wire  O_sdram_cas_n, 
    output  wire  O_sdram_we_n,
    output  wire  [1:0]  O_sdram_bank,  
    output  wire  [12:0] O_sdram_addr, 
    inout   wire  [31:0] IO_sdram_dq,
    output  wire  [3:0]  O_sdram_dqm
);

    assign O_sdram_clk = I_out_clk;
    assign O_sdram_dqm = 4'b0000; // 全部开启数据屏蔽

    wire wr0_req, rd0_req, rd1_req, rd2_req, wr1_req;
    wire wr0_ack, rd0_ack, rd1_ack, rd2_ack, wr1_ack;
    wire [23:0] wr0_addr, rd0_addr, rd1_addr, rd2_addr, wr1_addr;
    wire [31:0] wr0_data, rd0_data, rd1_data, rd2_data, wr1_data;

    sdram_fifo_ctrl sdram_fifo_ctrl(
        .I_ref_clk(I_ref_clk), .I_rst_n(I_rst_n), .I_sdram_init_done(O_sdram_init_done),
        .I_wr0_clk(I_wr0_clk), .I_wr0_req(I_wr0_req), .I_wr0_load(I_wr0_load), .I_wr0_data(I_wr0_data), .I_wr0_saddr(I_wr0_saddr), .I_wr0_eaddr(I_wr0_eaddr), .I_wr0_burst(I_wr0_burst),
        .O_sdram_wr0_req(wr0_req), .I_sdram_wr0_ack(wr0_ack), .O_sdram_wr0_addr(wr0_addr), .O_sdram_wr0_data(wr0_data),

        .I_rd0_clk(I_rd0_clk), .I_rd0_req(I_rd0_req), .I_rd0_load(I_rd0_load), .O_rd0_data(O_rd0_data), .I_rd0_saddr(I_rd0_saddr), .I_rd0_eaddr(I_rd0_eaddr), .I_rd0_burst(I_rd0_burst),
        .O_sdram_rd0_req(rd0_req), .I_sdram_rd0_ack(rd0_ack), .O_sdram_rd0_addr(rd0_addr), .I_sdram_rd0_data(rd0_data),

        .I_rd1_clk(I_rd1_clk), .I_rd1_req(I_rd1_req), .I_rd1_load(I_rd1_load), .O_rd1_data(O_rd1_data), .I_rd1_saddr(I_rd1_saddr), .I_rd1_eaddr(I_rd1_eaddr), .I_rd1_burst(I_rd1_burst),
        .O_sdram_rd1_req(rd1_req), .I_sdram_rd1_ack(rd1_ack), .O_sdram_rd1_addr(rd1_addr), .I_sdram_rd1_data(rd1_data),

        .I_rd2_clk(I_rd2_clk), .I_rd2_req(I_rd2_req), .I_rd2_load(I_rd2_load), .O_rd2_data(O_rd2_data), .I_rd2_saddr(I_rd2_saddr), .I_rd2_eaddr(I_rd2_eaddr), .I_rd2_burst(I_rd2_burst),
        .O_sdram_rd2_req(rd2_req), .I_sdram_rd2_ack(rd2_ack), .O_sdram_rd2_addr(rd2_addr), .I_sdram_rd2_data(rd2_data),

        .I_wr1_clk(I_wr1_clk), .I_wr1_req(I_wr1_req), .I_wr1_load(I_wr1_load), .I_wr1_data(I_wr1_data), .I_wr1_saddr(I_wr1_saddr), .I_wr1_eaddr(I_wr1_eaddr), .I_wr1_burst(I_wr1_burst),
        .O_sdram_wr1_req(wr1_req), .I_sdram_wr1_ack(wr1_ack), .O_sdram_wr1_addr(wr1_addr), .O_sdram_wr1_data(wr1_data)
    );

    sdram_control sdram_control(
        .I_ref_clk(I_ref_clk), .I_rst_n(I_rst_n),
        .I_wr0_req(wr0_req), .O_wr0_ack(wr0_ack), .I_wr0_addr(wr0_addr), .I_wr0_burst(I_wr0_burst), .I_wr0_data(wr0_data),
        .I_rd0_req(rd0_req), .O_rd0_ack(rd0_ack), .I_rd0_addr(rd0_addr), .I_rd0_burst(I_rd0_burst), .O_rd0_data(rd0_data),
        .I_rd1_req(rd1_req), .O_rd1_ack(rd1_ack), .I_rd1_addr(rd1_addr), .I_rd1_burst(I_rd1_burst), .O_rd1_data(rd1_data),
        .I_rd2_req(rd2_req), .O_rd2_ack(rd2_ack), .I_rd2_addr(rd2_addr), .I_rd2_burst(I_rd2_burst), .O_rd2_data(rd2_data),
        .I_wr1_req(wr1_req), .O_wr1_ack(wr1_ack), .I_wr1_addr(wr1_addr), .I_wr1_burst(I_wr1_burst), .I_wr1_data(wr1_data),
        .O_sdram_init_done(O_sdram_init_done),
        .O_sdram_cke(O_sdram_cke), .O_sdram_cs_n(O_sdram_cs_n), .O_sdram_ras_n(O_sdram_ras_n),
        .O_sdram_cas_n(O_sdram_cas_n), .O_sdram_we_n(O_sdram_we_n), .O_sdram_bank(O_sdram_bank),
        .O_sdram_addr(O_sdram_addr), .IO_sdram_dq(IO_sdram_dq)
    );

endmodule