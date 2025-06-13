module datapath (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        datapath_start,
  input  logic [9:0]  input_key,
  input  logic        datapath_done_ack,    // Handshake acknowledgment
  output logic        datapath_done,
  // Memory interface
  output logic [7:0]  s_mem_addr,
  output logic [7:0]  s_mem_data_write,
  input  logic [7:0]  s_mem_data_read,
  output logic        s_mem_wren
);

  logic [6:0] state;
  // FSM State definition
 // state[6:4] = additional bits to make state unique
 // state[3] = placeholder - for future usage
 // state[2] = shuffle_start
 // state[1] = init_start
 // state[0] = datapath_done
  parameter [6:0] IDLE        = 6'b000_0000;  // 
  parameter [6:0] INIT_MEMORY = 6'b001_0010;  // init_start=1 (bit 0)
  parameter [6:0] SHUFFLE     = 6'b010_0100;  // shuffle_start=1 (bit 1)
  parameter [6:0] COMPLETE    = 6'b011_0001;   

  // Internal control wires
  logic init_start;
  logic shuffle_start;
  logic init_done;
  logic shuffle_done;
  logic shuffle_done_ack;  // Handshake acknowledgment
  logic init_done_ack;  // Handshake acknowledgment

  assign datapath_done = state[0];
  assign init_start  = state[1];
  assign shuffle_start  = state[2];

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
    .init_done (init_done),
	 .done_ack       (init_done_ack),      // Handshake acknowledgment
  );

  // Instantiate KSA shuffle module
  ksa_shuffle ksa_shuffle_inst (
    .clk          (clk),
    .reset_n      (reset_n),
    .start        (shuffle_start),   
    .input_key    (input_key),
    .mem_addr     (mem_addr_shuffle),
    .mem_data_read    (s_mem_data_read),
    .mem_data_write  (mem_data_write_shuffle),
    .mem_wren     (mem_wren_shuffle),
    .done         (shuffle_done),
    .done_ack       (shuffle_done_ack),      // Handshake acknowledgment
  );

  // Main FSM logic
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      shuffle_done_ack <= 1'b0;
		init_done_ack <= 1'b0;
    end else begin
      // Default outputs
      shuffle_done_ack <= 1'b0;
		init_done_ack <= 1'b0;
      case (state)
        IDLE: begin
          if (datapath_start) begin
            state <= INIT_MEMORY;
          end
        end

        INIT_MEMORY: begin
          if (init_done) begin
            state <= SHUFFLE;
				init_done_ack <= 1'b1; 
          end
        end

        SHUFFLE: begin
          if (shuffle_done) begin
            state <= COMPLETE;
            shuffle_done_ack <= 1'b1; 
          end
        end

        COMPLETE: begin
          if (datapath_done_ack) begin
            state <= IDLE;
          end
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
