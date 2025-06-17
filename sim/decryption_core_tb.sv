
module tb_decryption_core;

  // Clock parameters
  parameter CLK_PERIOD = 10; // 10ns = 100MHz clock

  // DUT signals
  logic        clk;
  logic        reset_n;
  logic        start;
  logic        stop;
  logic [23:0] secret_key;
  logic [23:0] secret_key_start_value = 24'h000000;
  logic [23:0] secret_key_end_value = 24'hFFFFFF;
  logic        done;
  logic        secret_key_found_flag;

  // Instantiate DUT
  decryption_core dut (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .stop(stop),
    .secret_key(secret_key),
    .secret_key_start_value(secret_key_start_value),
    .secret_key_end_value(secret_key_end_value),
    .done(done),
    .secret_key_found_flag(secret_key_found_flag)
  );

  // Clock generation
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initial reset
    reset_n = 0;
    start = 0;
    stop = 0;
    #(CLK_PERIOD*2);
    
    // Release reset
    reset_n = 1;
    #(CLK_PERIOD*2);
    
    // Start operation
    start = 1;
    #(CLK_PERIOD);
    start = 0;
    
    #(CLK_PERIOD*5);

    force dut.datapath_done = 1'b1;
    force secret_key_found_flag = 1'b1;
    #(CLK_PERIOD);
    release secret_key_found_flag;
    release dut.datapath_done;

    #(CLK_PERIOD*10)

    // Test stop case
    reset_n = 0;
    #(CLK_PERIOD);
    reset_n = 1;
    #(CLK_PERIOD);
    
    start = 1;
    #(CLK_PERIOD);
    start = 0;
    #(CLK_PERIOD*3);
    
    // Force early termination with stop signal
    stop = 1;
    #(CLK_PERIOD);
    stop = 0;

    // Final wait
    #(CLK_PERIOD*10);
    $stop;
  end

endmodule