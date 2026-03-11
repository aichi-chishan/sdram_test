`include "sdram_param.v"
module sdram_cmd(
    input   wire    I_sys_clk,
    input   wire    I_rst_n,
    
    input   wire    [23:0] I_sdram_addr,  // 路由后的复用地址
    input   wire    [9:0]  I_sdram_burst, // 路由后的突发长度

    input   wire    [4:0] I_init_state,
    input   wire    [3:0] I_work_state,
    input   wire    [9:0] O_cnt_clk,

    output  wire    O_sdram_cke,
    output  wire    O_sdram_cs_n,
    output  wire    O_sdram_ras_n,
    output  wire    O_sdram_cas_n,
    output  wire    O_sdram_we_n,
    output  reg     [1:0] O_sdram_bank,
    output  reg     [12:0] O_sdram_addr
);

    parameter WRITE_MODE = 1'b0;    
    parameter CL = 3'b011;          
    parameter BURST_TYPE = 1'b0;    
    parameter BURST_LENGTH = 3'b111;

    reg [4:0] sdram_cmd;
    wire end_wrburst = (O_cnt_clk == I_sdram_burst - 1);
    wire end_rdburst = (O_cnt_clk == I_sdram_burst - 4);

    always@(posedge I_sys_clk or negedge I_rst_n)begin
        if(I_rst_n==1'b0)begin
            sdram_cmd <= `CMD_INIT;
            O_sdram_bank <= 2'b11;
            O_sdram_addr <= 13'h1fff;
        end
        else begin
            case(I_init_state)
                `I_NOP,`I_TRP,`I_TRF,`I_TRSC:begin 
                    sdram_cmd <= `CMD_NOP; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                end
                `I_PCH:begin
                    sdram_cmd <= `CMD_PCH; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                end
                `I_ARF:begin
                    sdram_cmd <= `CMD_ARF; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                end
                `I_LMR:begin
                    sdram_cmd <= `CMD_LMR; O_sdram_bank <= 2'b00;
                    O_sdram_addr <= { 3'b000, WRITE_MODE, 2'b00, CL, BURST_TYPE, BURST_LENGTH };
                end
                `I_DONE:begin 
                    case(I_work_state)
                        `IDLE,`TRCD,`CL,`TWR,`TRP,`TRFC:begin
                            sdram_cmd <= `CMD_NOP; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                        end
                        `ACT:begin
                            sdram_cmd <= `CMD_ACT; 
                            O_sdram_bank <= I_sdram_addr[23:22]; O_sdram_addr <= I_sdram_addr[21:9];
                        end
                        `WR:begin
                            sdram_cmd <= `CMD_WR;
                            O_sdram_bank <= I_sdram_addr[23:22]; O_sdram_addr <= {4'b0000,I_sdram_addr[8:0]};
                        end
                        `WR_BE:begin
                            if(end_wrburst) sdram_cmd <= `CMD_BT;
                            else begin sdram_cmd <= `CMD_NOP; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff; end
                        end
                        `RD:begin
                            sdram_cmd <= `CMD_RD;
                            O_sdram_bank <= I_sdram_addr[23:22]; O_sdram_addr <= {4'b0000,I_sdram_addr[8:0]};
                        end
                        `RD_BE:begin 
                            if(end_rdburst) sdram_cmd <= `CMD_BT;
                            else begin sdram_cmd <= `CMD_NOP; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff; end
                        end
                        `PCH:begin 
                            sdram_cmd <= `CMD_PCH; O_sdram_bank <= I_sdram_addr[23:22]; O_sdram_addr <= 13'h0000;
                        end
                        `ARF:begin 
                            sdram_cmd <= `CMD_ARF; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                        end
                        default:begin
                            sdram_cmd <= `CMD_NOP; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                        end
                    endcase
                end
                default:begin
                        sdram_cmd <= `CMD_NOP; O_sdram_bank <= 2'b11; O_sdram_addr <= 13'h1fff;
                end
            endcase
        end
    end
    assign {O_sdram_cke,O_sdram_cs_n,O_sdram_ras_n,O_sdram_cas_n,O_sdram_we_n} = sdram_cmd;
endmodule