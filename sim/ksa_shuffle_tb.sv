

module ksa_shuffle_tb();

  // Parameters
  localparam CLK_PERIOD = 10; // 10ns = 100MHz clock

  // Signals
  reg        clk;
  reg        reset_n;
  reg        start;
  reg        done_ack;
  reg [23:0] secret_key;
  wire [7:0] mem_addr;
  wire [7:0] mem_data_read;
  wire [7:0] mem_data_write;
  wire       mem_wren;
  wire       done;

  // Instantiate DUT (Verilog)
  ksa_shuffle dut (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .done_ack(done_ack),
    .secret_key(secret_key),
    .mem_addr(mem_addr),
    .mem_data_read(mem_data_read),
    .mem_data_write(mem_data_write),
    .mem_wren(mem_wren),
    .done(done)
  );

  // Instantiate s_memory (VHDL)
  s_memory s_mem_inst (
    .address(mem_addr),
    .clock(clk),
    .data(mem_data_write),
    .wren(mem_wren),
    .q(mem_data_read)
  );

  // Clock generation
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize inputs
    reset_n = 1'b0;
    start = 1'b0;
    done_ack = 1'b0;
    secret_key = 24'h000249; // Example key from lab document
    
    // Reset
    #(CLK_PERIOD*2);
    reset_n = 1'b1;
    #(CLK_PERIOD);
    
    // Start the shuffle
    start = 1'b1;
    #(CLK_PERIOD);
    start = 1'b0;
    
    // Wait for completion
    wait (done == 1'b1);
    #(CLK_PERIOD);
    done_ack = 1'b1;
    #(CLK_PERIOD);
    done_ack = 1'b0;

    // Add delay to see final state in waveforms
    #1000;
    $finish;
  end

endmodule