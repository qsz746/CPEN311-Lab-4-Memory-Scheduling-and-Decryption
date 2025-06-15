module ksa_shuffle (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic        done_ack,           // Handshake acknowledgment
  input  logic [9:0]  input_key,
  output logic [7:0]  mem_addr,
  input  logic [7:0]  mem_data_read,      // Data READ FROM memory
  output logic [7:0]  mem_data_write,     // Data TO WRITE TO memory 
  output logic        mem_wren,
  output logic        done
);

  localparam KEY_LENGTH = 3;
  logic [7:0] secret_key [0:KEY_LENGTH-1];

  always_comb begin
    secret_key[0] = 8'h00;
    secret_key[1] = {6'b0, input_key[9:8]};
    secret_key[2] = input_key[7:0];
  end

  typedef enum logic [4:0] {
    IDLE,
    SET_ADDR_S_I,
    WAIT_READ_S_I_1,
    WAIT_READ_S_I_2,
    READ_S_I,
    READ_KEY_BYTE,
    COMPUTE_J,
    SET_ADDR_S_J,
    WAIT_READ_S_J_1,
    WAIT_READ_S_J_2,
    READ_S_J,
    SWAP_WRITE_J_TO_I,
    WAIT_SWAP_J_TO_I,
    SWAP_WRITE_I_TO_J,
    WAIT_SWAP_I_TO_J,
    FINAL_WAIT,
    DONE
  } state_t;
  
  state_t state;

  logic [7:0] i, j, s_i, s_j, key_byte;

  // Registered outputs
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state          <= IDLE;
      i              <= 8'd0;
      j              <= 8'd0;
      s_i            <= 8'd0;
      s_j            <= 8'd0;
      key_byte       <= 8'd0;
      mem_addr       <= 8'd0;
      mem_data_write <= 8'd0;
      mem_wren       <= 1'b0;
      done           <= 1'b0;
    end else begin
      // Default outputs
      mem_wren <= 1'b0;
      done     <= 1'b0;
      
      case (state)
        IDLE: begin
          if (start) begin
            state <= SET_ADDR_S_I;
            i     <= 8'd0;
            j     <= 8'd0;
          end
        end

        SET_ADDR_S_I: begin
          mem_addr <= i;
          state    <= WAIT_READ_S_I_1;
        end

        WAIT_READ_S_I_1: begin
          state <= WAIT_READ_S_I_2;
        end

        WAIT_READ_S_I_2: begin
          state <= READ_S_I;
        end

        READ_S_I: begin
          s_i   <= mem_data_read;
          state <= READ_KEY_BYTE;
        end

        READ_KEY_BYTE: begin
          case (i % KEY_LENGTH)
            0: key_byte <= secret_key[0];
            1: key_byte <= secret_key[1];
            2: key_byte <= secret_key[2];
            default: key_byte <= 8'd0;
          endcase
          state <= COMPUTE_J;
        end

        COMPUTE_J: begin
          j     <= j + s_i + key_byte;
          state <= SET_ADDR_S_J;
        end

        SET_ADDR_S_J: begin
          mem_addr <= j;
          state    <= WAIT_READ_S_J_1;
        end

        WAIT_READ_S_J_1: begin
          state <= WAIT_READ_S_J_2;
        end

        WAIT_READ_S_J_2: begin
          state <= READ_S_J;
        end

        READ_S_J: begin
          s_j   <= mem_data_read;
          state <= SWAP_WRITE_J_TO_I;
        end

        SWAP_WRITE_J_TO_I: begin
          mem_addr       <= i;
          mem_data_write <= s_j;
          mem_wren       <= 1'b1;
          state          <= WAIT_SWAP_J_TO_I;
        end

        WAIT_SWAP_J_TO_I: begin
          state <= SWAP_WRITE_I_TO_J;
        end

        SWAP_WRITE_I_TO_J: begin
          mem_addr       <= j;
          mem_data_write <= s_i;
          mem_wren       <= 1'b1;
          if (i == 8'd255) begin
            state <= FINAL_WAIT;
          end else begin
            i     <= i + 1;
            state <= SET_ADDR_S_I;
          end
        end

        WAIT_SWAP_I_TO_J: begin
          state <= FINAL_WAIT;
        end

        FINAL_WAIT: begin
          state <= DONE;
        end

        DONE: begin
          done <= 1'b1;
          if (done_ack) begin
            state <= IDLE;
          end
        end
      endcase
    end
  end

endmodule