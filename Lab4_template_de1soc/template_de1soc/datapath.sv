module datapath (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        datapath_start,
  input  logic [9:0]  input_key,
  output logic        datapath_done,
  // Memory interface
  output logic [7:0]  s_mem_addr,
  output logic [7:0]  s_mem_data_out,
  input  logic [7:0]  s_mem_data_in,
  output logic        s_mem_wren
);

  logic [5:0] state;
  // FSM State definition
 // state[5:3] = additional bits to make state unique
 // state[2] = placeholder - for future usage
 // state[1] = shuffle_start
 // state[0] = init_start
  parameter [5:0] IDLE        = 6'b000_000;  // 
  parameter [5:0] INIT_MEMORY = 6'b001_001;  // init_start=1 (bit 0)
  parameter [5:0] SHUFFLE     = 6'b010_010;  // shuffle_start=1 (bit 1)
  parameter [5:0] COMPLETE    = 6'b011_000;   

	assign init_start  = state[0];
	assign shuffle_start  = state[1];


  // Internal control wires
  logic init_start;
  logic shuffle_start;
  logic init_done;
  logic shuffle_done;

  logic [7:0] mem_addr_init;
  logic [7:0] mem_data_out_init;
  logic       mem_wren_init;

  logic [7:0] mem_addr_shuffle;
  logic [7:0] mem_data_out_shuffle;
  logic       mem_wren_shuffle;

  // Instantiate memory init module
  memory_init memory_init_inst (
    .clk       (clk),
    .start     (init_start),
    .reset_n   (reset_n),
    .mem_addr  (mem_addr_init),
    .mem_data  (mem_data_out_init),
    .mem_wren  (mem_wren_init),
    .init_done (init_done)
  );

  // Instantiate KSA shuffle module
  ksa_shuffle ksa_shuffle_inst (
    .clk          (clk),
    .reset_n      (reset_n),
    .start        (shuffle_start),   
    .input_key    (input_key),
    .mem_addr     (mem_addr_shuffle),
    .mem_data_in  (mem_data_in),
    .mem_data_out (mem_data_out_shuffle),
    .mem_wren     (mem_wren_shuffle),
    .done         (shuffle_done)
  );

  // Main FSM logic
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state         <= IDLE;
      mem_addr      <= 8'd0;
      mem_data_out  <= 8'd0;
      mem_wren      <= 1'b0;
      datapath_done <= 1'b0;
    end else begin
      // Default outputs
      mem_addr     <= 8'd0;
      mem_data_out <= 8'd0;
      mem_wren     <= 1'b0;
      datapath_done    <= 1'b0;

      case (state)
        IDLE: begin
          if (datapath_start) begin
            state <= INIT_MEMORY;
          end
        end

        INIT_MEMORY: begin
          s_mem_addr     <= mem_addr_init;
          s_mem_data_in  <= mem_data_out_init;
          s_mem_wren     <= mem_wren_init;

          if (init_done) begin
            state <= SHUFFLE;
          end
        end

        SHUFFLE: begin
          s_mem_addr       <= mem_addr_shuffle;
          s_mem_data_in    <= mem_data_in_shuffle;
          s_mem_data_out   <= mem_data_out_shuffle
          s_mem_wren       <= mem_wren_shuffle;

          if (shuffle_done) begin
            state <= COMPLETE;
          end
        end

        COMPLETE: begin
          datapath_done  <= 1'b1;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
