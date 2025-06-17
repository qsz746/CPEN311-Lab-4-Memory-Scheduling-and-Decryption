

module tb_memory_init();

    // Inputs
    logic clk;
    logic reset_n;
    logic start;
    logic done_ack;
    
    // Outputs from memory_init
    logic [7:0] mem_addr;
    logic [7:0] mem_data;
    logic mem_wren;
    logic init_done;
    
    // Output from s_memory
    logic [7:0] mem_q;
    
    // Instantiate the memory initialization controller
    memory_init dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .done_ack(done_ack),
        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .mem_wren(mem_wren),
        .init_done(init_done)
    );
    
    // Instantiate the s_memory component
    s_memory memory_inst (
        .address(mem_addr),
        .clock(clk),
        .data(mem_data),
        .wren(mem_wren),
        .q(mem_q)
    );
    
    // Clock generation
    always begin
        clk = 0; #5;
        clk = 1; #5;
    end
    
    // Test procedure
    initial begin
        // Initialize inputs
        reset_n = 0;
        start = 0;
        done_ack = 0;
        
        // Reset the system
        #10;
        reset_n = 1;
        #10;
        
        // Start the initialization
        start = 1;
        #10;
        start = 0;
        
        // Wait for initialization to complete
        wait(init_done == 1);
        $display("Initialization completed at time %0t", $time);
        
        // Acknowledge completion
        #20;
        done_ack = 1;
        #10;
        done_ack = 0;
        
        // Verify the module returns to IDLE
        #20;
        if (init_done == 0) begin
            $display("Module successfully returned to IDLE state");
        end else begin
            $display("Error: Module did not return to IDLE state");
        end
        
        // Check some memory writes and reads
        $display("\nChecking memory contents:");
        for (int i = 0; i < 10; i++) begin
            #10;
            $display("Address %0d: written = %h, read = %h", 
                     mem_addr, mem_data, mem_q);
        end
        
        // Check the last address
        #10;
        $display("Address 255: written = %h, read = %h", 
                 8'd255, mem_q);
        
        // End simulation
        #100;
        $stop;
    end
    
    // Monitor to track state changes
    always @(posedge clk) begin
        $display("Time %0t: state = %b, counter = %d, mem_wren = %b, init_done = %b",
                 $time, dut.state, dut.counter, mem_wren, init_done);
    end
    
endmodule