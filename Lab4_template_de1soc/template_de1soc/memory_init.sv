module memory_init (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
	 input  logic        done_ack,     // New: Handshake acknowledgment
    output logic [7:0]  mem_addr,
    output logic [7:0]  mem_data,
    output logic        mem_wren,     
    output logic        init_done   
);

    // State Encoding (One-Hot with Embedded Outputs)
    // state[4:3]  additional bits for making states unique
    // state[2] = placeholder, always 0, for future 
    // state[1] = mem_wren  (1 when INIT)
    // state[0] = init_done (1 when DONE)
    parameter [4:0] IDLE  = 5'b00_0_00;
    parameter [4:0] INIT  = 5'b01_0_10;  // mem_wren=1
	 parameter [4:0] WAIT  = 5'b10_0_10;  // mem_wren=1
    parameter [4:0] DONE  = 5'b11_0_01;  // init_done=1

    logic [4:0] state;
    logic [7:0] counter;  // 8-bit counter (0 to 255)


    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state   <= IDLE;
            counter <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state   <= INIT;
                        counter <= 8'd0;  // Reset counter on start
                    end
                end

                INIT: begin
                    counter <= counter + 1;
                        if (counter == 8'd255) begin
                            state <= WAIT; // Move to DONE next cycle, after writing 255
                        end
                end

                WAIT: begin
                    state <= DONE;    // Now safe to assert init_done
                end

                DONE: begin
					     if (done_ack) begin
                       state <= IDLE;  // Return to IDLE after one cycle
						  end
                end

                default: begin
							state <= IDLE;
		          end
            endcase
        end
    end
 
    assign init_done = state[0];
    assign mem_wren = state[1]; 
 

    // Address/Data Logic
    assign mem_addr = counter;
    assign mem_data = counter;

endmodule