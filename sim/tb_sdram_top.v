`timescale 1ns/1ps

module tb_sdram_top();

    // -----------------------------------------------------
    // 参数定义 Parameter Definitions
    // -----------------------------------------------------
    // 图像尺寸 1280x720 RGB565，每个像素16bit。
    // SDRAM控制器的写入是32bit宽（2个像素），所以总字数(WORDS)是1280*720/2。
    parameter IMG_WIDTH  = 1280;
    parameter IMG_HEIGHT = 720;
    parameter WORDS      = (IMG_WIDTH * IMG_HEIGHT) / 2; // 460800 Words

    // HEX文件的绝对路径，要求写入32-bit的Hex数据 (高16位像素2，低16位像素1)
    parameter HEX_FILE_CAM  = "D:/Project/sdram_test/sim/camera_in.hex";
    parameter HEX_FILE_ALG1 = "D:/Project/sdram_test/sim/algo_in1.hex";
    parameter HEX_FILE_ALG2 = "D:/Project/sdram_test/sim/algo_in2.hex";

    // 假设用作延时的打拍数量
    parameter ALGO_DELAY = 5;

    // 分配模拟的内存数组
    reg [31:0] camera_mem [0:460799];

    initial begin
        // 取消注释以使其生效，如果没有文件将会有Warning
        // $readmemh(HEX_FILE_CAM, camera_mem);
        // 如果文件不存在，可以初始化一些测试数据防止报错
        camera_mem[0] = 32'hFFFF_0000;
        camera_mem[1] = 32'h0000_FFFF;
    end

    // -----------------------------------------------------
    // 信号声明 Signal Declarations
    // -----------------------------------------------------
    reg I_ref_clk = 0;
    reg I_out_clk = 0;
    reg I_rst_n   = 0;

    // WR0 (Camera)
    reg I_wr0_clk = 0;
    reg I_wr0_req = 0;
    reg I_wr0_load= 0;
    reg [31:0] I_wr0_data = 0;
    reg [23:0] I_wr0_saddr = 24'h00_0000;
    reg [23:0] I_wr0_eaddr = WORDS;
    reg [9:0]  I_wr0_burst = 256;

    // RD0 (Screen)
    reg I_rd0_clk = 0;
    reg I_rd0_req = 0;
    reg I_rd0_load= 0;
    wire [31:0] O_rd0_data;
    reg [23:0] I_rd0_saddr = 24'h00_0000; // 与Camera做PingPong或直接读写入区域
    reg [23:0] I_rd0_eaddr = WORDS;
    reg [9:0]  I_rd0_burst = 256;

    // RD1 (Algo A - 帧1)
    reg I_rd1_clk = 0;
    reg I_rd1_req = 0;
    reg I_rd1_load= 0;
    wire [31:0] O_rd1_data;
    reg [23:0] I_rd1_saddr = 24'h10_0000;
    reg [23:0] I_rd1_eaddr = WORDS;
    reg [9:0]  I_rd1_burst = 256;

    // RD2 (Algo B - 帧2)
    reg I_rd2_clk = 0;
    reg I_rd2_req = 0;
    reg I_rd2_load= 0;
    wire [31:0] O_rd2_data;
    reg [23:0] I_rd2_saddr = 24'h20_0000;
    reg [23:0] I_rd2_eaddr = WORDS;
    reg [9:0]  I_rd2_burst = 256;

    // WR1 (Algo Write - 结果写入)
    reg I_wr1_clk = 0;
    reg I_wr1_req = 0;
    reg I_wr1_load= 0;
    reg [31:0] I_wr1_data = 0;
    reg [23:0] I_wr1_saddr = 24'h30_0000;
    reg [23:0] I_wr1_eaddr = WORDS;
    reg [9:0]  I_wr1_burst = 256;

    // SDRAM物理引脚
    wire O_sdram_init_done;
    wire O_sdram_clk;
    wire O_sdram_cke;
    wire O_sdram_cs_n;
    wire O_sdram_ras_n;
    wire O_sdram_cas_n;
    wire O_sdram_we_n;
    wire [1:0]  O_sdram_bank;
    wire [12:0] O_sdram_addr;
    wire [31:0] IO_sdram_dq;
    wire [3:0]  O_sdram_dqm;

    // -----------------------------------------------------
    // 实例化被测模块 Instantiate UUT
    // -----------------------------------------------------
    sdram_top u_sdram_top (
        .I_ref_clk        (I_ref_clk        ),
        .I_out_clk        (I_out_clk        ),
        .I_rst_n          (I_rst_n          ),
        .I_wr0_clk        (I_wr0_clk        ),
        .I_wr0_req        (I_wr0_req        ),
        .I_wr0_load       (I_wr0_load       ),
        .I_wr0_data       (I_wr0_data       ),
        .I_wr0_saddr      (I_wr0_saddr      ),
        .I_wr0_eaddr      (I_wr0_eaddr      ),
        .I_wr0_burst      (I_wr0_burst      ),
        .I_rd0_clk        (I_rd0_clk        ),
        .I_rd0_req        (I_rd0_req        ),
        .I_rd0_load       (I_rd0_load       ),
        .O_rd0_data       (O_rd0_data       ),
        .I_rd0_saddr      (I_rd0_saddr      ),
        .I_rd0_eaddr      (I_rd0_eaddr      ),
        .I_rd0_burst      (I_rd0_burst      ),
        .I_rd1_clk        (I_rd1_clk        ),
        .I_rd1_req        (I_rd1_req        ),
        .I_rd1_load       (I_rd1_load       ),
        .O_rd1_data       (O_rd1_data       ),
        .I_rd1_saddr      (I_rd1_saddr      ),
        .I_rd1_eaddr      (I_rd1_eaddr      ),
        .I_rd1_burst      (I_rd1_burst      ),
        .I_rd2_clk        (I_rd2_clk        ),
        .I_rd2_req        (I_rd2_req        ),
        .I_rd2_load       (I_rd2_load       ),
        .O_rd2_data       (O_rd2_data       ),
        .I_rd2_saddr      (I_rd2_saddr      ),
        .I_rd2_eaddr      (I_rd2_eaddr      ),
        .I_rd2_burst      (I_rd2_burst      ),
        .I_wr1_clk        (I_wr1_clk        ),
        .I_wr1_req        (I_wr1_req        ),
        .I_wr1_load       (I_wr1_load       ),
        .I_wr1_data       (I_wr1_data       ),
        .I_wr1_saddr      (I_wr1_saddr      ),
        .I_wr1_eaddr      (I_wr1_eaddr      ),
        .I_wr1_burst      (I_wr1_burst      ),
        .O_sdram_init_done(O_sdram_init_done),
        .O_sdram_clk      (O_sdram_clk      ),
        .O_sdram_cke      (O_sdram_cke      ),
        .O_sdram_cs_n     (O_sdram_cs_n     ),
        .O_sdram_ras_n    (O_sdram_ras_n    ),
        .O_sdram_cas_n    (O_sdram_cas_n    ),
        .O_sdram_we_n     (O_sdram_we_n     ),
        .O_sdram_bank     (O_sdram_bank     ),
        .O_sdram_addr     (O_sdram_addr     ),
        .IO_sdram_dq      (IO_sdram_dq      ),
        .O_sdram_dqm      (O_sdram_dqm      )
    );

    // -----------------------------------------------------
    // 实例化双片 16-bit MT48LC16M16A2 拼接为 32-bit SDRAM
    // -----------------------------------------------------
    mt48lc16m16a2 u_sdram_chip0 (
        .Dq    (IO_sdram_dq[15:0]),
        .Addr  (O_sdram_addr),
        .Ba    (O_sdram_bank),
        .Clk   (O_sdram_clk),
        .Cke   (O_sdram_cke),
        .Cs_n  (O_sdram_cs_n),
        .Ras_n (O_sdram_ras_n),
        .Cas_n (O_sdram_cas_n),
        .We_n  (O_sdram_we_n),
        .Dqm   (O_sdram_dqm[1:0])
    );
    
    mt48lc16m16a2 u_sdram_chip1 (
        .Dq    (IO_sdram_dq[31:16]),
        .Addr  (O_sdram_addr),
        .Ba    (O_sdram_bank),
        .Clk   (O_sdram_clk),
        .Cke   (O_sdram_cke),
        .Cs_n  (O_sdram_cs_n),
        .Ras_n (O_sdram_ras_n),
        .Cas_n (O_sdram_cas_n),
        .We_n  (O_sdram_we_n),
        .Dqm   (O_sdram_dqm[3:2])
    );

    // -----------------------------------------------------
    // 时钟生成
    // -----------------------------------------------------
    always #5       I_ref_clk = ~I_ref_clk;     // 100MHz SDRAM Control Clock
    always #5       I_out_clk = ~I_out_clk;     // 100MHz SDRAM Physical Clock (可加相移)
    always #6.734   I_wr0_clk = ~I_wr0_clk;     // 74.25MHz Camera 720p 像素钟
    always #6.734   I_rd0_clk = ~I_rd0_clk;     // 74.25MHz Screen 720p 像素钟
    always #3.333   I_rd1_clk = ~I_rd1_clk;     // 150MHz 算法处理模块时钟
    always #3.333   I_rd2_clk = ~I_rd2_clk;     
    always #3.333   I_wr1_clk = ~I_wr1_clk;

    // -----------------------------------------------------
    // 核心并发测试进程
    // -----------------------------------------------------
    reg start_sim = 0;

    initial begin
        I_rst_n <= 0;
        // 等待100ns后复位完成
        #100 I_rst_n <= 1;
        // 等待SDRAM初始化完成
        wait (O_sdram_init_done == 1'b1);
        #1000;
        $display("======= SDRAM Initialization Done. Starting Frame Processing Simulation =======");
        start_sim = 1;

        // 运行测试较长时间后结束
        #50_000_000; 
        $display("======= Simulation Finished =======");
        $stop;
    end

    // ---------------------------
    // [测试行为1] 摄像头写入 WR0
    // ---------------------------
    integer wr0_cnt = 0;
    always @(posedge I_wr0_clk) begin
        if (!I_rst_n) begin
            wr0_cnt <= 0;
            I_wr0_req <= 0;
            I_wr0_load <= 0;
        end else if (start_sim) begin
            if (wr0_cnt == 0) begin
                I_wr0_load <= 1;               // 产生地址清零，FIFO清零脉冲
                I_wr0_saddr <= 24'h00_0000;    // 本次向内存 0x00_0000 区间写入
                I_wr0_eaddr <= WORDS;
                wr0_cnt <= wr0_cnt + 1;
            end else if (wr0_cnt == 1) begin
                I_wr0_load <= 0;
                wr0_cnt <= wr0_cnt + 1;
            end else if (wr0_cnt < WORDS + 2) begin // 写满一帧
                I_wr0_req <= 1;                // 打开FIFO写逻辑
                // 模拟不断生成新像素/读取HEX文件作为数据源
                I_wr0_data <= camera_mem[wr0_cnt - 2];
                wr0_cnt <= wr0_cnt + 1;
            end else begin
                I_wr0_req <= 0;
                // 模拟帧间消隐期 Blanking Time
                if (wr0_cnt == WORDS + 60000) begin
                    wr0_cnt <= 0;              // 开始下一帧循环
                end else begin
                    wr0_cnt <= wr0_cnt + 1;
                end
            end
        end
    end

    // ---------------------------
    // [测试行为2] 屏幕读出 RD0
    // ---------------------------
    integer rd0_cnt = 0;
    always @(posedge I_rd0_clk) begin
        if (!I_rst_n) begin
            rd0_cnt <= 0;
            I_rd0_req <= 0;
            I_rd0_load<= 0;
        end else if (start_sim) begin
            if (rd0_cnt == 0) begin
                I_rd0_load <= 1;
                I_rd0_saddr <= 24'h00_0000; // 假定正将摄像头缓冲区的数据扫到屏幕上
                I_rd0_eaddr <= WORDS;
                rd0_cnt <= rd0_cnt + 1;
            end else if (rd0_cnt == 1) begin
                I_rd0_load <= 0;
                rd0_cnt <= rd0_cnt + 1;
            end else if (rd0_cnt < WORDS + 2) begin
                I_rd0_req <= 1;             // 给屏幕FIFO发出读使能
                rd0_cnt <= rd0_cnt + 1;
            end else begin
                I_rd0_req <= 0;
                // 模拟屏幕视频流消隐期 Blanking Time
                if (rd0_cnt == WORDS + 60000) begin
                    rd0_cnt <= 0;           // 下一帧刷新
                end else begin
                    rd0_cnt <= rd0_cnt + 1;
                end
            end
        end
    end

    // ---------------------------
    // [测试行为3] 算法双读加打拍写 Algo (RD1, RD2, WR1)
    // ---------------------------
    integer algo_cnt = 0;
    reg [2:0] valid_pipe [0:ALGO_DELAY-1];
    reg [31:0] data_pipe [0:ALGO_DELAY-1];
    integer i;

    always @(posedge I_rd1_clk) begin
        if (!I_rst_n) begin
            algo_cnt <= 0;
            I_rd1_req <= 0; I_rd2_req <= 0; I_wr1_req <= 0;
            I_rd1_load<= 0; I_rd2_load<= 0; I_wr1_load<= 0;
            for (i=0; i<ALGO_DELAY; i=i+1) begin
                valid_pipe[i] <= 0;
                data_pipe[i] <= 0;
            end
        end else if (start_sim) begin
            // FIFO 调度逻辑
            if (algo_cnt == 0) begin
                I_rd1_load <= 1; I_rd1_saddr <= 24'h10_0000; I_rd1_eaddr <= WORDS;
                I_rd2_load <= 1; I_rd2_saddr <= 24'h20_0000; I_rd2_eaddr <= WORDS;
                I_wr1_load <= 1; I_wr1_saddr <= 24'h30_0000; I_wr1_eaddr <= WORDS;
                algo_cnt <= algo_cnt + 1;
            end else if (algo_cnt == 1) begin
                I_rd1_load <= 0; I_rd2_load <= 0; I_wr1_load <= 0;
                algo_cnt <= algo_cnt + 1;
            end else if (algo_cnt < WORDS + 2) begin
                I_rd1_req <= 1;  I_rd2_req <= 1; // 并发请求两路缓存数据用于合成
                algo_cnt <= algo_cnt + 1;
            end else begin
                I_rd1_req <= 0;  I_rd2_req <= 0;
                // 留出时间让最后几拍写回，然后进行模拟空白期
                if (algo_cnt == WORDS + 50000) begin
                    algo_cnt <= 0;
                end else begin
                    algo_cnt <= algo_cnt + 1;
                end
            end

            // 打拍管线 (模拟多帧合成处理延时)
            // 第一拍：假定发出req后的下一个周期从FIFO中取得了像素
            valid_pipe[0] <= (algo_cnt >= 2 && algo_cnt < WORDS + 2);
            data_pipe[0]  <= O_rd1_data + O_rd2_data; // 此处模拟简单的双帧ADD处理

            // 第2 ~ ALGO_DELAY拍：流水线顺延
            for (i=1; i<ALGO_DELAY; i=i+1) begin
                valid_pipe[i] <= valid_pipe[i-1];
                data_pipe[i]  <= data_pipe[i-1];
            end

            // 最后一拍：写入结果FIFO (WR1)
            I_wr1_req  <= valid_pipe[ALGO_DELAY-1];
            I_wr1_data <= data_pipe[ALGO_DELAY-1];
        end
    end

endmodule
