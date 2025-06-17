
module tb_datapath();

    // Clock and reset
    logic clk;
    logic reset_n;
    
    // Control signals
    logic datapath_start;
    logic datapath_done_ack;
    logic stop;
    logic datapath_done;
    
    // Key related signals
    logic [23:0] secret_key;
    logic [23:0] secret_key_start_value = 24'h0;
    logic [23:0] secret_key_end_value = 24'h3;
    logic secret_key_found_flag;
    
    // Memory interfaces (simplified for state testing)
    logic [7:0] s_mem_data_read = 8'h00;
    logic [7:0] d_mem_data_read = 8'h00;
    logic [7:0] e_mem_data_read = 8'h00;

    // Instantiate the datapath
    datapath dut (
        .clk(clk),
        .reset_n(reset_n),
        .datapath_start(datapath_start),
        .datapath_done_ack(datapath_done_ack),
        .stop(stop),
        .datapath_done(datapath_done),
        .secret_key(secret_key),
        .secret_key_start_value(secret_key_start_value),
        .secret_key_end_value(secret_key_end_value),
        .secret_key_found_flag(secret_key_found_flag),
        .s_mem_addr(),
        .s_mem_data_write(),
        .s_mem_data_read(s_mem_data_read),
        .s_mem_wren(),
        .d_mem_addr(),
        .d_mem_data_write(),
        .d_mem_wren(),
        .e_mem_addr(),
        .e_mem_data_read(e_mem_data_read)
    );
    
    // Clock generation (100MHz)
    always begin
        clk = 0; #5;
        clk = 1; #5;
    end
    
    // State transition testing
    initial begin
        // Initialize
        reset_n = 0;
        datapath_start = 0;
        datapath_done_ack = 0;
        stop = 0;
        secret_key_found_flag = 0;
        
        // Reset
        #20;
        reset_n = 1;
        #20;

        
        // Start the process
        datapath_start = 1;
        #50;
        datapath_start = 0;
        
        // Monitor state machine progress

            // Monitor key 2 processing (simulate found key)
            begin
                #20;
                #20; force dut.memory_init_inst.init_done = 1; #10; release dut.memory_init_inst.init_done;
                
                #20;
                #20; force dut.ksa_shuffle_inst.done = 1; #10; release dut.ksa_shuffle_inst.done;
                
                #20;
                #20; force dut.message_decryption_inst.done = 1; #10; release dut.message_decryption_inst.done;

                #20;
                #20; force dut.memory_init_inst.init_done = 1; #10; release dut.memory_init_inst.init_done;
                
                #20;
                #20; force dut.ksa_shuffle_inst.done = 1; #10; release dut.ksa_shuffle_inst.done;
                
                #20;
                force dut.secret_key_found_flag = 1;
                #20; force dut.message_decryption_inst.done = 1; #10; release dut.message_decryption_inst.done;

                
            end
            
            begin
                datapath_done_ack = 1;
                #20;
                datapath_done_ack = 0;
                
                #100;
                $display("=== Test Complete ===");
                $stop;
            end
    end
    
    // State and key monitor
    always @(posedge clk) begin
        if (dut.state != dut.IDLE) begin
            $display("[%0t] State: %s, Key: %h, Found: %b", 
                    $time, dut.state, secret_key, secret_key_found_flag);
        end
    end
    
endmodule