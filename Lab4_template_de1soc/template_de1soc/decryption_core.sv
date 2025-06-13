module decryption_core (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic [9:0]  input_key,
  output logic        done
);

  // Internal memory interface signals
  logic [7:0]  s_mem_addr;
  logic [7:0]  s_mem_data_write;
  logic [7:0]  s_mem_data_read;
  logic        s_mem_wren;
  logic datapath_done_ack;  // Handshake acknowledgment
  logic datapath_done;  // Handshake acknowledgment 
 

  logic [2:0] state;
  parameter [2:0] IDLE        = 3'b00_00;  // 
  parameter [2:0] WORKING     = 3'b01_10;  //  datapath_start = 1
  parameter [2:0] DONE        = 3'b10_01;  // core_done =1 

  assign datapath_start = state[1];
  assign done = state[0];

  // FSM
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state               <= IDLE;
      datapath_done_ack   <= 1'b0;
    
    end else begin
      // Default signals
      datapath_done_ack <= 1'b0;
      

      case (state)
        IDLE: begin
          if (start) begin
            state <= WORKING;
          end
        end

        WORKING: begin
          if (datapath_done) begin
            datapath_done_ack <= 1'b1; // 1-cycle pulse
            state <= DONE;
          end
        end

        DONE: begin
        end
      endcase
    end
  end
 
  // Instantiate datapath
  datapath datapath_inst (
    .clk                   (clk),
    .reset_n               (reset_n),
    .datapath_start        (datapath_start),
    .input_key             (input_key),
    .datapath_done         (datapath_done),
    .datapath_done_ack     (datapath_done_ack),
    // Memory interface
    .s_mem_addr     (s_mem_addr),
    .s_mem_data_write  (s_mem_data_write),
    .s_mem_data_read (s_mem_data_read),
    .s_mem_wren     (s_mem_wren)
  );

  // Instantiate S-memory  
  s_memory memory_inst (
    .clock      (clk),
    .address    (s_mem_addr),
    .data       (s_mem_data_write),
    .q          (s_mem_data_read),
    .wren       (s_mem_wren)
  );

endmodule