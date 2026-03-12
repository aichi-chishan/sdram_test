`timescale 1ns / 1ps

module tb_sdram_top();

    // -------------------------------------------------------------------------
    // 参数定义：为了加快仿真速度，强烈建议先将宽高改小(如128x128)测试通过后再跑全尺寸
    // -------------------------------------------------------------------------
    parameter IMG_WIDTH  = 1280;
    parameter IMG_HEIGHT = 720;
    parameter IMG_WORDS  = (IMG_WIDTH * IMG_HEIGHT) / 2; // 一行两像素(32bit)

    // SDRAM 物理地址空间划分 (模拟 STM32 维护的内存池)
    parameter REGION_1 = 24'h000000; // 存放 Image 1 原图
    parameter REGION_2 = 24'h200000; // 存放 Image 2 原图
    parameter REGION_3 = 24'h400000; // 存放 Image 2 算法处理后的图像

    // -------------------------------------------------------------------------
    // 信号与时钟复位
    // -------------------------------------------------------------------------
    reg I_ref_clk, I_out_clk, I_rst_n;
    reg clk_33M, clk_24M;

    initial begin
        I_ref_clk = 0; I_out_clk = 0; I_rst_n = 0;
        clk_33M = 0; clk_24M = 0;
        #100 I_rst_n = 1;
    end

    // 原有 I_ref_clk 生成保持不变
    always #5 I_ref_clk = ~I_ref_clk;   // 100MHz 控制器时钟

    // 修改 I_out_clk 生成：先延迟2ns再开始周期性翻转
    initial begin
        I_out_clk = 0;
        #2;   // 滞后2ns
        forever #5 I_out_clk = ~I_out_clk;  // 100MHz SDRAM 物理时钟
    end

    // 读写时钟的生成
    always #15   clk_33M = ~clk_33M;
    always #20.8 clk_24M = ~clk_24M;

    always @(*) begin
        I_wr0_clk = clk_33M; 
        I_rd0_clk = clk_24M;
        I_rd1_clk = clk_24M; 
        I_wr1_clk = clk_33M; 
        I_rd2_clk = clk_24M;
    end

    // 各端口控制信号
    reg         I_wr0_clk, I_rd0_clk, I_rd1_clk, I_rd2_clk, I_wr1_clk;
    reg         I_wr0_req, I_wr0_load; reg [31:0] I_wr0_data; reg [23:0] I_wr0_saddr, I_wr0_eaddr; reg [9:0] I_wr0_burst;
    reg         I_rd0_req, I_rd0_load; wire [31:0] O_rd0_data; reg [23:0] I_rd0_saddr, I_rd0_eaddr; reg [9:0] I_rd0_burst;
    reg         I_rd1_req, I_rd1_load; wire [31:0] O_rd1_data; reg [23:0] I_rd1_saddr, I_rd1_eaddr; reg [9:0] I_rd1_burst;
    reg         I_wr1_req, I_wr1_load; reg [31:0] I_wr1_data; reg [23:0] I_wr1_saddr, I_wr1_eaddr; reg [9:0] I_wr1_burst;
    
    // RD2 端口本次不使用，Tie-off
    reg         I_rd2_req, I_rd2_load; wire [31:0] O_rd2_data; reg [23:0] I_rd2_saddr, I_rd2_eaddr; reg [9:0] I_rd2_burst;

    wire O_sdram_init_done;
    wire O_sdram_clk, O_sdram_cke, O_sdram_cs_n, O_sdram_ras_n, O_sdram_cas_n, O_sdram_we_n;
    wire [1:0]  O_sdram_bank;
    wire [12:0] O_sdram_addr;
    wire [31:0] IO_sdram_dq;
    wire [3:0]  O_sdram_dqm;

    // -------------------------------------------------------------------------
    // 实例化待测设计 (DUT)
    // -------------------------------------------------------------------------
    sdram_top u_sdram_top(
        .I_ref_clk(I_ref_clk), .I_out_clk(I_out_clk), .I_rst_n(I_rst_n),
        .I_wr0_clk(I_wr0_clk), .I_wr0_req(I_wr0_req), .I_wr0_load(I_wr0_load), .I_wr0_data(I_wr0_data), .I_wr0_saddr(I_wr0_saddr), .I_wr0_eaddr(I_wr0_eaddr), .I_wr0_burst(I_wr0_burst),
        .I_rd0_clk(I_rd0_clk), .I_rd0_req(I_rd0_req), .I_rd0_load(I_rd0_load), .O_rd0_data(O_rd0_data), .I_rd0_saddr(I_rd0_saddr), .I_rd0_eaddr(I_rd0_eaddr), .I_rd0_burst(I_rd0_burst),
        .I_rd1_clk(I_rd1_clk), .I_rd1_req(I_rd1_req), .I_rd1_load(I_rd1_load), .O_rd1_data(O_rd1_data), .I_rd1_saddr(I_rd1_saddr), .I_rd1_eaddr(I_rd1_eaddr), .I_rd1_burst(I_rd1_burst),
        .I_rd2_clk(I_rd2_clk), .I_rd2_req(I_rd2_req), .I_rd2_load(I_rd2_load), .O_rd2_data(O_rd2_data), .I_rd2_saddr(24'd0), .I_rd2_eaddr(24'd0), .I_rd2_burst(10'd0),
        .I_wr1_clk(I_wr1_clk), .I_wr1_req(I_wr1_req), .I_wr1_load(I_wr1_load), .I_wr1_data(I_wr1_data), .I_wr1_saddr(I_wr1_saddr), .I_wr1_eaddr(I_wr1_eaddr), .I_wr1_burst(I_wr1_burst),
        .O_sdram_init_done(O_sdram_init_done),
        .O_sdram_clk(O_sdram_clk), .O_sdram_cke(O_sdram_cke), .O_sdram_cs_n(O_sdram_cs_n), .O_sdram_ras_n(O_sdram_ras_n), .O_sdram_cas_n(O_sdram_cas_n), .O_sdram_we_n(O_sdram_we_n),
        .O_sdram_bank(O_sdram_bank), .O_sdram_addr(O_sdram_addr), .IO_sdram_dq(IO_sdram_dq), .O_sdram_dqm(O_sdram_dqm)
    );

    // -------------------------------------------------------------------------
    // 实例化官方 SDRAM 行为模型 (32位总线需2片16位芯片拼接)
    // -------------------------------------------------------------------------
    mt48lc16m16a2 u_sdram_low (
        .Dq(IO_sdram_dq[15:0]), 
        .Addr(O_sdram_addr), .Ba(O_sdram_bank), .Clk(O_sdram_clk), .Cke(O_sdram_cke), 
        .Cs_n(O_sdram_cs_n), .Ras_n(O_sdram_ras_n), .Cas_n(O_sdram_cas_n), .We_n(O_sdram_we_n), .Dqm(O_sdram_dqm[1:0])
    );

    mt48lc16m16a2 u_sdram_high (
        .Dq(IO_sdram_dq[31:16]), 
        .Addr(O_sdram_addr), .Ba(O_sdram_bank), .Clk(O_sdram_clk), .Cke(O_sdram_cke), 
        .Cs_n(O_sdram_cs_n), .Ras_n(O_sdram_ras_n), .Cas_n(O_sdram_cas_n), .We_n(O_sdram_we_n), .Dqm(O_sdram_dqm[3:2])
    );

    // -------------------------------------------------------------------------
    // 模拟 STM32 动态分配地址池的任务
    // -------------------------------------------------------------------------
    task stm32_set_addr;
        input [2:0]  port; // 0:WR0, 1:RD0, 2:RD1, 3:WR1
        input [23:0] base_addr;
        begin
            case(port)
                0: begin I_wr0_saddr = base_addr; I_wr0_eaddr = base_addr + IMG_WORDS; I_wr0_load = 1; @(posedge I_ref_clk); I_wr0_load = 0; end
                1: begin I_rd0_saddr = base_addr; I_rd0_eaddr = base_addr + IMG_WORDS; I_rd0_load = 1; @(posedge I_ref_clk); I_rd0_load = 0; end
                2: begin I_rd1_saddr = base_addr; I_rd1_eaddr = base_addr + IMG_WORDS; I_rd1_load = 1; @(posedge I_ref_clk); I_rd1_load = 0; end
                3: begin I_wr1_saddr = base_addr; I_wr1_eaddr = base_addr + IMG_WORDS; I_wr1_load = 1; @(posedge I_ref_clk); I_wr1_load = 0; end
            endcase
            @(posedge I_ref_clk); // 留出同步裕量
        end
    endtask

    // -------------------------------------------------------------------------
    // 仿真主进程
    // -------------------------------------------------------------------------
    reg [31:0] img1_mem [0:IMG_WORDS-1];
    reg [31:0] img2_mem [0:IMG_WORDS-1];
    integer i, j, file_out1, file_out2;

    // 算法延迟流水线寄存器
    reg [31:0] algo_pipe [0:3]; 

    initial begin
        // 信号初始化
        I_wr0_req = 0; I_rd0_req = 0; I_rd1_req = 0; I_wr1_req = 0; I_rd2_req = 0;
        I_wr0_burst = 256; I_rd0_burst = 256; I_rd1_burst = 256; I_wr1_burst = 256; I_rd2_burst = 256;

        $readmemh("D:/Project/sdram_test/img/1_1280x720_rgb565.hex", img1_mem);
        $readmemh("D:/Project/sdram_test/img/2_1280x720_rgb565.hex", img2_mem);

        @(posedge O_sdram_init_done);
        $display("SDRAM Init Done.");
        #2000;

        // ==========================================
        // 步骤 1: WR0 端口分时复用，先后存入两张图
        // ==========================================
        $display("STM32: Set WR0 to Region 1, Writing Image 1...");
        stm32_set_addr(0, REGION_1);
        for (i = 0; i < IMG_WORDS; i = i + 1) begin
            @(posedge I_ref_clk);
            I_wr0_req = 1; I_wr0_data = img1_mem[i];
        end
        @(posedge I_ref_clk); I_wr0_req = 0;
        #50000; // 等待 SDRAM 物理层写入完毕

        $display("STM32: Set WR0 to Region 2, Writing Image 2...");
        stm32_set_addr(0, REGION_2);
        for (i = 0; i < IMG_WORDS; i = i + 1) begin
            @(posedge I_ref_clk);
            I_wr0_req = 1; I_wr0_data = img2_mem[i];
        end
        @(posedge I_ref_clk); I_wr0_req = 0;
        #50000;

        // ==========================================
        // 步骤 2: 并行任务 -> RD0 读出图1，同时 RD1->算法->WR1 处理图2
        // ==========================================
        file_out1 = $fopen("D:/Project/sdram_test/img/image1_out.hex", "w");
        $display("STM32: Assigning Regions for Parallel Processing...");
        
        // STM32 分配内存指针，彻底隔绝读写冲突
        stm32_set_addr(1, REGION_1); // RD0 指向图 1
        stm32_set_addr(2, REGION_2); // RD1 指向图 2 (源)
        stm32_set_addr(3, REGION_3); // WR1 指向图 2 (目的)

        #10000; // 等待读 FIFO 预读取填充数据

        $display("Processing...");
        fork
            // 线程 A: 屏幕端口 RD0 直接读取 Image 1
            begin
                for (i = 0; i < IMG_WORDS; i = i + 1) begin
                    @(posedge I_ref_clk);
                    I_rd0_req = 1;
                    $fdisplay(file_out1, "%08X", O_rd0_data);
                end
                @(posedge I_ref_clk); I_rd0_req = 0;
                $fclose(file_out1);
            end

            // 线程 B: 算法通道读取、打拍、存入新区域
            begin
                for (j = 0; j < IMG_WORDS + 4; j = j + 1) begin
                    @(posedge I_ref_clk);
                    
                    // 1. 发起读请求，直到读完
                    if (j < IMG_WORDS) I_rd1_req = 1; else I_rd1_req = 0;
                    
                    // 2. 模拟算法打 4 拍处理
                    algo_pipe[3] <= algo_pipe[2];
                    algo_pipe[2] <= algo_pipe[1];
                    algo_pipe[1] <= algo_pipe[0];
                    algo_pipe[0] <= O_rd1_data; // 假设做了一些处理，如反色：~O_rd1_data

                    // 3. 第 4 拍后，将处理完的数据打入 WR1
                    if (j >= 4) begin
                        I_wr1_req = 1;
                        I_wr1_data = algo_pipe[3];
                    end else begin
                        I_wr1_req = 0;
                    end
                end
                @(posedge I_ref_clk); I_wr1_req = 0;
            end
        join
        #50000;

        // ==========================================
        // 步骤 3: 屏幕端口 RD0 切换指针，读出处理后的图 2
        // ==========================================
        file_out2 = $fopen("D:/Project/sdram_test/img/image2_processed_out.hex", "w");
        $display("STM32: Set RD0 to Region 3, Reading Processed Image 2...");
        
        stm32_set_addr(1, REGION_3);
        #10000; 

        for (i = 0; i < IMG_WORDS; i = i + 1) begin
            @(posedge I_ref_clk);
            I_rd0_req = 1;
            $fdisplay(file_out2, "%08X", O_rd0_data);
        end
        @(posedge I_ref_clk); I_rd0_req = 0;
        
        $fclose(file_out2);
        $display("Simulation Finished Successfully!");
        
        #100;
        $stop;
    end

endmodule