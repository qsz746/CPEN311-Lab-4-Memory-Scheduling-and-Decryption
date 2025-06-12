module datapath (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        datapath_start,
  input  logic [9:0]  input_key,
  output logic        datapath_done,
  // Memory interface
  output logic [7:0]  s_mem_addr,
  output logic [7:0]  s_mem_data_write,
  input  logic [7:0]  s_mem_data_read,
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

  // Internal control wires
  logic init_start;
  logic shuffle_start;
  logic init_done;
  logic shuffle_done;

  assign init_start  = state[0];
	assign shuffle_start  = state[1];

  logic [7:0] mem_addr_init;
  logic [7:0] mem_data_write_init;
  logic       mem_wren_init;

  logic [7:0] mem_addr_shuffle;
  logic [7:0] mem_data_write_shuffle;
  logic       mem_wren_shuffle;

  // Instantiate memory init module
  memory_init memory_init_inst (
    .clk       (clk),
    .start     (init_start),
    .reset_n   (reset_n),
    .mem_addr  (mem_addr_init),
    .mem_data  (mem_data_write_init),
    .mem_wren  (mem_wren_init),
    .init_done (init_done)
  );

  // Instantiate KSA shuffle module
  ksa_shuffle ksa_shuffle_inst (
    .clk          (clk),
    .reset_n      (reset_n),
    .start        (1'b0),   
    .input_key    (input_key),
    .mem_addr     (mem_addr_shuffle),
    .mem_data_read    (s_mem_data_read),
    .mem_data_write  (mem_data_write_shuffle),
    .mem_wren     (mem_wren_shuffle),
    .done         (shuffle_done)
  );

  // Main FSM logic
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      datapath_done <= 1'b0;
    end else begin
      // Default outputs
      datapath_done <= 1'b0;

      case (state)
        IDLE: begin
          if (datapath_start) begin
            state <= INIT_MEMORY;
          end
        end

        INIT_MEMORY: begin
          if (init_done) begin
            state <= SHUFFLE;
          end
        end

        SHUFFLE: begin
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


  // COMBINATIONAL OUTPUT ROUTING (NEW)
  always_comb begin
    // Default outputs
    s_mem_addr       = 8'd0;
    s_mem_data_write = 8'd0;
    s_mem_wren       = 1'b0;

    // Route signals based on state
    case (state)
      INIT_MEMORY: begin
        s_mem_addr       = mem_addr_init;
        s_mem_data_write = mem_data_write_init;
        s_mem_wren       = mem_wren_init;
      end
      SHUFFLE: begin
        s_mem_addr       = mem_addr_shuffle;
        s_mem_data_write = mem_data_write_shuffle;
        s_mem_wren       = mem_wren_shuffle;
      end
      default: ; // IDLE and COMPLETE use defaults
    endcase
  end

endmodule
