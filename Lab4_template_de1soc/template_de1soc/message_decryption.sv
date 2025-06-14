// compute one byte per character in the encrypted message. You will build this in Task 2
// i = 0, j=0
// for k = 0 to message_length-1 { // message_length is 32 in our implementation
// i = i+1
// j = j+s[i]
// swap values of s[i] and s[j]
// f = s[ (s[i]+s[j]) ]
// decrypted_output[k] = f xor encrypted_input[k] // 8 bit wide XOR function
// }

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
  output logic [4:0]  d_mem_addr,         // Address for decrypted memory
  output logic        d_mem_wren,         // Write enable for decrypted memory
  
  input  logic [7:0]  e_mem_data_read,    // Encrypted input from memory
  output logic [4:0]  e_mem_addr,         // Address for encrypted memory
  output logic        done
);

  localparam MESSAGE_LENGTH = 32;
  
  logic [7:0] state;
  // FSM State definition
  // state[7:3] = additional bits to make state unique
  // state[2]   = d_mem_wren
  // state[1]   = s_mem_wren  
  // state[0]   = done
  parameter [7:0] IDLE               = 7'b00000_000;
  parameter [7:0] INC_I              = 7'b00001_000;
  parameter [7:0] SET_ADDR_S_I       = 7'b00010_000;
  parameter [7:0] WAIT_READ_S_I      = 7'b00011_000;
  parameter [7:0] READ_S_I           = 7'b00100_000;
  parameter [7:0] COMPUTE_J          = 7'b00101_000;
  parameter [7:0] SET_ADDR_S_J       = 7'b00110_000;
  parameter [7:0] WAIT_READ_S_J      = 7'b00111_000;
  parameter [7:0] READ_S_J           = 7'b01000_000;
  parameter [7:0] SWAP_WRITE_J_TO_I  = 7'b01001_010;
  parameter [7:0] SWAP_WRITE_I_TO_J  = 7'b01010_010;
  parameter [7:0] COMPUTE_F          = 7'b01011_000;
  parameter [7:0] SET_ADDR_F         = 7'b01100_000;
  parameter [7:0] WAIT_READ_F        = 7'b01101_000;
  parameter [7:0] READ_F             = 7'b01110_000;
  parameter [7:0] WRITE_DECRYPTED    = 7'b01111_100;  
  parameter [7:0] FINAL_WAIT         = 7'b10000_000;  
  parameter [7:0] DONE               = 7'b10001_001;


  assign done      = state[0];
  assign s_mem_wren = state[1];
  assign d_mem_wren = state[2];  

  logic [7:0] i, j, s_i, s_j, f;
  logic [4:0] k;  
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
      k              <= 5'd0;
      encrypted_byte <= 8'd0;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= INC_I;
            i     <= 8'd0;
            j     <= 8'd0;
            k     <= 5'd0;
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
            state <= FINAL_WAIT;
          end else begin
            k <= k + 1;
            state <= INC_I;
          end
        end

        FINAL_WAIT: begin
          state <= DONE;  // Ensure final write completes
        end

        DONE: begin
          if (done_ack) begin
            state <= IDLE;
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
    e_mem_addr = 5'd0;
    d_mem_addr = 5'd0;
    s_mem_data_write = 8'd0;
    d_mem_data_write = 8'd0;

    case (state)
      SET_ADDR_S_I,
      WAIT_READ_S_I: begin
        s_mem_addr = i;
      end

      SET_ADDR_S_J,
      WAIT_READ_S_J: begin
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
      WAIT_READ_F: begin
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