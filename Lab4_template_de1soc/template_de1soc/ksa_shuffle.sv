module ksa_shuffle (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        start,
  input  logic        done_ack,           // Handshake acknowledgment
  input  logic [23:0] secret_key,
  output logic [7:0]  mem_addr,
  input  logic [7:0]  mem_data_read,      // Data READ FROM memory
  output logic [7:0]  mem_data_write,     // Data TO WRITE TO memory 
  output logic        mem_wren,
  output logic        done
);

  localparam KEY_LENGTH = 3;
 

 

	parameter [4:0] IDLE                  = 5'b00000;
	parameter [4:0] SET_ADDR_S_I          = 5'b00001;
	parameter [4:0] WAIT_READ_S_I_1       = 5'b00010;
	parameter [4:0] WAIT_READ_S_I_2       = 5'b00011;
	parameter [4:0] READ_S_I              = 5'b00100;
	parameter [4:0] READ_KEY_BYTE         = 5'b00101;
	parameter [4:0] COMPUTE_J             = 5'b00110;
	parameter [4:0] SET_ADDR_S_J          = 5'b00111;
	parameter [4:0] WAIT_READ_S_J_1       = 5'b01000;
	parameter [4:0] WAIT_READ_S_J_2       = 5'b01001;
	parameter [4:0] READ_S_J              = 5'b01010;
	parameter [4:0] SWAP_WRITE_J_TO_I     = 5'b01011;
	parameter [4:0] WAIT_SWAP_J_TO_I      = 5'b01100;
	parameter [4:0] SWAP_WRITE_I_TO_J     = 5'b01101;
	parameter [4:0] WAIT_SWAP_I_TO_J      = 5'b01110;
	parameter [4:0] FINAL_WAIT            = 5'b01111;
	parameter [4:0] DONE                  = 5'b10000;

	logic [4:0] state;

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
            0: key_byte <= secret_key[23:16];
            1: key_byte <= secret_key[15:8];
            2: key_byte <= secret_key[7:0];
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

        default: begin
				   state <= IDLE;
		  end
      endcase
    end
  end

endmodule