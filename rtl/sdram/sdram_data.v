`include "sdram_param.v"
module sdram_data(
    input   wire    I_sys_clk,  
    input   wire    I_rst_n,    

    input   wire    [31:0] I_sdram_data,  
    output  wire    [31:0] O_sdram_data,  
    input   wire    [3:0]  I_work_state,  
    input   wire    [9:0]  I_cnt_clk,     

    inout   wire    [31:0] IO_sdram_data  
);

    reg sdram_dq_out_en;
    reg [31:0] sdram_dq_in;
    reg [31:0] sdram_dq_out;

    always@(posedge I_sys_clk or negedge I_rst_n)begin
        if(I_rst_n==1'b0) sdram_dq_out_en <= 1'b0;
        else if((I_work_state==`WR)||(I_work_state==`WR_BE)) sdram_dq_out_en <= 1'b1;
        else sdram_dq_out_en <= 1'b0;
    end

    always@(posedge I_sys_clk or negedge I_rst_n)begin
        if(I_rst_n==1'b0) sdram_dq_in <= 'd0;
        else if((I_work_state==`WR)||(I_work_state==`WR_BE)) sdram_dq_in <= I_sdram_data;
    end

    always@(posedge I_sys_clk or negedge I_rst_n)begin
        if(I_rst_n==1'b0) sdram_dq_out <= 'd0;
        else if(I_work_state==`RD_BE) sdram_dq_out <= IO_sdram_data;
    end

    assign IO_sdram_data = sdram_dq_out_en ? sdram_dq_in : 32'hzzzz_zzzz;
    assign O_sdram_data = sdram_dq_out;
endmodule