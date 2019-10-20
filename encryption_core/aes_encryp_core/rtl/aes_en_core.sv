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
                        output logic [3:0] key_sel_o,                               // round key selector 
                        output logic cipher_text_rdy_o,                             // cipher text is rdy
                        output logic [7:0] cipher_text_o [NO_ROWS-1:0][NO_COLS-1:0] // cipher text matrix
                    );
    
    // variable declaration
    logic [3:0] aes_round_counter;  
    logic [7:0] initial_matrix[NO_ROWS-1:0][NO_COLS-1:0];

    // variables rtelated to aes round control
    logic sub_byte_done;

    // local variables for sbox substitution control
    logic sbox_sub_en;
    logic [3:0] sbox_row_mask;
    logic [3:0] sbox_col_mask;
    logic sbox_sub_valid;
    logic [7:0] sbox_sub_matrix [NO_ROWS-1:0][NO_COLS-1:0];

    // local variables for shift row substitution
    logic [7:0] temp_0;     // for shifting 1 byte
    logic [7:0] temp_1;     // for shifting 2 bytes
    logic [7:0] temp_2;     // for shifting 3 bytes

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
                    sub_byte_done = 0;
                    $display("initial matrix:%0p", initial_matrix);
                end
                else if(aes_round_counter > 0 && aes_round_counter < 10) begin // perform 0-9 aes_encryption rounds
                    // sub bytes
                    if(!sub_byte_done) begin
                        if(!sbox_sub_valid) begin
                            sbox_sub_en = 1;
                            sbox_row_mask = 4'hF;
                            sbox_col_mask = 4'hF;
                        end
                        else begin
                            sbox_sub_en = 0;
                            sub_byte_done = 1;
                        end
                    end
                    else begin  
                        // shift rows
                        shift_rows();
                        // mix columns
                         
                    end
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
            .sbox_ip_char_matrix(initial_matrix),
            .sbox_ip_char_row_mask(sbox_row_mask),
            .sbox_ip_char_col_mask(sbox_col_mask),
            .sbox_op_char_matrix_valid(sbox_sub_valid),
            .sbox_op_char_matrix(sbox_sub_matrix)
        );

    task shift_rows();
        logic [7:0] temp;

        for(int i=0; i<NO_ROWS; i++) begin
            case(i) 
                0:  begin    // no shift
                        for(int j=0; j<NO_COLS; j++) begin
                            sbox_sub_matrix[i][j] = sbox_sub_matrix[i][j];
                        end
                    end
                1:  begin
                        for(int j=0; j<NO_COLS-1; j++) begin    // rotate over 1 byte
                            temp = sbox_sub_matrix[i][j];
                            sbox_sub_matrix[i][j] = sbox_sub_matrix[i][j+1];
                            sbox_sub_matrix[i][j+1] = temp; 
                        end
                    end
                2:  begin
                        for(int j=0; j<NO_COLS-2; j++) begin  // rotate over 2 byte
                            temp = sbox_sub_matrix[i][j];
                            sbox_sub_matrix[i][j] = sbox_sub_matrix[i][j+2];
                            sbox_sub_matrix[i][j+2] = temp;
                        end
                    end
                3:  begin
                        for(int j=NO_COLS-1; j>0; j--) begin    // rotate over 3 byte (by performing 1 byte shift in reverse)
                            temp = sbox_sub_matrix[i][j];
                            sbox_sub_matrix[i][j] =  sbox_sub_matrix[i][j-1];
                            sbox_sub_matrix[i][j-1] = temp;
                        end
                    end
            endcase
        end
    endtask

    task mix_columns();
        
    endtask
endmodule