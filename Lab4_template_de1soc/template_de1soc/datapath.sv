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

  logic [8:0] state;
  // FSM State definition
  // state[8:5] = additional bits to make state unique
  // state[4] = register_for_shuffle
  // state[3] = register_for_init_memory
  // state[2] = shuffle_start
  // state[1] = init_start
  // state[0] = datapath_done

  parameter [8:0] IDLE                 = 9'b0000_00_00_0;
  parameter [8:0] INIT_MEMORY          = 9'b0001_01_01_0;  // init_start = 1, register_for_init_memory = 1
  parameter [8:0] WAIT_FOR_INIT_MEMORY = 9'b0010_01_00_0;  // register_for_init_memory = 1
  parameter [8:0] SHUFFLE              = 9'b0011_10_10_0;  // shuffle_start = 1,  register_for_shuffle = 1
  parameter [8:0] WAIT_FOR_SHUFFLE     = 9'b0100_10_00_0;  // register_for_shuffle = 1
  parameter [8:0] COMPLETE             = 9'b0101_00_00_1;

  // Internal control wires
  logic init_start;
  logic shuffle_start;
  logic init_done;
  logic shuffle_done;
  logic shuffle_done_ack;  // Handshake acknowledgment
  logic init_done_ack;     // Handshake acknowledgment

  assign register_for_shuffle     = state[4];
  assign register_for_init_memory = state[3];
  assign shuffle_start            = state[2];
  assign init_start               = state[1];
  assign datapath_done            = state[0];

  logic [7:0] mem_addr_init;
  logic [7:0] mem_data_write_init;
  logic       mem_wren_init;

  logic [7:0] mem_addr_shuffle;
  logic [7:0] mem_data_write_shuffle;
  logic       mem_wren_shuffle;

  // Registered outputs
  logic [7:0] s_mem_addr_reg;
  logic [7:0] s_mem_data_write_reg;
  logic       s_mem_wren_reg;

  // Assign registered outputs to ports
  assign s_mem_addr        = s_mem_addr_reg;
  assign s_mem_data_write  = s_mem_data_write_reg;
  assign s_mem_wren        = s_mem_wren_reg;

  // Instantiate memory init module
  memory_init memory_init_inst (
    .clk        (clk),
    .start      (init_start),
    .reset_n    (reset_n),
    .mem_addr   (mem_addr_init),
    .mem_data   (mem_data_write_init),
    .mem_wren   (mem_wren_init),
    .init_done  (init_done),
    .done_ack   (init_done_ack)
  );

  // Instantiate KSA shuffle module
  ksa_shuffle ksa_shuffle_inst (
    .clk            (clk),
    .reset_n        (reset_n),
    .start          (shuffle_start),   
    .input_key      (input_key),
    .mem_addr       (mem_addr_shuffle),
    .mem_data_read  (s_mem_data_read),
    .mem_data_write (mem_data_write_shuffle),
    .mem_wren       (mem_wren_shuffle),
    .done           (shuffle_done),
    .done_ack       (shuffle_done_ack)
  );

  // Main FSM logic
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      shuffle_done_ack <= 1'b0;
      init_done_ack    <= 1'b0;
    end else begin
      // Default outputs
      shuffle_done_ack <= 1'b0;
      init_done_ack    <= 1'b0;
      case (state)
        IDLE: begin
          if (datapath_start)
            state <= INIT_MEMORY;
        end

        INIT_MEMORY: begin
          state <= WAIT_FOR_INIT_MEMORY;
        end

        WAIT_FOR_INIT_MEMORY: begin
          if (init_done) begin
            state <= SHUFFLE;
            init_done_ack <= 1'b1;
          end
        end

        SHUFFLE: begin
          state <= WAIT_FOR_SHUFFLE;
        end

        WAIT_FOR_SHUFFLE: begin
          if (shuffle_done) begin
            state <= COMPLETE;
            shuffle_done_ack <= 1'b1;
          end
        end

        COMPLETE: begin
          if (datapath_done_ack)
            state <= IDLE;
        end
      endcase
    end
  end

  // Output register logic
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      s_mem_addr_reg        <= 8'd0;
      s_mem_data_write_reg  <= 8'd0;
      s_mem_wren_reg        <= 1'b0;
    end else begin
      if (register_for_init_memory) begin
        s_mem_addr_reg       <= mem_addr_init;
        s_mem_data_write_reg <= mem_data_write_init;
        s_mem_wren_reg       <= mem_wren_init;
      end else if (register_for_shuffle) begin
        s_mem_addr_reg       <= mem_addr_shuffle;
        s_mem_data_write_reg <= mem_data_write_shuffle;
        s_mem_wren_reg       <= mem_wren_shuffle;
      end
    end
  end

endmodule
