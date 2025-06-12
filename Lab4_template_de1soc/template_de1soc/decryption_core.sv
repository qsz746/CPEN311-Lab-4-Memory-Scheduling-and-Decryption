module decryption_core (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic [9:0]  input_key,
  output logic        done
);

  // Internal memory interface signals
  logic [7:0]  s_mem_addr;
  logic [7:0]  s_mem_data_in;
  logic [7:0]  s_mem_data_out;
  logic        s_mem_wren;

  // Instantiate datapath
  datapath datapath_inst (
    .clk                   (clk),
    .reset_n               (reset_n),
    .datapath_start        (start),
    .input_key             (input_key),
    .done                  (done),
    // Memory interface
    .s_mem_addr     (s_mem_addr),
    .s_mem_data_in  (s_mem_data_in),
    .s_mem_data_out (s_mem_data_out),
    .s_mem_wren     (s_mem_wren)
  );

  // Instantiate S-memory  
  s_memory memory_inst (
    .clock      (clk),
    .address    (s_mem_addr),
    .data       (s_mem_data_out),
    .q          (s_mem_data_in),
    .wren       (s_mem_wren)
  );

endmodule