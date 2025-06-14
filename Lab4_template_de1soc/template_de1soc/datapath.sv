module datapath (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        datapath_start,
  input  logic [9:0]  input_key,
  input  logic        datapath_done_ack,    // Handshake acknowledgment
  output logic        datapath_done,
  
  // S Memory interface
  output logic [7:0]  s_mem_addr,
  output logic [7:0]  s_mem_data_write,
  input  logic [7:0]  s_mem_data_read,
  output logic        s_mem_wren,


  // D Memory interface
  output logic [4:0]  d_mem_addr,
  output logic [7:0]  d_mem_data_write,
  input  logic [7:0]  d_mem_data_read,
  output logic        d_mem_wren,
  

  // E Memory interface
  output logic [4:0]  e_mem_addr,
  input logic         e_mem_data_read
  );
 
  logic [10:0] state;
  // FSM State definition
  // state[10:7] = additional bits to make state unique
  // state[6] = register_for_decryption
  // state[5] = register_for_shuffle
  // state[4] = register_for_init_memory
 
  // state[3] = decryption_start
  // state[2] = shuffle_start
  // state[1] = init_start
  // state[0] = datapath_done

  parameter [10:0] IDLE                 = 9'b0000_000_000_0;
  parameter [10:0] INIT_MEMORY          = 9'b0001_001_001_0;  // init_start = 1, register_for_init_memory = 1
  parameter [10:0] WAIT_FOR_INIT_MEMORY = 9'b0010_001_000_0;  // register_for_init_memory = 1

  parameter [10:0] SHUFFLE              = 9'b0011_010_010_0;  // shuffle_start = 1,  register_for_shuffle = 1
  parameter [10:0] WAIT_FOR_SHUFFLE     = 9'b0100_010_000_0;  // register_for_shuffle = 1
  
  parameter [10:0] DECRYPTION           = 9'b0101_100_100_0;  // decryption_start = 1,  register_for_decryption = 1
  parameter [10:0] WAIT_FOR_DECRYPTION  = 9'b0110_100_000_0;  // register_for_decryption = 1
 
  parameter [10:0] COMPLETE             = 9'b0111_000_000_1;

  // Internal control wires
  logic init_start;
  logic shuffle_start;
  logic decryption_start;
  
  logic init_done;
  logic shuffle_done;
  logic shuffle_done_ack;  // Handshake acknowledgment
  logic init_done_ack;     // Handshake acknowledgment
  logic decryption_done;
  logic decryption_done_ack;

  assign register_for_decryption  = state[6];
  assign register_for_shuffle     = state[5];
  assign register_for_init_memory = state[4];
  assign decryption_start 		    = state[3];
  assign shuffle_start            = state[2];
  assign init_start               = state[1];
  assign datapath_done            = state[0];

  logic [7:0] s_mem_addr_init;
  logic [7:0] s_mem_data_write_init;
  logic       s_mem_wren_init;

  logic [7:0] s_mem_addr_shuffle;
  logic [7:0] s_mem_data_write_shuffle;
  logic       s_mem_wren_shuffle;
  
  logic [7:0] s_mem_addr_decryption;
  logic [7:0] s_mem_data_write_decryption;
  logic       s_mem_wren_decryption;

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
    .mem_addr   (s_mem_addr_init),
    .mem_data   (s_mem_data_write_init),
    .mem_wren   (s_mem_wren_init),
    .init_done  (init_done),
    .done_ack   (init_done_ack)
  );

  // Instantiate KSA shuffle module
  ksa_shuffle ksa_shuffle_inst (
    .clk            (clk),
    .reset_n        (reset_n),
    .start          (shuffle_start),   
    .input_key      (input_key),
    .mem_addr       (s_mem_addr_shuffle),
    .mem_data_read  (s_mem_data_read),
    .mem_data_write (s_mem_data_write_shuffle),
    .mem_wren       (s_mem_wren_shuffle),
    .done           (shuffle_done),
    .done_ack       (shuffle_done_ack)
  );


//Instantiate message_decryption
    message_decryption message_decryption_inst (
      .clk            (clk),                     
      .reset_n        (reset_n),                 
      .start          (decrypt_start),            
      .done_ack       (decrypt_done_ack),        
      .s_mem_addr     (s_mem_addr_decryption),  // S Memory interface        
      .s_mem_data_read(s_mem_data_read),    
      .s_mem_data_write(s_mem_data_write_decryption),
      .s_mem_wren     (s_mem_wren_decryption),
      .d_mem_data_write(d_mem_data_write),    // D Memory interface  			
      .d_mem_addr     (d_mem_addr),              
      .d_mem_wren     (d_mem_wren), 
		  .e_mem_addr     (e_mem_addr),  	    // E Memory interface  	
		  .e_mem_data_read(e_mem_data_read), 		
      .done           (decrypt_done)             
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

        DECRYPTION: begin
          state <= WAIT_FOR_DECRYPTION;
        end

        WAIT_FOR_DECRYPTION: begin
          if (decryption_done) begin
            state <= COMPLETE;
            decryption_done_ack <= 1'b1;
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
        s_mem_addr_reg       <= s_mem_addr_init;
        s_mem_data_write_reg <= s_mem_data_write_init;
        s_mem_wren_reg       <= s_mem_wren_init;
      end else if (register_for_shuffle) begin
        s_mem_addr_reg       <= s_mem_addr_shuffle;
        s_mem_data_write_reg <= s_mem_data_write_shuffle;
        s_mem_wren_reg       <= s_mem_wren_shuffle;
      end else if (register_for_decryption) begin
		  s_mem_addr_reg       <= s_mem_addr_decryption;
        s_mem_data_write_reg <= s_mem_data_write_decryption;
        s_mem_wren_reg       <= s_mem_wren_decryption;
		end
    end
  end

endmodule
