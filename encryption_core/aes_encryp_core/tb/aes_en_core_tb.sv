`timescale 1ns/1ps

module aes_en_core_tb;
    logic       aes_clk;
    logic       resetn;
    logic       aes_core_en;
    logic       aes_encrypt_mode_en;
    logic       plain_text_vld_i;
    logic       plain_text_rdy_o;
    logic [7:0] plain_text [3:0][3:0];
    logic [7:0] cipher_key [3:0][3:0];
    logic [7:0] round_key [3:0][3:0];
    logic       key_vld;
    logic       key_req;
    logic [3:0] key_sel;
    logic       cipher_text_rdy;
    logic [7:0] cipher_text [3:0][3:0];
    logic       cipher_text_ack_i;
    logic       cipher_text_rdy_o; 

    // clock generation block
    initial begin
        aes_clk = 0;
        forever begin
            #10ns aes_clk = ~aes_clk;
        end
    end

    // drive cipher key
    initial begin
        cipher_key[0][0] = 8'h2b;
        cipher_key[0][1] = 8'h28;
        cipher_key[0][2] = 8'hab;
        cipher_key[0][3] = 8'h09;

        cipher_key[1][0] = 8'h7e;
        cipher_key[1][1] = 8'hae;
        cipher_key[1][2] = 8'hf7;
        cipher_key[1][3] = 8'hcf;

        cipher_key[2][0] = 8'h15;
        cipher_key[2][1] = 8'hd2;
        cipher_key[2][2] = 8'h15;
        cipher_key[2][3] = 8'h4f;

        cipher_key[3][0] = 8'h16;
        cipher_key[3][1] = 8'ha6;
        cipher_key[3][2] = 8'h88;
        cipher_key[3][3] = 8'h3c;
    end

    // drive plain text
    initial begin
        plain_text[0][0] = 8'h32;
        plain_text[0][1] = 8'h88;
        plain_text[0][2] = 8'h31;
        plain_text[0][3] = 8'he0;
        
        plain_text[1][0] = 8'h43;
        plain_text[1][1] = 8'h5a;
        plain_text[1][2] = 8'h31;
        plain_text[1][3] = 8'h37;

        plain_text[2][0] = 8'hf6;
        plain_text[2][1] = 8'h30;
        plain_text[2][2] = 8'h98;
        plain_text[2][3] = 8'h07;

        plain_text[3][0] = 8'ha8;
        plain_text[3][1] = 8'h8d;
        plain_text[3][2] = 8'ha2;
        plain_text[3][3] = 8'h34;
    end

    // testing block
    initial begin
        resetn = 0;
        aes_core_en = 0;
        aes_encrypt_mode_en = 0;
        plain_text_vld_i = 0;
        cipher_text_ack_i = 0;
        #30ns;
        resetn = 1;
        aes_core_en = 1;
        aes_encrypt_mode_en = 1;
        plain_text_vld_i = 1;
        wait(plain_text_rdy_o);
        wait(cipher_text_rdy);
        cipher_text_ack_i = 1;
    end

    // simulation stop block
    initial begin
        repeat(200) 
            @(posedge aes_clk);
        $finish();
    end

    // Instantiation of DUT
    aes_en_core#(
                    // parameters
                    .NO_ROWS(4),
                    .NO_COLS(4),
                    .NO_SBOX_ROWS(16),
                    .NO_SBOX_COLS(16)
                )I_AES_EN (
                        // IO ports
                    .aes_clk(aes_clk),                          // input
                    .resetn(resetn),                            // input
                    .aes_core_en(aes_core_en),                  // input
                    .aes_encrypt_mode_en(aes_encrypt_mode_en),  // input
                    .plain_text_i(plain_text),                  // input
                    .plain_text_vld_i(plain_text_vld_i),        // input
                    .plain_text_rdy_o(plain_text_rdy_o),        // output
                    .cipher_key_i(round_key),                   // input
                    .key_vld_i(key_vld),                        // input
                    .key_req_o(key_req),                        // output
                    .key_sel_o(key_sel),                        // output
                    .cipher_text_rdy_o(cipher_text_rdy),        // output
                    .cipher_text_ack_i(cipher_text_ack_i),      // input
                    .cipher_text_o(cipher_text)                 // output
                );
    
    // instantiation of AES key gen module
    aes_key_expander#(
                        // parameters
                        .KEY_WIDTH(128),
                        .SBOX_ROW_NO(4),
                        .SBOX_COL_NO(1)
                    ) I_AES_KEY_GEN(
                        // IO ports
                        .cipher_key(cipher_key),
                        .resetn(resetn),
                        .encrypt_en(aes_core_en),
                        .clk(aes_clk),
                        .key_req(key_req),
                        .key_sel(key_sel),
                        .key_rdy(key_vld),
                        .round_key(round_key)
                    );
 
endmodule
