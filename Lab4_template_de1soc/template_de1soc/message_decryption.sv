// Task 2b

//  i = 0, j=0
//  for k = 0 to message_length-1 { // message_length is 32 in our implementation
//  i = i+1
//  j = j+s[i]
//  swap values of s[i] and s[j]
//  f = s[ (s[i]+s[j]) ]
//  decrypted_output[k] = f xor encrypted_input[k] // 8 bit wide XOR function
//  }

module message_decryption (
    input  logic        clk,
    input  logic        reset_n,

    input  logic        start_decryption,
    output logic        finish_decryption,

    // s_memory
    output logic [7:0]  s_mem_addr,
    input  logic [7:0]  s_mem_data_read,
    output logic [7:0]  s_mem_data_write, 
    output logic        s_mem_wren,

    // encryption ROM
    output logic [4:0]  encrypted_input_mem_addr,
    input  logic [7:0]  encrypted_input,

    // decryption RAM
    output logic [4:0]  decrypted_output_mem_addr,
    output logic [7:0]  decrypted_output,
    output logic        decrypted_output_wren
);

    parameter MESSAGE_LENGTH = 32;

    logic [7:0] i, j, f, s_i, s_j;
    logic [4:0] k;

    logic [7:0] temp_swap_reg; // Stores temporary values while swapping s_i and s_j

    logic [7:0] encryption_data;
    logic [7:0] decryption_data;

    typedef enum logic [3:0] {
        IDLE, INCREMENT_I, READ_S_I, INCREMENT_J, READ_S_J,
        WRITE_S_I_TO_S_J, WRITE_S_J_TO_S_I, // Separated swap into 2 cycles to prevent glitches
        COMPUTE_F, READ_ENCRYPTED_INPUT, WRITE_DECRYPTED_OUTPUT, DONE
    } decryption_states; 

    decryption_states state;

    // FSM for decryption loop
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
        state     <= IDLE;
        i         <= 8'd0;
        j         <= 8'd0;
        k         <= 5'd0;
        f         <= 8'd0;
        s_i       <= 8'd0;
        s_j       <= 8'd0;
        end else begin
            case(state)
                IDLE                    : begin
                    if (start_decryption) begin
                        state   <= INCREMENT_I;
                        i       <= 8'd0;
                        j       <= 8'd0;
                        k       <= 5'd0;
                    end
                end

                //  i = i+1
                INCREMENT_I             : begin
                    state   <= READ_S_I;
                    i       <= i + 1;
                end
                
                READ_S_I                : begin
                    state   <= INCREMENT_J;
                    s_i     <= s_mem_data_read;
                end
                
                //  j = j+s[i]
                INCREMENT_J             : begin
                    state   <= READ_S_J;
                    j       <= j + s_i; 
                end
                
                // swap values of s[i] and s[j]
                READ_S_J                : begin
                    state   <= WRITE_S_I_TO_S_J;
                    s_j     <= s_mem_data_read;
                end
                
                WRITE_S_I_TO_S_J        : begin
                    state           <= WRITE_S_J_TO_S_I;
                    temp_swap_reg   <= s_j;
                    s_j             <= s_i;
                end
                
                WRITE_S_J_TO_S_I        : begin
                    state   <= COMPUTE_F;
                    s_i     <= temp_swap_reg;
                end
                
                // f = s[ (s[i]+s[j]) ]
                COMPUTE_F               : begin
                    state   <= READ_ENCRYPTED_INPUT;
                    f       <= s_mem_data_read;
                end
                
                READ_ENCRYPTED_INPUT    : begin
                    state           <= WRITE_DECRYPTED_OUTPUT;
                    encryption_data <= encrypted_input;
                end

                // decrypted_output[k] = f xor encrypted_input[k] 
                WRITE_DECRYPTED_OUTPUT  : begin
                    decryption_data <= f ^ encryption_data;

                    // if k == MESSAGE_LENGTH - 1, loop one more time
                    if (k < MESSAGE_LENGTH - 1) begin
                        state <= INCREMENT_I;
                        k     <= k + 1;
                    end else begin
                        state <= DONE;
                    end
                end

                DONE                    : begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // Memory reading combinational logic
    always_comb begin
        s_mem_addr                  = 8'd0;
        s_mem_data_write            = 8'd0;
        s_mem_wren                  = 1'b0;
        encrypted_input_mem_addr    = 5'd0;
        decrypted_output_mem_addr   = 5'd0;
        decrypted_output_wren       = 1'b0;
        finish_decryption           = 1'b0;

        case(state)
            IDLE                    : begin
                // do nothing
            end

            INCREMENT_I             : begin
                // do nothing
            end
            
            READ_S_I                : begin
                s_mem_addr = i;
            end
            
            INCREMENT_J             : begin
                // do nothing
            end
            
            READ_S_J                : begin
                s_mem_addr = j;
            end
            
            WRITE_S_I_TO_S_J        : begin
                s_mem_addr        = j;
                s_mem_data_write  = s_i;
                s_mem_wren        = 1'b1;
            end
            
            WRITE_S_J_TO_S_I        : begin
                s_mem_addr        = i;
                s_mem_data_write  = temp_swap_reg;
                s_mem_wren        = 1'b1;
            end
            
            COMPUTE_F               : begin
                s_mem_addr = s_i + s_j;
            end

            READ_ENCRYPTED_INPUT    : begin
                encrypted_input_mem_addr = k;
            end

            WRITE_DECRYPTED_OUTPUT  : begin
                decrypted_output_mem_addr   = k;
                decrypted_output_wren       = 1'b1;
            end

            DONE                    : begin
                finish_decryption = 1'b1;
            end
        endcase
    end

    assign decrypted_output = decryption_data;

endmodule