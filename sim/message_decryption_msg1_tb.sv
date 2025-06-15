//`timescale 1ns/1ps

module tb_message_decryption();

  // Clock and reset
  logic clk;
  logic reset_n;
  
  // Module inputs
  logic start;
  logic done_ack;
  
  // Memory interfaces
  logic [7:0] s_mem_addr;
  logic [7:0] s_mem_data_read;
  logic [7:0] s_mem_data_write;
  logic s_mem_wren;
  
  logic [7:0] d_mem_data_write;
  logic [4:0] d_mem_addr;
  logic d_mem_wren;
  
  logic [7:0] e_mem_data_read;
  logic [4:0] e_mem_addr;
  logic done;

  // Testbench variables
  logic [7:0] s_memory [0:255];  // Model of S memory
  logic [7:0] e_memory [0:31];   // Model of encrypted message memory
  logic [7:0] d_memory [0:31];   // Model of decrypted message memory
  
  // Clock generation
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  // Instantiate DUT
  message_decryption dut (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .done_ack(done_ack),
    .s_mem_addr(s_mem_addr),
    .s_mem_data_read(s_mem_data_read),
    .s_mem_data_write(s_mem_data_write),
    .s_mem_wren(s_mem_wren),
    .d_mem_addr(d_mem_addr),
    .d_mem_data_write(d_mem_data_write),
    .d_mem_wren(d_mem_wren),
    .e_mem_data_read(e_mem_data_read),
    .e_mem_addr(e_mem_addr),
    .done(done)
  );

  // Memory models
  always_comb begin
    // S memory read
    s_mem_data_read = s_memory[s_mem_addr];
    
    // Encrypted message memory read
    e_mem_data_read = e_memory[e_mem_addr];
  end

  // S memory write
  always_ff @(posedge clk) begin
    if (s_mem_wren)
      s_memory[s_mem_addr] <= s_mem_data_write;
  end

  // Decrypted message memory write
  always_ff @(posedge clk) begin
    if (d_mem_wren)
      d_memory[d_mem_addr] <= d_mem_data_write;
  end

  // Test procedure
  initial begin
    // Initialize memories with specific test data
    initialize_memories();
    
    // Reset the system
    reset_n = 0;
    start = 0;
    done_ack = 0;
    #100;
    reset_n = 1;
    #20;
    
    // Start decryption
    $display("[%0t] Starting decryption...", $time);
    start = 1;
    #20;
    start = 0;
    
    // Wait for completion
    wait(done);
    $display("[%0t] Decryption complete", $time);
    
    // Acknowledge completion
    #20;
    done_ack = 1;
    #20;
    done_ack = 0;
    
    // Display results
    display_results();
    
    // End simulation
    #100;
    $display("Simulation complete");
    $stop;
  end

  // Initialize memories with specific test data
  task initialize_memories();
    begin
      // Initialize S-array with provided values
      // Row 1
      s_memory[0] = 8'h3A; s_memory[1] = 8'hA8; s_memory[2] = 8'h4E; s_memory[3] = 8'h08; 
      s_memory[4] = 8'h55; s_memory[5] = 8'hA3; s_memory[6] = 8'hB8; s_memory[7] = 8'h40; 
      s_memory[8] = 8'h93; s_memory[9] = 8'h0C; s_memory[10] = 8'h44; s_memory[11] = 8'h24; 
      s_memory[12] = 8'hA6; s_memory[13] = 8'h89; s_memory[14] = 8'h26; s_memory[15] = 8'hEA; 
      s_memory[16] = 8'h72; s_memory[17] = 8'h66; s_memory[18] = 8'h61; s_memory[19] = 8'h5A;
      
      // Row 2  
      s_memory[20] = 8'hDA; s_memory[21] = 8'hEF; s_memory[22] = 8'hB2; s_memory[23] = 8'h9E; 
      s_memory[24] = 8'h1F; s_memory[25] = 8'h02; s_memory[26] = 8'h15; s_memory[27] = 8'h3D; 
      s_memory[28] = 8'h01; s_memory[29] = 8'h8E; s_memory[30] = 8'hAC; s_memory[31] = 8'hCD; 
      s_memory[32] = 8'h4A; s_memory[33] = 8'h57; s_memory[34] = 8'h7B; s_memory[35] = 8'h9B; 
      s_memory[36] = 8'h2C; s_memory[37] = 8'h32; s_memory[38] = 8'h49; s_memory[39] = 8'hC8;
      
      // Row 3
      s_memory[40] = 8'h79; s_memory[41] = 8'h30; s_memory[42] = 8'h64; s_memory[43] = 8'h11;
      s_memory[44] = 8'hCC; s_memory[45] = 8'h7E; s_memory[46] = 8'h81; s_memory[47] = 8'hCE;
      s_memory[48] = 8'h9D; s_memory[49] = 8'h5C; s_memory[50] = 8'h46; s_memory[51] = 8'hFA;
      s_memory[52] = 8'h65; s_memory[53] = 8'hB1; s_memory[54] = 8'h52; s_memory[55] = 8'h2F;
      s_memory[56] = 8'h74; s_memory[57] = 8'hC4; s_memory[58] = 8'hAB; s_memory[59] = 8'h88;
      
      // Row 4
      s_memory[60] = 8'hC0; s_memory[61] = 8'hFF; s_memory[62] = 8'h86; s_memory[63] = 8'hF4;
      s_memory[64] = 8'h16; s_memory[65] = 8'h91; s_memory[66] = 8'h3F; s_memory[67] = 8'h0B;
      s_memory[68] = 8'hA5; s_memory[69] = 8'h0F; s_memory[70] = 8'hCA; s_memory[71] = 8'h90;
      s_memory[72] = 8'h37; s_memory[73] = 8'hF3; s_memory[74] = 8'hE8; s_memory[75] = 8'hBE;
      s_memory[76] = 8'h8F; s_memory[77] = 8'h67; s_memory[78] = 8'h09; s_memory[79] = 8'h5F;
      
      // Row 5
      s_memory[80] = 8'hAD; s_memory[81] = 8'hA4; s_memory[82] = 8'hEE; s_memory[83] = 8'hBF;
      s_memory[84] = 8'hA1; s_memory[85] = 8'h8A; s_memory[86] = 8'hF2; s_memory[87] = 8'hEC;
      s_memory[88] = 8'hA0; s_memory[89] = 8'h5E; s_memory[90] = 8'h1E; s_memory[91] = 8'h96;
      s_memory[92] = 8'h45; s_memory[93] = 8'hC2; s_memory[94] = 8'h3B; s_memory[95] = 8'h28;
      s_memory[96] = 8'h2B; s_memory[97] = 8'h68; s_memory[98] = 8'hED; s_memory[99] = 8'h36;
      
      // Row 6
      s_memory[100] = 8'hE5; s_memory[101] = 8'h92; s_memory[102] = 8'h9A; s_memory[103] = 8'hB3;
      s_memory[104] = 8'hDB; s_memory[105] = 8'h77; s_memory[106] = 8'h6A; s_memory[107] = 8'hD4;
      s_memory[108] = 8'hA2; s_memory[109] = 8'h56; s_memory[110] = 8'h27; s_memory[111] = 8'h1B;
      s_memory[112] = 8'hEB; s_memory[113] = 8'h54; s_memory[114] = 8'h98; s_memory[115] = 8'h84;
      s_memory[116] = 8'h25; s_memory[117] = 8'hBC; s_memory[118] = 8'h34; s_memory[119] = 8'hFB;
      
      // Row 7
      s_memory[120] = 8'h42; s_memory[121] = 8'hF0; s_memory[122] = 8'h17; s_memory[123] = 8'hD0;
      s_memory[124] = 8'hD2; s_memory[125] = 8'h13; s_memory[126] = 8'h51; s_memory[127] = 8'h4C;
      s_memory[128] = 8'h33; s_memory[129] = 8'hC3; s_memory[130] = 8'h1A; s_memory[131] = 8'h31;
      s_memory[132] = 8'hF6; s_memory[133] = 8'h60; s_memory[134] = 8'h82; s_memory[135] = 8'h10;
      s_memory[136] = 8'hE1; s_memory[137] = 8'h73; s_memory[138] = 8'h41; s_memory[139] = 8'hD8;
      
      // Row 8
      s_memory[140] = 8'h4B; s_memory[141] = 8'h3C; s_memory[142] = 8'hDF; s_memory[143] = 8'hAA;
      s_memory[144] = 8'h5D; s_memory[145] = 8'h9C; s_memory[146] = 8'h05; s_memory[147] = 8'hD6;
      s_memory[148] = 8'h0A; s_memory[149] = 8'h19; s_memory[150] = 8'hC9; s_memory[151] = 8'h0E;
      s_memory[152] = 8'hFC; s_memory[153] = 8'h06; s_memory[154] = 8'h6D; s_memory[155] = 8'hF5;
      s_memory[156] = 8'h99; s_memory[157] = 8'h58; s_memory[158] = 8'h29; s_memory[159] = 8'hB6;
      
      // Row 9
      s_memory[160] = 8'h4D; s_memory[161] = 8'hC7; s_memory[162] = 8'h53; s_memory[163] = 8'hC1;
      s_memory[164] = 8'hC6; s_memory[165] = 8'h48; s_memory[166] = 8'h07; s_memory[167] = 8'h8D;
      s_memory[168] = 8'h59; s_memory[169] = 8'h7A; s_memory[170] = 8'hB7; s_memory[171] = 8'h00;
      s_memory[172] = 8'h7D; s_memory[173] = 8'hB5; s_memory[174] = 8'hCF; s_memory[175] = 8'h14;
      s_memory[176] = 8'hDD; s_memory[177] = 8'h3E; s_memory[178] = 8'hDE; s_memory[179] = 8'hD7;
      
      // Row 10
      s_memory[180] = 8'hBB; s_memory[181] = 8'h22; s_memory[182] = 8'h62; s_memory[183] = 8'h2D;
      s_memory[184] = 8'hA9; s_memory[185] = 8'h03; s_memory[186] = 8'h39; s_memory[187] = 8'h50;
      s_memory[188] = 8'h21; s_memory[189] = 8'h20; s_memory[190] = 8'h76; s_memory[191] = 8'h7C;
      s_memory[192] = 8'hE0; s_memory[193] = 8'hD9; s_memory[194] = 8'h95; s_memory[195] = 8'hAE;
      s_memory[196] = 8'hBD; s_memory[197] = 8'h6E; s_memory[198] = 8'h1C; s_memory[199] = 8'h12;
      
      // Row 11
      s_memory[200] = 8'hD3; s_memory[201] = 8'h70; s_memory[202] = 8'h38; s_memory[203] = 8'hAF;
      s_memory[204] = 8'hF7; s_memory[205] = 8'h43; s_memory[206] = 8'hF9; s_memory[207] = 8'h6B;
      s_memory[208] = 8'hD5; s_memory[209] = 8'h1D; s_memory[210] = 8'h71; s_memory[211] = 8'h8C;
      s_memory[212] = 8'h83; s_memory[213] = 8'h23; s_memory[214] = 8'hF8; s_memory[215] = 8'h7F;
      s_memory[216] = 8'h9F; s_memory[217] = 8'hFD; s_memory[218] = 8'h2A; s_memory[219] = 8'hDC;
      
      // Row 12
      s_memory[220] = 8'h69; s_memory[221] = 8'h97; s_memory[222] = 8'hFE; s_memory[223] = 8'h8B;
      s_memory[224] = 8'hB9; s_memory[225] = 8'h0D; s_memory[226] = 8'h2E; s_memory[227] = 8'hE3;
      s_memory[228] = 8'h85; s_memory[229] = 8'h87; s_memory[230] = 8'hE2; s_memory[231] = 8'hB0;
      s_memory[232] = 8'h63; s_memory[233] = 8'hD1; s_memory[234] = 8'hB4; s_memory[235] = 8'h94;
      s_memory[236] = 8'h78; s_memory[237] = 8'hBA; s_memory[238] = 8'hE9; s_memory[239] = 8'hE4;
      
      // Row 13
      s_memory[240] = 8'hE6; s_memory[241] = 8'h18; s_memory[242] = 8'hCB; s_memory[243] = 8'h04;
      s_memory[244] = 8'hC5; s_memory[245] = 8'hE7; s_memory[246] = 8'hA7; s_memory[247] = 8'h6C;
      s_memory[248] = 8'h4F; s_memory[249] = 8'h6F; s_memory[250] = 8'h47; s_memory[251] = 8'h80;
      s_memory[252] = 8'h35; s_memory[253] = 8'h5B; s_memory[254] = 8'h75; s_memory[255] = 8'hF1;
      
      // Initialize encrypted message with provided values
      e_memory[0] = 8'd45;   e_memory[1] = 8'd143;  e_memory[2] = 8'd122; e_memory[3] = 8'd169;
      e_memory[4] = 8'd56;    e_memory[5] = 8'd115;  e_memory[6] = 8'd95;  e_memory[7] = 8'd135;
      e_memory[8] = 8'd69;    e_memory[9] = 8'd27;   e_memory[10] = 8'd130; e_memory[11] = 8'd134;
      e_memory[12] = 8'd75;   e_memory[13] = 8'd155; e_memory[14] = 8'd127; e_memory[15] = 8'd157;
      e_memory[16] = 8'd239;  e_memory[17] = 8'd13;  e_memory[18] = 8'd196; e_memory[19] = 8'd187;
      e_memory[20] = 8'd249;  e_memory[21] = 8'd119; e_memory[22] = 8'd153; e_memory[23] = 8'd117;
      e_memory[24] = 8'd255;  e_memory[25] = 8'd213; e_memory[26] = 8'd96;  e_memory[27] = 8'd115;
      e_memory[28] = 8'd1;    e_memory[29] = 8'd248; e_memory[30] = 8'd22;  e_memory[31] = 8'd37;
      
      $display("Memories initialized with specific test data");
    end
  endtask

  // Display decrypted results
  task display_results();
    integer i;
    begin
      $display("\nDecrypted Message (Hex):");
      for (i = 0; i < 32; i = i + 1) begin
        $write("%h ", d_memory[i]);
        if ((i+1) % 8 == 0) $write("\n");
      end
      
      $display("\nDecrypted Message (ASCII):");
      for (i = 0; i < 32; i = i + 1) begin
        // Only print printable ASCII characters
        if (d_memory[i] >= 8'h20 && d_memory[i] <= 8'h7E)
          $write("%c", d_memory[i]);
        else
          $write(".");
        if ((i+1) % 8 == 0) $write("\n");
      end
      $display("\n");
    end
  endtask

  // Monitor for debugging
  initial begin
    $timeformat(-9, 0, " ns", 6);
    $monitor("[%0t] State: %s, i=%h, j=%h, k=%d, s_i=%h, s_j=%h, f=%h",
             $time, dut.state.name(), dut.i, dut.j, dut.k, dut.s_i, dut.s_j, dut.f);
  end

endmodule