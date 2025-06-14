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

  logic [6:0] state;
  // FSM State definition
  // state[6:3] = additional bits to make state unique
  // state[2]   = placeholder
  // state[1]   = mem_wren
  // state[0]   = done
  parameter [6:0] IDLE               = 7'b0000_000;   
  parameter [6:0] SET_ADDR_S_I       = 7'b0001_000;   
  parameter [6:0] WAIT_READ_S_I      = 7'b0010_000;  
  parameter [6:0] READ_S_I           = 7'b0011_000;   
  parameter [6:0] READ_KEY_BYTE      = 7'b0100_000;   
  parameter [6:0] COMPUTE_J          = 7'b0101_000;   
  parameter [6:0] SET_ADDR_S_J       = 7'b0110_000;  
  parameter [6:0] WAIT_READ_S_J      = 7'b0111_000;  
  parameter [6:0] READ_S_J           = 7'b1000_000;  
  parameter [6:0] SWAP_WRITE_J_TO_I  = 7'b1001_010;  
  parameter [6:0] SWAP_WRITE_I_TO_J  = 7'b1010_010;  
  parameter [6:0] FINAL_WAIT         = 7'b1011_000;  
  parameter [6:0] DONE               = 7'b1110_001;

  assign done     = state[0];
  assign mem_wren = state[1];

  logic [7:0] i, j, s_i, s_j, key_byte;

  // State machine
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state     <= IDLE;
      i         <= 8'd0;
      j         <= 8'd0;
      s_i       <= 8'd0;
      s_j       <= 8'd0;
      key_byte  <= 8'd0;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= SET_ADDR_S_I;
            i     <= 8'd0;
            j     <= 8'd0;
          end
        end

        SET_ADDR_S_I: begin
          state <= WAIT_READ_S_I;  
        end

        WAIT_READ_S_I: begin
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
          j     <= (j + s_i + key_byte);  
          state <= SET_ADDR_S_J;
        end

        SET_ADDR_S_J: begin
          state <= WAIT_READ_S_J;
        end

        WAIT_READ_S_J: begin
          state <= READ_S_J;
        end

        READ_S_J: begin
          s_j   <= mem_data_read;
          state <= SWAP_WRITE_J_TO_I;   
        end

        SWAP_WRITE_J_TO_I: begin
          state <= SWAP_WRITE_I_TO_J;
        end

        SWAP_WRITE_I_TO_J: begin  
          if (i == 8'd255) begin
            state <= FINAL_WAIT;
          end else begin
            i     <= i + 1;
            state <= SET_ADDR_S_I;
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
    mem_addr       = 8'd0;
    mem_data_write = 8'd0;

    case (state)
      SET_ADDR_S_I,
      WAIT_READ_S_I: begin
        mem_addr = i;
      end

      SET_ADDR_S_J,
      WAIT_READ_S_J: begin
        mem_addr = j;
      end

      SWAP_WRITE_J_TO_I: begin
        mem_addr       = i;
        mem_data_write = s_j;
      end

      SWAP_WRITE_I_TO_J: begin
        mem_addr       = j;
        mem_data_write = s_i;
      end

      default: ;  // No action for other states
    endcase
  end

endmodule