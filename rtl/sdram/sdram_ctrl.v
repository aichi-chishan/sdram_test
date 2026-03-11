`include "sdram_param.v"
module sdram_ctrl(
    input   wire    I_ref_clk,  
    input   wire    I_rst_n,    

    input   wire    I_wr0_req, output O_wr0_ack, input [9:0] I_wr0_burst,
    input   wire    I_rd0_req, output O_rd0_ack, input [9:0] I_rd0_burst,
    input   wire    I_rd1_req, output O_rd1_ack, input [9:0] I_rd1_burst,
    input   wire    I_rd2_req, output O_rd2_ack, input [9:0] I_rd2_burst,
    input   wire    I_wr1_req, output O_wr1_ack, input [9:0] I_wr1_burst,

    output  wire    [2:0] O_active_port,  // 告知路由层当前端口
    output  wire    [9:0] O_active_burst, // 输出当前激活的burst

    output  wire    O_sdram_init_done,  
    output  reg     [4:0] O_sdram_init_state,   
    output  reg     [3:0] O_sdram_work_state,   
    output  reg     [9:0] O_cnt_clk,  
    output  reg     O_sdram_rd_wr   
);
    parameter   TRP = 10'd4, TRC = 10'd6, TRSC = 10'd6, TRCD = 10'd2,        
                TCL = 10'd4, TWR = 10'd2, T_200US = 15'd20_000, T_AUTO_AREF = 11'd781;

    reg [14:0] cnt_200us;
    reg [10:0] cnt_auto_ref;
    reg auto_ref_req;
    reg [3:0] init_arf_cnt;
    reg cnt_rst_n;

    wire t_200us_done = (cnt_200us == T_200US);
    assign O_sdram_init_done = (O_sdram_init_state == `I_DONE);
    wire sdram_ref_ack = (O_sdram_work_state == `ARF);

    reg [2:0] active_port;
    assign O_active_port = active_port;

    reg [9:0] active_burst;
    always @(*) begin
        case(active_port)
            3'd0: active_burst = I_wr0_burst;
            3'd1: active_burst = I_rd0_burst;
            3'd2: active_burst = I_rd1_burst;
            3'd3: active_burst = I_rd2_burst;
            3'd4: active_burst = I_wr1_burst;
            default: active_burst = 10'd0;
        endcase
    end
    assign O_active_burst = active_burst;

    wire end_twrite = (O_cnt_clk == active_burst - 1);
    wire end_tread  = (O_cnt_clk == active_burst + 2);

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) cnt_200us <= 'd0;
        else if(cnt_200us < T_200US) cnt_200us <= cnt_200us + 1'b1;
    end

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) cnt_auto_ref <= 'd0;
        else if(cnt_auto_ref < T_AUTO_AREF) cnt_auto_ref <= cnt_auto_ref + 1'b1;
        else cnt_auto_ref <= 'd0;
    end

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) auto_ref_req <= 1'b0;
        else if(cnt_auto_ref == T_AUTO_AREF-1) auto_ref_req <= 1'b1;
        else if(sdram_ref_ack) auto_ref_req <= 1'b0;
    end

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) O_cnt_clk <= 10'd0;
        else if(cnt_rst_n==1'b0) O_cnt_clk <= 10'd0;
        else O_cnt_clk <= O_cnt_clk + 1'b1;
    end

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) init_arf_cnt <= 4'd0;
        else if(O_sdram_init_state == `I_NOP) init_arf_cnt <= 4'd0;
        else if(O_sdram_init_state == `I_ARF) init_arf_cnt <= init_arf_cnt + 1'b1;
    end

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) O_sdram_init_state <= `I_NOP;
        else begin
            case(O_sdram_init_state)
                `I_NOP: O_sdram_init_state <= t_200us_done?`I_PCH:`I_NOP;
                `I_PCH: O_sdram_init_state <= `I_TRP;
                `I_TRP: O_sdram_init_state <= (`end_trp)?`I_ARF:`I_TRP;
                `I_ARF: O_sdram_init_state <= `I_TRF;
                `I_TRF: O_sdram_init_state <= (`end_trf)?((init_arf_cnt==4'd8)?`I_LMR:`I_ARF):`I_TRF;
                `I_LMR: O_sdram_init_state <= `I_TRSC;
                `I_TRSC: O_sdram_init_state <= (`end_trsc)?`I_DONE:`I_TRSC;
                `I_DONE: O_sdram_init_state <= O_sdram_init_state;
                default: O_sdram_init_state <= `I_NOP;
            endcase
        end
    end

    always@(posedge I_ref_clk or negedge I_rst_n)begin
        if(!I_rst_n) begin 
            O_sdram_work_state <= `IDLE; active_port <= 3'd7; O_sdram_rd_wr <= 1'b1;
        end
        else begin
            case(O_sdram_work_state)
            `IDLE:begin
                // 多端口优先级仲裁
                if(auto_ref_req & O_sdram_init_done)begin
                    O_sdram_work_state <= `ARF; active_port <= 3'd7; 
                end
                else if(I_wr0_req & O_sdram_init_done)begin
                    O_sdram_work_state <= `ACT; active_port <= 3'd0; O_sdram_rd_wr <= 1'b0;
                end
                else if(I_rd0_req & O_sdram_init_done)begin
                    O_sdram_work_state <= `ACT; active_port <= 3'd1; O_sdram_rd_wr <= 1'b1;
                end
                else if(I_rd1_req & O_sdram_init_done)begin
                    O_sdram_work_state <= `ACT; active_port <= 3'd2; O_sdram_rd_wr <= 1'b1;
                end
                else if(I_rd2_req & O_sdram_init_done)begin
                    O_sdram_work_state <= `ACT; active_port <= 3'd3; O_sdram_rd_wr <= 1'b1;
                end
                else if(I_wr1_req & O_sdram_init_done)begin
                    O_sdram_work_state <= `ACT; active_port <= 3'd4; O_sdram_rd_wr <= 1'b0;
                end
                else begin
                    O_sdram_work_state <= `IDLE; active_port <= 3'd7; O_sdram_rd_wr <= 1'b1;
                end
            end
            `ACT: O_sdram_work_state <= `TRCD;
            `TRCD:begin
                if(`end_trcd) O_sdram_work_state <= O_sdram_rd_wr ? `RD : `WR;
                else O_sdram_work_state <= `TRCD;
            end
            `WR: O_sdram_work_state <= `WR_BE;
            `WR_BE: O_sdram_work_state <= (end_twrite)?`TWR:`WR_BE;
            `TWR: O_sdram_work_state <= (`end_twr)?`PCH:`TWR;
            `RD: O_sdram_work_state <= `CL;
            `CL: O_sdram_work_state <= (`end_cl)?`RD_BE:`CL;
            `RD_BE: O_sdram_work_state <= (end_tread)?`PCH:`RD_BE;
            `PCH: O_sdram_work_state <= `TRP;
            `TRP: O_sdram_work_state <= (`end_trp)?`IDLE:`TRP;
            `ARF: O_sdram_work_state <= `TRFC;
            `TRFC: O_sdram_work_state <= (`end_trf)?`IDLE:`TRFC;
            default: O_sdram_work_state <= `IDLE;
            endcase
        end
    end

    always@(*)begin
        case(O_sdram_init_state)
            `I_NOP: cnt_rst_n <= 1'b0;
            `I_PCH, `I_ARF, `I_LMR: cnt_rst_n <= 1'b1;
            `I_TRP: cnt_rst_n <= (`end_trp)?1'b0:1'b1;
            `I_TRF: cnt_rst_n <= (`end_trf)?1'b0:1'b1;
            `I_TRSC: cnt_rst_n <= (`end_trsc)?1'b0:1'b1;
            `I_DONE:begin
                case(O_sdram_work_state)
                    `IDLE: cnt_rst_n <= 1'b0;
                    `ACT:  cnt_rst_n <= 1'b1;
                    `TRCD: cnt_rst_n <= (`end_trcd)?1'b0:1'b1;
                    `WR_BE: cnt_rst_n <= (end_twrite)?1'b0:1'b1;
                    `TWR:  cnt_rst_n <= (`end_twr)?1'b0:1'b1;
                    `CL:   cnt_rst_n <= (`end_cl)?1'b0:1'b1;
                    `RD_BE: cnt_rst_n <= (end_tread)?1'b0:1'b1;
                    `TRP:  cnt_rst_n <= (`end_trp)?1'b0:1'b1;
                    `TRFC: cnt_rst_n <= (`end_trf)?1'b0:1'b1;
                    default: cnt_rst_n <= 1'b0;
                endcase
            end
            default: cnt_rst_n <= 1'b0;
        endcase
    end

    // 仅在WR和WR_BE阶段，且不多读
    wire base_wr_ack = (O_sdram_work_state==`WR) | ((O_sdram_work_state==`WR_BE) & (O_cnt_clk < active_burst - 1'b1));
    wire base_rd_ack = (O_sdram_work_state==`RD_BE)&(O_cnt_clk>=10'd1)&(O_cnt_clk<active_burst+2'd1);

    assign O_wr0_ack = (active_port == 3'd0) & base_wr_ack;
    assign O_rd0_ack = (active_port == 3'd1) & base_rd_ack;
    assign O_rd1_ack = (active_port == 3'd2) & base_rd_ack;
    assign O_rd2_ack = (active_port == 3'd3) & base_rd_ack;
    assign O_wr1_ack = (active_port == 3'd4) & base_wr_ack;

endmodule