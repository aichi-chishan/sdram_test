`timescale 1ns/1ps

module tb_sdram_top();

    // ==========================================
    // 参数定义与文件路径
    // ==========================================
    // 1280x720 RGB565图像，每两个像素组合成一个32位数据
    // 总数据量 = 1280 * 720 / 2 = 460800 个 32-bit Word = 0x70800
    parameter IMG_WORDS = 24'h070800;
    
    // 指定 .hex 文件的绝对路径（请根据实际路径修改，斜杠使用 '/'）
    parameter HEX_FILE_CAM = "C:/YourProject/images/cam_frame.hex";
    parameter HEX_FILE_BG  = "C:/YourProject/images/bg_frame.hex";

    // ==========================================
    // 信号定义
    // ==========================================
    reg I_ref_clk;
    reg I_out_clk;
    reg I_rst_n;

    // WR0 (Camera) 模拟摄像头时钟 (例如 40MHz)
    reg I_wr0_clk, I_wr0_req, I_wr0_load;
    reg [31:0] I_wr0_data;
    reg [23:0] I_wr0_saddr, I_wr0_eaddr;
    reg [9:0]  I_wr0_burst;

    // RD0 (Screen) 模拟屏幕时钟 (例如 40MHz)
    reg I_rd0_clk, I_rd0_req, I_rd0_load;
    wire [31:0] O_rd0_data;
    reg [23:0] I_rd0_saddr, I_rd0_eaddr;
    reg [9:0]  I_rd0_burst;

    // RD1 (Algo A) & RD2 (Algo B) 模拟算法时钟 (例如 75MHz)
    reg I_rd1_clk, I_rd1_req, I_rd1_load;
    wire [31:0] O_rd1_data;
    reg [23:0] I_rd1_saddr, I_rd1_eaddr;
    reg [9:0]  I_rd1_burst;

    reg I_rd2_clk, I_rd2_req, I_rd2_load;
    wire [31:0] O_rd2_data;
    reg [23:0] I_rd2_saddr, I_rd2_eaddr;
    reg [9:0]  I_rd2_burst;

    // WR1 (Algo Write) 同算法时钟
    reg I_wr1_clk, I_wr1_req, I_wr1_load;
    reg [31:0] I_wr1_data;
    reg [23:0] I_wr1_saddr, I_wr1_eaddr;
    reg [9:0]  I_wr1_burst;

    wire O_sdram_init_done;
    wire O_sdram_clk, O_sdram_cke, O_sdram_cs_n, O_sdram_ras_n, O_sdram_cas_n, O_sdram_we_n;
    wire [1:0] O_sdram_bank;
    wire [12:0] O_sdram_addr;
    wire [31:0] IO_sdram_dq;
    wire [3:0] O_sdram_dqm;

    // ==========================================
    // 时钟生成
    // ==========================================
    initial begin
        I_ref_clk = 0; I_out_clk = 1; // I_out_clk 偏移180度，以满足SDRAM建立保持时间
        I_wr0_clk = 0; I_rd0_clk = 0;
        I_rd1_clk = 0; I_rd2_clk = 0; I_wr1_clk = 0;
    end
    always #5     I_ref_clk = ~I_ref_clk; // 100MHz
    always #5     I_out_clk = ~I_out_clk; // 100MHz 
    always #12.5  I_wr0_clk = ~I_wr0_clk; // ~40MHz Camera
    always #12.5  I_rd0_clk = ~I_rd0_clk; // ~40MHz Screen
    always #6.66  I_rd1_clk = ~I_rd1_clk; // ~75MHz Algo
    always #6.66  I_rd2_clk = ~I_rd2_clk; // ~75MHz Algo
    always #6.66  I_wr1_clk = ~I_wr1_clk; // ~75MHz Algo

    // ==========================================
    // 模块例化：SDRAM Top
    // ==========================================
    sdram_top u_sdram_top(
        .I_ref_clk(I_ref_clk), .I_out_clk(I_out_clk), .I_rst_n(I_rst_n),
        
        .I_wr0_clk(I_wr0_clk), .I_wr0_req(I_wr0_req), .I_wr0_load(I_wr0_load),
        .I_wr0_data(I_wr0_data), .I_wr0_saddr(I_wr0_saddr), .I_wr0_eaddr(I_wr0_eaddr), .I_wr0_burst(I_wr0_burst),
        
        .I_rd0_clk(I_rd0_clk), .I_rd0_req(I_rd0_req), .I_rd0_load(I_rd0_load),
        .O_rd0_data(O_rd0_data), .I_rd0_saddr(I_rd0_saddr), .I_rd0_eaddr(I_rd0_eaddr), .I_rd0_burst(I_rd0_burst),
        
        .I_rd1_clk(I_rd1_clk), .I_rd1_req(I_rd1_req), .I_rd1_load(I_rd1_load),
        .O_rd1_data(O_rd1_data), .I_rd1_saddr(I_rd1_saddr), .I_rd1_eaddr(I_rd1_eaddr), .I_rd1_burst(I_rd1_burst),
        
        .I_rd2_clk(I_rd2_clk), .I_rd2_req(I_rd2_req), .I_rd2_load(I_rd2_load),
        .O_rd2_data(O_rd2_data), .I_rd2_saddr(I_rd2_saddr), .I_rd2_eaddr(I_rd2_eaddr), .I_rd2_burst(I_rd2_burst),
        
        .I_wr1_clk(I_wr1_clk), .I_wr1_req(I_wr1_req), .I_wr1_load(I_wr1_load),
        .I_wr1_data(I_wr1_data), .I_wr1_saddr(I_wr1_saddr), .I_wr1_eaddr(I_wr1_eaddr), .I_wr1_burst(I_wr1_burst),
        
        .O_sdram_init_done(O_sdram_init_done),
        .O_sdram_clk(O_sdram_clk), .O_sdram_cke(O_sdram_cke), .O_sdram_cs_n(O_sdram_cs_n),
        .O_sdram_ras_n(O_sdram_ras_n), .O_sdram_cas_n(O_sdram_cas_n), .O_sdram_we_n(O_sdram_we_n),
        .O_sdram_bank(O_sdram_bank), .O_sdram_addr(O_sdram_addr), .IO_sdram_dq(IO_sdram_dq), .O_sdram_dqm(O_sdram_dqm)
    );

    // ==========================================
    // 模块例化：两个 16-bit SDRAM 拼接成 32-bit
    // ==========================================
    // 低 16 位 SDRAM
    mt48lc16m16a2 u_sdram_low(
        .Dq(IO_sdram_dq[15:0]), .Addr(O_sdram_addr), .Ba(O_sdram_bank),
        .Clk(O_sdram_clk), .Cke(O_sdram_cke), .Cs_n(O_sdram_cs_n),
        .Ras_n(O_sdram_ras_n), .Cas_n(O_sdram_cas_n), .We_n(O_sdram_we_n), .Dqm(O_sdram_dqm[1:0])
    );
    // 高 16 位 SDRAM
    mt48lc16m16a2 u_sdram_high(
        .Dq(IO_sdram_dq[31:16]), .Addr(O_sdram_addr), .Ba(O_sdram_bank),
        .Clk(O_sdram_clk), .Cke(O_sdram_cke), .Cs_n(O_sdram_cs_n),
        .Ras_n(O_sdram_ras_n), .Cas_n(O_sdram_cas_n), .We_n(O_sdram_we_n), .Dqm(O_sdram_dqm[3:2])
    );

    // ==========================================
    // 测试激励控制逻辑
    // ==========================================
    
    // 图像缓冲区，用于读取 .hex 文件
    reg [31:0] img_cam [0:460799];
    reg [31:0] img_bg  [0:460799];

    initial begin
        // 读取外部绝对路径的HEX图像数据
        $readmemh(HEX_FILE_CAM, img_cam);
        $readmemh(HEX_FILE_BG, img_bg);

        // 初始化所有控制信号
        I_rst_n = 0;
        
        I_wr0_req = 0; I_wr0_load = 0; I_wr0_data = 0;
        I_rd0_req = 0; I_rd0_load = 0;
        I_rd1_req = 0; I_rd1_load = 0;
        I_rd2_req = 0; I_rd2_load = 0;
        I_wr1_req = 0; I_wr1_load = 0; I_wr1_data = 0;

        // 设置地址空间分配 (互不重叠)
        // Camera -> WR0 (Bank0, Base: 0x000000)
        I_wr0_saddr = 24'h000_000; I_wr0_eaddr = I_wr0_saddr + IMG_WORDS; I_wr0_burst = 10'd256;
        // Algo Read 1 <- WR0 (Bank0, Base: 0x000000)
        I_rd1_saddr = 24'h000_000; I_rd1_eaddr = I_rd1_saddr + IMG_WORDS; I_rd1_burst = 10'd256;
        // Algo Read 2 <- 预存背景 (Bank1, Base: 0x100000)
        I_rd2_saddr = 24'h100_000; I_rd2_eaddr = I_rd2_saddr + IMG_WORDS; I_rd2_burst = 10'd256;
        // Algo Write -> WR1 (Bank2, Base: 0x200000)
        I_wr1_saddr = 24'h200_000; I_wr1_eaddr = I_wr1_saddr + IMG_WORDS; I_wr1_burst = 10'd256;
        // Screen Read <- WR1 (Bank2, Base: 0x200000)
        I_rd0_saddr = 24'h200_000; I_rd0_eaddr = I_rd0_saddr + IMG_WORDS; I_rd0_burst = 10'd256;

        #100 I_rst_n = 1;

        // 等待 SDRAM 初始化完成
        wait(O_sdram_init_done == 1'b1);
        #1000;
        
        // 发送 VSYNC 同步脉冲 (清空FIFO并复位地址)
        I_wr0_load = 1; I_rd0_load = 1; I_rd1_load = 1; I_rd2_load = 1; I_wr1_load = 1;
        #200;
        I_wr0_load = 0; I_rd0_load = 0; I_rd1_load = 0; I_rd2_load = 0; I_wr1_load = 0;
        
        #1000; // 等待地址复位稳定
    end

    // --- Task 1: 模拟 Camera 持续写入帧 (WR0) ---
    integer cam_idx = 0;
    always @(posedge I_wr0_clk) begin
        if (I_wr0_load) begin
            cam_idx <= 0;
            I_wr0_req <= 0;
        end else if (O_sdram_init_done) begin
            // 这里为了防止一次性把内部FIFO塞满 (async_fifo_32x512 容量为512), 
            // 可以模拟真实的行消隐，这里简单地持续推入数据
            if (cam_idx < IMG_WORDS) begin
                I_wr0_req <= 1'b1;
                I_wr0_data <= img_cam[cam_idx];
                cam_idx <= cam_idx + 1;
            end else begin
                I_wr0_req <= 1'b0; 
                // 若需连续多帧，可在此重置 cam_idx 和触发 I_wr0_load
            end
        end
    end

    // --- Task 2: 模拟 Algo 图像合成流水线 (RD1, RD2 -> WR1) ---
    // 打拍延迟（模拟如仿射变换或多帧合成的处理周期）
    parameter PIPE_DELAY = 6;
    reg [31:0] rd1_pipe [0:PIPE_DELAY-1];
    reg [31:0] rd2_pipe [0:PIPE_DELAY-1];
    reg [PIPE_DELAY-1:0] valid_pipe;

    integer algo_idx = 0;
    
    // RD1 与 RD2 数据请求拉高，控制FIFO吐出数据
    always @(posedge I_rd1_clk) begin
        if (I_rd1_load) begin
            algo_idx <= 0;
            I_rd1_req <= 0;
            I_rd2_req <= 0;
        end else if (cam_idx > 512) begin // 等待Camera至少写完一点数据防止FIFO读空
            if (algo_idx < IMG_WORDS) begin
                I_rd1_req <= 1'b1;
                I_rd2_req <= 1'b1;
                algo_idx <= algo_idx + 1;
            end else begin
                I_rd1_req <= 1'b0;
                I_rd2_req <= 1'b0;
            end
        end
    end

    // 流水线打拍及运算逻辑
    integer i;
    always @(posedge I_wr1_clk) begin // I_wr1_clk 与 I_rd1_clk 频率一致
        if (!I_rst_n || I_wr1_load) begin
            valid_pipe <= 0;
            I_wr1_req <= 0;
            I_wr1_data <= 0;
        end else begin
            // 数据在读请求后通常延时1拍从FIFO输出，这里直接抓取O_rd1_data作为流水线第0级
            rd1_pipe[0] <= O_rd1_data;
            rd2_pipe[0] <= O_rd2_data;
            valid_pipe[0] <= I_rd1_req; // 假设FIFO从不读空（理想情况下的同步测试）
            
            // 移位寄存器打拍
            for (i = 1; i < PIPE_DELAY; i = i + 1) begin
                rd1_pipe[i] <= rd1_pipe[i-1];
                rd2_pipe[i] <= rd2_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
            
            // 流水线最后一级：模拟双帧合成 (通过简单的位移实现带透明度的Alpha混合/像素相加)
            // 分别处理两个16位RGB565像素
            I_wr1_req <= valid_pipe[PIPE_DELAY-1];
            I_wr1_data <= {
                (rd1_pipe[PIPE_DELAY-1][31:16] >> 1) + (rd2_pipe[PIPE_DELAY-1][31:16] >> 1),
                (rd1_pipe[PIPE_DELAY-1][15:0]  >> 1) + (rd2_pipe[PIPE_DELAY-1][15:0]  >> 1)
            };
        end
    end

    // --- Task 3: 模拟 Screen 刷新读取 (RD0) ---
    integer screen_idx = 0;
    always @(posedge I_rd0_clk) begin
        if (I_rd0_load) begin
            screen_idx <= 0;
            I_rd0_req <= 0;
        end else if (algo_idx > 1024) begin // 确保合成画面写入到SDRAM有一定余量后，屏幕开始扫描
            if (screen_idx < IMG_WORDS) begin
                I_rd0_req <= 1'b1;
                screen_idx <= screen_idx + 1;
            end else begin
                I_rd0_req <= 1'b0;
            end
        end
    end

endmodule