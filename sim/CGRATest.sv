`include "define.sv"

task automatic GenClk(
    ref logic clk, input realtime delay, realtime period
);
    clk = 1'b0;
    #delay;
    forever #(period/2) clk = ~clk;
endtask

task automatic GenRst(
    ref logic clk,
    ref logic rst,
    input int start,
    input int duration
);
    rst = 1'b0;
    repeat(start) @(posedge clk);
    rst = 1'b1;
    repeat(duration) @(posedge clk);
    rst = 1'b0;
endtask

task automatic io_write(
    input integer c,
    // 6 + 32 + 1 + 3
    ref logic [40 : 0]vlw
);
    vlw = c + (1 << 3) + (1 << 4) + (1 << 36);
endtask

module CGRATest;

// cfg mem
    logic [`CFGW-1 : 0] cfg_ram [`CFG_LENGTH-1 : 0];
    string file_cfg  = "../data/exam.bit";
    initial begin
        $readmemh(file_cfg, cfg_ram);
    end

// clk rst
    logic clk, rst;
    initial GenClk(clk, 0, 10);

// cfg port
    logic [$clog2(`CFG_LENGTH)-1 : 0] addr;
    logic cfg_en;
    logic [`AW-1 : 0] cfg_addr;
    logic [`DW-1 : 0] cfg_data;

    // CGRA inst
    logic io_en [0 : 7];
    logic [`DW-1 : 0] io_in [0 : 11];
    logic [`DW-1 : 0] io_out [0 : 11];

// host interface
    logic [5:0]  io_hostInterface_read_addr         [8];
    logic        io_hostInterface_read_data_ready   [8];
    logic        io_hostInterface_read_data_valid   [8];
    logic [31:0] io_hostInterface_read_data_bits    [8];
    logic [5:0]  io_hostInterface_write_addr        [8];
    logic        io_hostInterface_write_data_ready  [8];
    logic        io_hostInterface_write_data_valid  [8];
    logic [31:0] io_hostInterface_write_data_bits   [8];
    logic [2:0]  io_hostInterface_cycle             [8];

    logic [40 : 0]vlw[8];
    generate
        for(genvar i = 0; i < 8; i++)begin
            assign {io_hostInterface_write_addr[i], io_hostInterface_write_data_bits[i], 
            io_hostInterface_write_data_valid[i], io_hostInterface_cycle[i]} = vlw[i];
        end
    endgenerate

// 
    initial begin
        GenRst(clk, rst, 0, 20);
        addr = 0;
        cfg_en = 0;
        @(posedge clk);
        for(integer i = 0; i < `CFG_LENGTH; i++) begin : cfg_readin
            cfg_en = 1;
            cfg_addr = cfg_ram[addr][51 : 32];
            cfg_data = cfg_ram[addr][31 : 0];
            @(posedge clk);
            addr++;
        end

        repeat(2) @(posedge clk);
        cfg_en = 0;

        io_hostInterface_read_data_ready = '{8{'0}};

        io_write(0, vlw[5]);
        @(posedge clk);
        io_write(0, vlw[3]);
        @(posedge clk);
        io_write(2, vlw[1]);
        @(posedge clk);
        io_write(0, vlw[7]);
        @(posedge clk);
        io_write(1, vlw[7]);
        @(posedge clk);
        io_write(1, vlw[4]);
        @(posedge clk);
        io_write(1, vlw[3]);
        @(posedge clk);
        io_write(0, vlw[6]);
        @(posedge clk);
        io_write(2, vlw[3]);
        @(posedge clk);
        io_write(1, vlw[0]);
        @(posedge clk);
        io_write(0, vlw[0]);
        @(posedge clk);
        io_write(0, vlw[2]);
        @(posedge clk);
        io_write(1, vlw[5]);
        @(posedge clk);
        io_write(0, vlw[1]);
        @(posedge clk);

// 不可直接对wr_vld赋值因为前面已经用vlw驱动
        vlw= '{8{'0}};
        @(posedge clk);

// enable computation
        io_en = '{8{'1}};

// input test data
        for(integer i = 0; i < 15; i++) begin
            @(posedge clk);
        end

        io_en = '{8{'0}};
        @(posedge clk);

        #4000 $finish;
    end

    CGRA HETA(
.clock                                      (clk    ),
.reset                                      (rst    ),
.io_cfg_en                                  (cfg_en ),
.io_cfg_addr                                (cfg_addr[17 : 0]   ),
.io_cfg_data                                (cfg_data           ),

.io_hostInterface_0_read_addr         (io_hostInterface_read_addr         [0]),
.io_hostInterface_0_read_data_ready   (io_hostInterface_read_data_ready   [0]),
.io_hostInterface_0_read_data_valid   (io_hostInterface_read_data_valid   [0]),
.io_hostInterface_0_read_data_bits    (io_hostInterface_read_data_bits    [0]),
.io_hostInterface_0_write_addr        (io_hostInterface_write_addr        [0]),
.io_hostInterface_0_write_data_ready  (io_hostInterface_write_data_ready  [0]),
.io_hostInterface_0_write_data_valid  (io_hostInterface_write_data_valid  [0]),
.io_hostInterface_0_write_data_bits   (io_hostInterface_write_data_bits   [0]),
.io_hostInterface_0_cycle             (io_hostInterface_cycle             [0]),
.io_hostInterface_1_read_addr         (io_hostInterface_read_addr         [1]),
.io_hostInterface_1_read_data_ready   (io_hostInterface_read_data_ready   [1]),
.io_hostInterface_1_read_data_valid   (io_hostInterface_read_data_valid   [1]),
.io_hostInterface_1_read_data_bits    (io_hostInterface_read_data_bits    [1]),
.io_hostInterface_1_write_addr        (io_hostInterface_write_addr        [1]),
.io_hostInterface_1_write_data_ready  (io_hostInterface_write_data_ready  [1]),
.io_hostInterface_1_write_data_valid  (io_hostInterface_write_data_valid  [1]),
.io_hostInterface_1_write_data_bits   (io_hostInterface_write_data_bits   [1]),
.io_hostInterface_1_cycle             (io_hostInterface_cycle             [1]),
.io_hostInterface_2_read_addr         (io_hostInterface_read_addr         [2]),
.io_hostInterface_2_read_data_ready   (io_hostInterface_read_data_ready   [2]),
.io_hostInterface_2_read_data_valid   (io_hostInterface_read_data_valid   [2]),
.io_hostInterface_2_read_data_bits    (io_hostInterface_read_data_bits    [2]),
.io_hostInterface_2_write_addr        (io_hostInterface_write_addr        [2]),
.io_hostInterface_2_write_data_ready  (io_hostInterface_write_data_ready  [2]),
.io_hostInterface_2_write_data_valid  (io_hostInterface_write_data_valid  [2]),
.io_hostInterface_2_write_data_bits   (io_hostInterface_write_data_bits   [2]),
.io_hostInterface_2_cycle             (io_hostInterface_cycle             [2]),
.io_hostInterface_3_read_addr         (io_hostInterface_read_addr         [3]),
.io_hostInterface_3_read_data_ready   (io_hostInterface_read_data_ready   [3]),
.io_hostInterface_3_read_data_valid   (io_hostInterface_read_data_valid   [3]),
.io_hostInterface_3_read_data_bits    (io_hostInterface_read_data_bits    [3]),
.io_hostInterface_3_write_addr        (io_hostInterface_write_addr        [3]),
.io_hostInterface_3_write_data_ready  (io_hostInterface_write_data_ready  [3]),
.io_hostInterface_3_write_data_valid  (io_hostInterface_write_data_valid  [3]),
.io_hostInterface_3_write_data_bits   (io_hostInterface_write_data_bits   [3]),
.io_hostInterface_3_cycle             (io_hostInterface_cycle             [3]),
.io_hostInterface_4_read_addr         (io_hostInterface_read_addr         [4]),
.io_hostInterface_4_read_data_ready   (io_hostInterface_read_data_ready   [4]),
.io_hostInterface_4_read_data_valid   (io_hostInterface_read_data_valid   [4]),
.io_hostInterface_4_read_data_bits    (io_hostInterface_read_data_bits    [4]),
.io_hostInterface_4_write_addr        (io_hostInterface_write_addr        [4]),
.io_hostInterface_4_write_data_ready  (io_hostInterface_write_data_ready  [4]),
.io_hostInterface_4_write_data_valid  (io_hostInterface_write_data_valid  [4]),
.io_hostInterface_4_write_data_bits   (io_hostInterface_write_data_bits   [4]),
.io_hostInterface_4_cycle             (io_hostInterface_cycle             [4]),
.io_hostInterface_5_read_addr         (io_hostInterface_read_addr         [5]),
.io_hostInterface_5_read_data_ready   (io_hostInterface_read_data_ready   [5]),
.io_hostInterface_5_read_data_valid   (io_hostInterface_read_data_valid   [5]),
.io_hostInterface_5_read_data_bits    (io_hostInterface_read_data_bits    [5]),
.io_hostInterface_5_write_addr        (io_hostInterface_write_addr        [5]),
.io_hostInterface_5_write_data_ready  (io_hostInterface_write_data_ready  [5]),
.io_hostInterface_5_write_data_valid  (io_hostInterface_write_data_valid  [5]),
.io_hostInterface_5_write_data_bits   (io_hostInterface_write_data_bits   [5]),
.io_hostInterface_5_cycle             (io_hostInterface_cycle             [5]),
.io_hostInterface_6_read_addr         (io_hostInterface_read_addr         [6]),
.io_hostInterface_6_read_data_ready   (io_hostInterface_read_data_ready   [6]),
.io_hostInterface_6_read_data_valid   (io_hostInterface_read_data_valid   [6]),
.io_hostInterface_6_read_data_bits    (io_hostInterface_read_data_bits    [6]),
.io_hostInterface_6_write_addr        (io_hostInterface_write_addr        [6]),
.io_hostInterface_6_write_data_ready  (io_hostInterface_write_data_ready  [6]),
.io_hostInterface_6_write_data_valid  (io_hostInterface_write_data_valid  [6]),
.io_hostInterface_6_write_data_bits   (io_hostInterface_write_data_bits   [6]),
.io_hostInterface_6_cycle             (io_hostInterface_cycle             [6]),
.io_hostInterface_7_read_addr         (io_hostInterface_read_addr         [7]),
.io_hostInterface_7_read_data_ready   (io_hostInterface_read_data_ready   [7]),
.io_hostInterface_7_read_data_valid   (io_hostInterface_read_data_valid   [7]),
.io_hostInterface_7_read_data_bits    (io_hostInterface_read_data_bits    [7]),
.io_hostInterface_7_write_addr        (io_hostInterface_write_addr        [7]),
.io_hostInterface_7_write_data_ready  (io_hostInterface_write_data_ready  [7]),
.io_hostInterface_7_write_data_valid  (io_hostInterface_write_data_valid  [7]),
.io_hostInterface_7_write_data_bits   (io_hostInterface_write_data_bits   [7]),
.io_hostInterface_7_cycle             (io_hostInterface_cycle             [7]),

  .io_en_0      (io_en[0]),
  .io_en_1      (io_en[1]),
  .io_en_2      (io_en[2]),
  .io_en_3      (io_en[3]),
  .io_en_4      (io_en[4]),
  .io_en_5      (io_en[5]),
  .io_en_6      (io_en[6]),
  .io_en_7      (io_en[7]),

  .io_in_0      (io_in[0]),
  .io_in_1      (io_in[1]),
  .io_in_2      (io_in[2]),
  .io_in_3      (io_in[3]),
  .io_in_4      (io_in[4]),
  .io_in_5      (io_in[5]),
  .io_in_6      (io_in[6]),
  .io_in_7      (io_in[7]),
  .io_in_8      (io_in[8]),
  .io_in_9      (io_in[9]),
  .io_in_10     (io_in[10]),
  .io_in_11     (io_in[11]),

  .io_out_0     (io_in[0]),
  .io_out_1     (io_in[1]),
  .io_out_2     (io_in[2]),
  .io_out_3     (io_in[3]),
  .io_out_4     (io_in[4]),
  .io_out_5     (io_in[5]),
  .io_out_6     (io_in[6]),
  .io_out_7     (io_in[7]),
  .io_out_8     (io_in[8]),
  .io_out_9     (io_in[9]),
  .io_out_10    (io_in[10]),
  .io_out_11    (io_in[11])

);

endmodule
