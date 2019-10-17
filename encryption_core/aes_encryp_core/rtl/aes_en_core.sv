`timescale 1ns/1ps

module aes_en_core#(
                        // parameters
                        parameter NO_ROWS = 4,
                        parameter NO_COLS = 4,
                        parameter NO_SBOX_ROWS = 16,
                        parameter NO_SBOX_COLS = 16
                    )(
                        // IO ports
                        input logic aes_clk,                                        // clock
                        input logic resetn,                                         // reset (active low)
                        input logic aes_core_en,                                    // enable
                        input logic aes_encrypt_mode_en,                            // running in encryption or decryption mode
                        input logic [7:0] plain_text_i [NO_ROWS-1:0][NO_COLS-1:0],  // plain text matrix
                        input logic [7:0] cipher_key_i [NO_ROWS-1:0][NO_COLS-1:0],  // cipher key matrix
                        input logic key_vld_i,                                      // round key is valid
                        output logic key_req_o,                                     // request for a round key
                        output logic cipher_text_rdy_o,                             // cipher text is rdy
                        output logic [7:0] cipher_text_o [NO_ROWS-1:0][NO_COLS-1:0] // cipher text matrix
                    );
    
    // variable declaration
    logic [3:0] aes_round_counter;  
    logic sub_byte_done;
    logic [7:0] initial_matrix[NO_ROWS-1:0][NO_COLS-1:0];

    // local variables for sbox substitution control
    logic sbox_sub_en;
    logic 

    // main encryption logic 
    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            cipher_text_rdy_o = 0;
            foreach(cipher_text_o[i,j]) begin
                cipher_text_o[i][j] = 0;
            end
            aes_round_counter = 0;
            sub_byte_done = 0;
            key_req_o = 0;
        end
        else begin
            if(aes_core_en) begin
                if(aes_round_counter == 0) begin   // initial aes_encryption round
                    foreach(plain_text_i[i,j]) begin
                        initial_matrix[i][j] = plain_text_i[i][j] ^ cipher_key_i[i][j];
                    end
                    aes_round_counter += 1;
                    $display("initial matrix:%0p", initial_matrix);
                end
                else if(aes_round_counter > 0 && aes_round_counter < 10) begin // perform 0-9 aes_encryption rounds
                    // sub bytes
                    
                end
            end
            else begin  // aes core disable
                cipher_text_rdy_o = 0;
                aes_round_counter = 0;
                sub_byte_done = 0;
            end
        end
    end

    // Instantiation  of sbox module
    sbox #(
            // parameters
            .NO_ROWS(NO_ROWS),
            .NO_COLS(NO_COLS)    
        ) I_AES_ENCRYPT_SBOX(
            // IO ports
            .resetn(resetn),
            .sbox_en(sbox_sub_en),
            .sbox_ip_char_matrix(plain_text_i),
            .sbox_ip_char_row_mask(),
            .sbox_ip_char_col_mask(),
            .sbox_op_char_matrix_valid(),
            .sbox_op_char_matrix()
        );

endmodule