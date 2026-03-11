`timescale 1ns / 1ps

module tb_sdram_top();

    // ==========================================================
    // 时钟与复位生成
    // ==========================================================
    reg ref_clk;    // SDRAM 控制器主时钟 100MHz
    reg out_clk;    // SDRAM 物理引脚时钟 100MHz (可做相位偏移)
    reg pixel_clk;  // 像素/算法处理时钟 50MHz (模拟摄像头/屏幕速率)
    reg rst_n;

    initial begin
        ref_clk = 0; out_clk = 0; pixel_clk = 0; rst_n = 0;
        #1000 rst_n = 1;
    end
    
    always #5  ref_clk = ~ref_clk;    // 100MHz
    always #5  out_clk = ~out_clk;    // 100MHz
    always #10 pixel_clk = ~pixel_clk;// 50MHz

    // ==========================================================
    // 顶层模块例化连线
    // ==========================================================
    wire O_sdram_init_done;
    wire O_sdram_clk, O_sdram_cke, O_sdram_cs_n, O_sdram_ras_n, O_sdram_cas_n, O_sdram_we_n;
    wire [1:0] O_sdram_bank;
    wire [12:0] O_sdram_addr;
    wire [31:0] IO_sdram_dq;
    wire [3:0] O_sdram_dqm;

    // 端口定义寄存器
    reg  wr0_req, rd0_req, rd1_req, rd2_req, wr1_req;
    reg  [31:0] wr0_data, wr1_data;
    wire [31:0] rd0_data, rd1_data, rd2_data;
    
    // 模拟 STM32 配置的基地址 (1M words = 4MB)
    parameter ADDR_FRAME1 = 24'h00_0000;
    parameter ADDR_FRAME2 = 24'h10_0000;
    parameter ADDR_FRAME3 = 24'h20_0000;
    parameter ADDR_RESULT = 24'h30_0000;
    
    // 突发长度配置 (均配置为 128)
    parameter BURST_LEN = 10'd128;

    sdram_top u_sdram_top (
        .I_ref_clk(ref_clk), .I_out_clk(out_clk), .I_rst_n(rst_n),
        .O_sdram_init_done(O_sdram_init_done),
        
        // WR0 (模拟摄像头输入)
        .I_wr0_clk(pixel_clk), .I_wr0_req(wr0_req), .I_wr0_load(1'b0),
        .I_wr0_data(wr0_data), .I_wr0_saddr(ADDR_FRAME3), .I_wr0_eaddr(ADDR_FRAME3 + 24'h070800), .I_wr0_burst(BURST_LEN),
        
        // RD0 (模拟屏幕送显)
        .I_rd0_clk(pixel_clk), .I_rd0_req(rd0_req), .I_rd0_load(1'b0),
        .O_rd0_data(rd0_data), .I_rd0_saddr(ADDR_FRAME3), .I_rd0_eaddr(ADDR_FRAME3 + 24'h070800), .I_rd0_burst(BURST_LEN),
        
        // RD1 (模拟算法通道A - HDR短曝光)
        .I_rd1_clk(pixel_clk), .I_rd1_req(rd1_req), .I_rd1_load(1'b0),
        .O_rd1_data(rd1_data), .I_rd1_saddr(ADDR_FRAME1), .I_rd1_eaddr(ADDR_FRAME1 + 24'h070800), .I_rd1_burst(BURST_LEN),
        
        // RD2 (模拟算法通道B - 仿射源数据/HDR长曝光)
        .I_rd2_clk(pixel_clk), .I_rd2_req(rd2_req), .I_rd2_load(1'b0),
        .O_rd2_data(rd2_data), .I_rd2_saddr(ADDR_FRAME2), .I_rd2_eaddr(ADDR_FRAME2 + 24'h070800), .I_rd2_burst(BURST_LEN),
        
        // WR1 (模拟算法写回 - 仿射结果)
        .I_wr1_clk(pixel_clk), .I_wr1_req(wr1_req), .I_wr1_load(1'b0),
        .I_wr1_data(wr1_data), .I_wr1_saddr(ADDR_RESULT), .I_wr1_eaddr(ADDR_RESULT + 24'h070800), .I_wr1_burst(BURST_LEN),

        // SDRAM 物理接口
        .O_sdram_clk(O_sdram_clk), .O_sdram_cke(O_sdram_cke), .O_sdram_cs_n(O_sdram_cs_n),
        .O_sdram_ras_n(O_sdram_ras_n), .O_sdram_cas_n(O_sdram_cas_n), .O_sdram_we_n(O_sdram_we_n),
        .O_sdram_bank(O_sdram_bank), .O_sdram_addr(O_sdram_addr), .IO_sdram_dq(IO_sdram_dq), .O_sdram_dqm(O_sdram_dqm)
    );

    // ==========================================================
    // 两个 MT48LC16M16A2 SDRAM 模型例化 (并联成 32-bit)
    // ==========================================================
    // 注意：需要确保你的工程目录下有 mt48lc16m16a2.v 仿真模型文件
    mt48lc16m16a2 sdram_low (
        .Dq(IO_sdram_dq[15:0]), .Addr(O_sdram_addr), .Ba(O_sdram_bank),
        .Clk(O_sdram_clk), .Cke(O_sdram_cke), .Cs_n(O_sdram_cs_n),
        .Ras_n(O_sdram_ras_n), .Cas_n(O_sdram_cas_n), .We_n(O_sdram_we_n), .Dqm(O_sdram_dqm[1:0])
    );

    mt48lc16m16a2 sdram_high (
        .Dq(IO_sdram_dq[31:16]), .Addr(O_sdram_addr), .Ba(O_sdram_bank),
        .Clk(O_sdram_clk), .Cke(O_sdram_cke), .Cs_n(O_sdram_cs_n),
        .Ras_n(O_sdram_ras_n), .Cas_n(O_sdram_cas_n), .We_n(O_sdram_we_n), .Dqm(O_sdram_dqm[3:2])
    );

    // ==========================================================
    // 测试激励与文件读写逻辑
    // ==========================================================
    // 分辨率 1280*720 = 921,600 像素，32-bit 下为 460,800 个 word
    parameter TOTAL_WORDS = 460800;
    
    reg [31:0] mem_frame3 [0:TOTAL_WORDS-1];
    integer fp_rd0, fp_wr1;
    integer wr0_cnt = 0;

    initial begin
        // 1. 读取预先准备好的 hex 文件加载到数组中
        $readmemh("frame3_current.hex", mem_frame3);
        
        // 2. 打开输出文件
        fp_rd0 = $fopen("output_rd0_screen.hex", "w");
        fp_wr1 = $fopen("output_wr1_affine.hex", "w");
        
        wr0_req = 0; rd0_req = 0; rd1_req = 0; rd2_req = 0;
        
        // 3. 等待 SDRAM 初始化完成
        wait(O_sdram_init_done);
        $display("SDRAM Init Done! Start Testing...");
        
        // 4. 为缩短仿真时间，省略先写 frame1/2 的过程，直接火力全开并发测试
        #1000;
        
        // 启动摄像头写入 (WR0) 和所有的读取端口 (RD0, RD1, RD2)
        // 现实中是按时序信号给，这里简单粗暴拉高 req 模拟连续不断的数据流索取
        fork
            // 线程A：模拟摄像头连续写入
            begin
                while (wr0_cnt < TOTAL_WORDS) begin
                    @(posedge pixel_clk);
                    wr0_req <= 1;
                    wr0_data <= mem_frame3[wr0_cnt];
                    wr0_cnt <= wr0_cnt + 1;
                end
                wr0_req <= 0;
            end
            
            // 线程B：模拟屏幕连续读取并存入文件
            begin
                forever begin
                    @(posedge pixel_clk);
                    rd0_req <= 1; // 始终索要数据
                    if (rd0_req) $fdisplay(fp_rd0, "%h", rd0_data);
                end
            end
            
            // 线程C：启动算法读取
            begin
                rd1_req <= 1;
                rd2_req <= 1;
            end
        join
    end

    // ==========================================================
    // 模拟仿射变换：从 RD2 读出数据，打 10 拍后，通过 WR1 存回
    // ==========================================================
    reg [31:0] affine_pipeline [0:9];
    reg [9:0]  affine_valid_pipe; // 标记流水线里的数据是否有效
    integer i;

    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr1_req <= 0;
            wr1_data <= 0;
            affine_valid_pipe <= 0;
            for(i=0; i<10; i=i+1) affine_pipeline[i] <= 0;
        end else begin
            // 移位寄存器打拍
            affine_pipeline[0] <= rd2_data;
            affine_valid_pipe[0] <= rd2_req; // 假设只要发起读请求，拿到的就是有效运算源
            
            for(i=1; i<10; i=i+1) begin
                affine_pipeline[i] <= affine_pipeline[i-1];
                affine_valid_pipe[i] <= affine_valid_pipe[i-1];
            end
            
            // 10 拍后回写到 WR1 端口
            wr1_req  <= affine_valid_pipe[9];
            wr1_data <= affine_pipeline[9];
            
            // 将打拍写回的数据也 dump 到文件验证
            if (wr1_req) $fdisplay(fp_wr1, "%h", wr1_data);
        end
    end

endmodule