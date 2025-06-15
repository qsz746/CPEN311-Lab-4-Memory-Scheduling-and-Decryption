module message_decryption (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic        done_ack,
  
  // Memory interfaces
  output logic [7:0]  s_mem_addr,
  input  logic [7:0]  s_mem_data_read,
  output logic [7:0]  s_mem_data_write,
  output logic        s_mem_wren,
  
  output logic [7:0]  d_mem_data_write,
  output logic [4:0]  d_mem_addr,
  output logic        d_mem_wren,
  
  input  logic [7:0]  e_mem_data_read,
  output logic [4:0]  e_mem_addr,
  output logic        done,
  output logic        secret_key_found_flag
);

  localparam MESSAGE_LENGTH = 32;
  
  typedef enum logic [4:0] {
    IDLE,
    INC_I,
    SET_ADDR_S_I,
    WAIT_READ_S_I_1,  // Added wait state for read
    WAIT_READ_S_I_2,  // Added wait state for read
    READ_S_I,
    COMPUTE_J,
    SET_ADDR_S_J,
    WAIT_READ_S_J_1,  // Added wait state for read
    WAIT_READ_S_J_2,  // Added wait state for read
    READ_S_J,
    SWAP_WRITE_J_TO_I,
    WAIT_FOR_SWAP_WRITE_J_TO_I_1,  // Added wait state for write
    WAIT_FOR_SWAP_WRITE_J_TO_I_2,  // Added wait state for write
    SWAP_WRITE_I_TO_J,
    WAIT_FOR_SWAP_WRITE_I_TO_J_1,  // Added wait state for write
    WAIT_FOR_SWAP_WRITE_I_TO_J_2,  // Added wait state for write
    COMPUTE_F_ADDR,
    SET_ADDRS_F_E,
    WAIT_READ_F_E_1,  // Added wait state for read
    WAIT_READ_F_E_2,  // Added wait state for read
    READ_F_E,
    WRITE_OUTPUT,
    DONE
  } state_t;
  
  state_t state;

  // Registers
  logic [7:0] i, j, s_i, s_j, f;
  logic [4:0] k;
  logic [7:0] encrypted_byte;
  

  // Registered outputs
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      i <= 8'd0;
      j <= 8'd0;
      k <= 5'd0;
      s_i <= 8'd0;
      s_j <= 8'd0;
      f <= 8'd0;
      encrypted_byte <= 8'd0;
      
      // Reset all outputs
      s_mem_addr <= 8'd0;
      s_mem_data_write <= 8'd0;
      s_mem_wren <= 1'b0;
      d_mem_addr <= 5'd0;
      d_mem_data_write <= 8'd0;
      d_mem_wren <= 1'b0;
      e_mem_addr <= 5'd0;
      done <= 1'b0;
      secret_key_found_flag <= 1'b0;
    end else begin
      // Default outputs
      s_mem_wren <= 1'b0;
      d_mem_wren <= 1'b0;
      done <= 1'b0;
      
      case (state)
        IDLE: begin
          if (start) begin
            state <= INC_I;
            i <= 8'd0;
            j <= 8'd0;
            k <= 5'd0;
            secret_key_found_flag <= 1'b0;
          end
        end
        
        INC_I: begin
          i <= i + 1;
          state <= SET_ADDR_S_I;
        end
        
        SET_ADDR_S_I: begin
          s_mem_addr <= i;
          state <= WAIT_READ_S_I_1;
        end
        
        WAIT_READ_S_I_1: begin
          state <= WAIT_READ_S_I_2;
        end
        
        WAIT_READ_S_I_2: begin
          state <= READ_S_I;
        end
        
        READ_S_I: begin
          s_i <= s_mem_data_read;
          state <= COMPUTE_J;
        end
        
        COMPUTE_J: begin
          j <= j + s_i;
          state <= SET_ADDR_S_J;
        end
        
        SET_ADDR_S_J: begin
          s_mem_addr <= j;
          state <= WAIT_READ_S_J_1;
        end
        
        WAIT_READ_S_J_1: begin
          state <= WAIT_READ_S_J_2;
        end
        
        WAIT_READ_S_J_2: begin
          state <= READ_S_J;
        end
        
        READ_S_J: begin
          s_j <= s_mem_data_read;
          state <= SWAP_WRITE_J_TO_I;
        end
        
        SWAP_WRITE_J_TO_I: begin
          s_mem_addr <= i;
          s_mem_data_write <= s_j;
          s_mem_wren <= 1'b1;
          state <= WAIT_FOR_SWAP_WRITE_J_TO_I_1;
        end
        
        WAIT_FOR_SWAP_WRITE_J_TO_I_1: begin
          state <= WAIT_FOR_SWAP_WRITE_J_TO_I_2;
        end
        
        WAIT_FOR_SWAP_WRITE_J_TO_I_2: begin
          state <= SWAP_WRITE_I_TO_J;
        end
        
        SWAP_WRITE_I_TO_J: begin
          s_mem_addr <= j;
          s_mem_data_write <= s_i;
          s_mem_wren <= 1'b1;
          state <= WAIT_FOR_SWAP_WRITE_I_TO_J_1;
        end
        
        WAIT_FOR_SWAP_WRITE_I_TO_J_1: begin
          state <= WAIT_FOR_SWAP_WRITE_I_TO_J_2;
        end
        
        WAIT_FOR_SWAP_WRITE_I_TO_J_2: begin
          state <= COMPUTE_F_ADDR;
        end
        
        COMPUTE_F_ADDR: begin
          state <= SET_ADDRS_F_E;
        end
        
        SET_ADDRS_F_E: begin
          s_mem_addr <= s_i + s_j;
          e_mem_addr <= k;
          state <= WAIT_READ_F_E_1;
        end
        
        WAIT_READ_F_E_1: begin
          state <= WAIT_READ_F_E_2;
        end
        
        WAIT_READ_F_E_2: begin
          state <= READ_F_E;
        end
        
        READ_F_E: begin
          f <= s_mem_data_read;
          encrypted_byte <= e_mem_data_read;
          state <= WRITE_OUTPUT;
        end

        WRITE_OUTPUT: begin
            d_mem_addr <= k;
            d_mem_data_write <= f ^ encrypted_byte;
            d_mem_wren <= 1'b1;

            // Check if decrypted char is valid
            if (((f ^ encrypted_byte) >= 8'd97 && (f ^ encrypted_byte) <= 8'd122) || (f ^ encrypted_byte) == 8'd32) begin
                if (k == MESSAGE_LENGTH - 1) begin
                    // All characters valid, set flag
                    secret_key_found_flag <= 1'b1;
                    state <= DONE;
                end
                else begin
                    k <= k + 1;
                    state <= INC_I;
                end
            end
            else begin
                // Invalid character, abort this key
                state <= DONE;
            end
        end


        
        DONE: begin   // If secret_key_found_flag=1, stay here forever
          done <= 1'b1;
          if (!secret_key_found_flag && done_ack) begin  
            state <= IDLE;
			 end
        end
      endcase
    end
  end
endmodule