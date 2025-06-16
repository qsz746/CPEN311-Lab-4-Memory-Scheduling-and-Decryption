module multicore_decryption (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  output logic [23:0] secret_key,
  output logic        done,
  output logic        secret_key_found,
  output logic [1:0]  active_core
);

  // Core control signals
  logic [3:0] core_start;
  logic [3:0] core_done;
  logic [3:0] core_found;
  logic [23:0] core_secret_key[4];
 
  
  // Key range divisions (0x000000-0x3FFFFF split into 4 equal parts)
  localparam [23:0] CORE0_START = 24'h000000;
  localparam [23:0] CORE0_END   = 24'h0FFFFF;
  localparam [23:0] CORE1_START = 24'h100000;
  localparam [23:0] CORE1_END   = 24'h1FFFFF;
  localparam [23:0] CORE2_START = 24'h200000;
  localparam [23:0] CORE2_END   = 24'h2FFFFF;
  localparam [23:0] CORE3_START = 24'h300000;
  localparam [23:0] CORE3_END   = 24'h3FFFFF;
 

  // Instantiate all four cores
  decryption_core core0 (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),  // Start all cores simultaneously
    .secret_key(core_secret_key[0]),
    .secret_key_start_value(CORE0_START),
    .secret_key_end_value(CORE0_END),
    .done(core_done[0]),
    .secret_key_found_flag(core_found[0]),
    .stop(secret_key_found)
  );
  
  decryption_core core1 (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .secret_key(core_secret_key[1]),
    .secret_key_start_value(CORE1_START),
    .secret_key_end_value(CORE1_END),
    .done(core_done[1]),
    .secret_key_found_flag(core_found[1]),
    .stop(secret_key_found)
  );
  
  decryption_core core2 (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .secret_key(core_secret_key[2]),
    .secret_key_start_value(CORE2_START),
    .secret_key_end_value(CORE2_END),
    .done(core_done[2]),
    .secret_key_found_flag(core_found[2]),
    .stop(secret_key_found)
  );
  
  decryption_core core3 (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .secret_key(core_secret_key[3]),
    .secret_key_start_value(CORE3_START),
    .secret_key_end_value(CORE3_END),
    .done(core_done[3]),
    .secret_key_found_flag(core_found[3]),
    .stop(secret_key_found)
  );

  // Output logic - no FSM needed
  always_comb begin
    // Default outputs
    secret_key = core_secret_key[0];
    done = (core_found[0] | core_found[1] | core_found[2] | core_found[3]) | (&core_done);  //Any one core finds the key (early exit), or all cores finish, and none found it
    secret_key_found = core_found[0] | core_found[1] | core_found[2] | core_found[3];
    active_core = 2'b00;
    
    // Find which core found the key (priority encoder)
    if (core_found[0]) begin
      secret_key = core_secret_key[0];
      active_core = 2'b00;
    end
    else if (core_found[1]) begin
      secret_key = core_secret_key[1];
      active_core = 2'b01;
    end
    else if (core_found[2]) begin
      secret_key = core_secret_key[2];
      active_core = 2'b10;
    end
    else if (core_found[3]) begin
      secret_key = core_secret_key[3];
      active_core = 2'b11;
    end
  end

endmodule