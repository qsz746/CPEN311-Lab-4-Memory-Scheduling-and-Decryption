module message_decryption (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic        done_ack,           // Handshake acknowledgment

  output logic [7:0]  s_mem_addr,         // Address for S memory
  input  logic [7:0]  s_mem_data_read,    // S-box value from memory
  output logic [7:0]  s_mem_data_write,
  output logic        s_mem_wren,         // Write enable for S memory
  
  output logic [7:0]  d_mem_data_write,   // Decrypted output to memory
  output logic [7:0]  d_mem_addr,         // Address for decrypted memory
  output logic        d_mem_wren,         // Write enable for decrypted memory
  
  input  logic [7:0]  e_mem_data_read,    // Encrypted input from memory
  output logic [7:0]  e_mem_addr,         // Address for encrypted memory
  output logic        done
);

  localparam MESSAGE_LENGTH = 32;
  
  logic [6:0] state;
  // FSM State definition
  // state[6:3] = additional bits to make state unique
  // state[2]   = placeholder
  // state[1]   = mem_wren (for both S and d memory)
  // state[0]   = done
  parameter [6:0] IDLE               = 7'b0000_000;
  parameter [6:0] INC_I              = 7'b0001_000;
  parameter [6:0] SET_ADDR_S_I       = 7'b0010_000;
  parameter [6:0] WAIT_READ_S_I      = 7'b0011_000;
  parameter [6:0] READ_S_I           = 7'b0100_000;
  parameter [6:0] COMPUTE_J          = 7'b0101_000;
  parameter [6:0] SET_ADDR_S_J       = 7'b0110_000;
  parameter [6:0] WAIT_READ_S_J      = 7'b0111_000;
  parameter [6:0] READ_S_J           = 7'b1000_000;
  parameter [6:0] SWAP_WRITE_J_TO_I  = 7'b1001_010;
  parameter [6:0] SWAP_WRITE_I_TO_J  = 7'b1010_010;
  parameter [6:0] COMPUTE_F          = 7'b1011_000;
  parameter [6:0] SET_ADDR_F         = 7'b1100_000;
  parameter [6:0] WAIT_READ_F        = 7'b1101_000;
  parameter [6:0] READ_F             = 7'b1110_000;
  parameter [6:0] WRITE_DECRYPTED    = 7'b1111_001; // Also sets done when last byte

  assign done      = state[0];
  assign s_mem_wren = state[1];
  assign d_mem_wren = state[1]; // Shared write enable for simplicity

  logic [7:0] i, j, s_i, s_j, f;
  logic [7:0] k; // Message byte counter
  logic [7:0] encrypted_byte;

  // State machine
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state          <= IDLE;
      i              <= 8'd0;
      j              <= 8'd0;
      s_i            <= 8'd0;
      s_j            <= 8'd0;
      f              <= 8'd0;
      k              <= 8'd0;
      encrypted_byte <= 8'd0;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= INC_I;
            i     <= 8'd0;
            j     <= 8'd0;
            k     <= 8'd0;
          end
        end

        INC_I: begin
          i <= i + 1;
          state <= SET_ADDR_S_I;
        end

        SET_ADDR_S_I: begin
          state <= WAIT_READ_S_I;
        end

        WAIT_READ_S_I: begin
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
          state <= WAIT_READ_S_J;
        end

        WAIT_READ_S_J: begin
          state <= READ_S_J;
        end

        READ_S_J: begin
          s_j <= s_mem_data_read;
          state <= SWAP_WRITE_J_TO_I;
        end

        SWAP_WRITE_J_TO_I: begin
          state <= SWAP_WRITE_I_TO_J;
        end

        SWAP_WRITE_I_TO_J: begin
          state <= COMPUTE_F;
        end

        COMPUTE_F: begin
          state <= SET_ADDR_F;
        end

        SET_ADDR_F: begin
          state <= WAIT_READ_F;
        end

        WAIT_READ_F: begin
          state <= READ_F;
        end

        READ_F: begin
          f <= s_mem_data_read;
          // Read encrypted byte at the same time
          encrypted_byte <= e_mem_data_read;
          state <= WRITE_DECRYPTED;
        end

        WRITE_DECRYPTED: begin
          if (k == MESSAGE_LENGTH-1) begin
            if (done_ack) begin
              state <= IDLE;
            end
          end else begin
            k <= k + 1;
            state <= INC_I;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  // Output logic
  always_comb begin
    // Default outputs
    s_mem_addr = 8'd0;
    e_mem_addr = 8'd0;
    d_mem_addr = 8'd0;
    s_mem_data_write = 8'd0;
    d_mem_data_write = 8'd0;

    case (state)
      SET_ADDR_S_I,
      WAIT_READ_S_I,
      READ_S_I: begin
        s_mem_addr = i;
      end

      SET_ADDR_S_J,
      WAIT_READ_S_J,
      READ_S_J: begin
        s_mem_addr = j;
      end

      SWAP_WRITE_J_TO_I: begin
        s_mem_addr = i;
        s_mem_data_write = s_j;
      end

      SWAP_WRITE_I_TO_J: begin
        s_mem_addr = j;
        s_mem_data_write = s_i;
      end

      SET_ADDR_F,
      WAIT_READ_F,
      READ_F: begin
        s_mem_addr = s_i + s_j;
      end

      WRITE_DECRYPTED: begin
        e_mem_addr = k;
        d_mem_addr = k;
        d_mem_data_write = f ^ encrypted_byte; // XOR decryption
      end

      default: ; // No action for other states
    endcase
  end

endmodule