module ksa_shuffle (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic [9:0]  input_key,
  output logic [7:0]  mem_addr,
  input  logic [7:0]  mem_data_read,   // Data READ FROM memory
  output logic [7:0]  mem_data_write,  // Data TO WRITE TO memory 
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

  typedef enum logic [2:0] {
    IDLE, READ_S_I, READ_KEY_BYTE, COMPUTE_J, READ_S_J,
    SWAP_WRITE_J_TO_I, SWAP_WRITE_I_TO_J, DONE
  } state_t;

  state_t state;
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
            state <= READ_S_I;
            i     <= 8'd0;
            j     <= 8'd0;
          end
        end

        READ_S_I: begin
          s_i   <= mem_data_read;
          state <= READ_KEY_BYTE;
        end

        READ_KEY_BYTE: begin
          key_byte <= secret_key[i % KEY_LENGTH];
          state    <= COMPUTE_J;
        end

        COMPUTE_J: begin
          j     <= j + s_i + key_byte;
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
          if (i < 8'd255) begin
            i     <= i + 1;
            state <= READ_S_I;
          end else begin
            state <= DONE;
          end
        end

        DONE: begin
          state <= IDLE;
        end
      endcase
    end
  end

  // Output logic
  always_comb begin
    mem_addr       = 8'd0;
    mem_data_write = 8'd0;
    mem_wren       = 1'b0;
    done           = 1'b0;

    case (state)
      READ_S_I: begin
        mem_addr = i;
      end

      READ_S_J: begin
        mem_addr = j;
      end

      SWAP_WRITE_J_TO_I: begin
        mem_addr       = i;
        mem_data_write = s_j;
        mem_wren       = 1'b1;
      end

      SWAP_WRITE_I_TO_J: begin
        mem_addr       = j;
        mem_data_write = s_i;
        mem_wren       = 1'b1;
      end

      DONE: begin
        done = 1'b1;
      end

      default: ;  // No action
    endcase
  end

endmodule
