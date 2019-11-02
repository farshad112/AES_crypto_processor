`timescale 1ns/1ps

module aes_decryp_core#(
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
                        output logic [7:0] plain_text_o [NO_ROWS-1:0][NO_COLS-1:0], // plain text matrix
                        input logic [7:0] cipher_key_i [NO_ROWS-1:0][NO_COLS-1:0],  // cipher key matrix
                        input logic key_vld_i,                                      // round key is valid
                        output logic key_req_o,                                     // request for a round key
                        output logic [3:0] key_sel_o,                               // round key selector 
                        output logic plain_text_rdy_o,                              // cipher text is rdy
                        input logic [7:0] cipher_text_i [NO_ROWS-1:0][NO_COLS-1:0], // cipher text matrix
                        output logic cipher_text_rdy_o,                             // ready  for cipher matrix
                        input logic cipher_text_vld_i                               // cipher text matrix valid
                    );
    
    // variable declaration
    logic [3:0] aes_round_counter;  
    logic [7:0] initial_matrix[NO_ROWS-1:0][NO_COLS-1:0];

    // variables rtelated to aes round control
    logic initial_round_done;
    logic isub_byte_done;
    logic ishift_rw_mix_col_done;
    logic add_round_key_done;

    // local variables for sbox substitution control
    logic isbox_sub_en;
    logic [3:0] isbox_row_mask;
    logic [3:0] isbox_col_mask;
    logic isbox_sub_valid;
    logic [7:0] isbox_sub_matrix [NO_ROWS-1:0][NO_COLS-1:0];

    // mix column related variables
    logic [7:0] inv_galios_field_matrix [3:0][3:0];
    logic [7:0] cipher_text_matrix [3:0][3:0];
    logic [7:0] plain_text_matrix [3:0][3:0];

    // main decryption logic 
    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            plain_text_rdy_o = 0;
            cipher_text_rdy_o = 1;
            isbox_sub_en = 0;
            foreach(plain_text_o[i,j]) begin
                plain_text_o[i][j] = 0;
            end
            foreach(isbox_sub_matrix[i,j]) begin
                isbox_sub_matrix[i][j] = 0;
            end
            foreach(cipher_text_matrix[i,j]) begin
                cipher_text_matrix[i][j] = 0;
            end
            foreach(initial_matrix[i,j]) begin
                initial_matrix[i][j] = 0;
            end
            aes_round_counter = 0;
            initial_round_done = 0;
            isub_byte_done = 0;
            key_req_o = 0;
            add_round_key_done = 0;
            ishift_rw_mix_col_done = 0;
            key_sel_o = 10;
        end
        else begin
            if(aes_core_en) begin
                cipher_text_rdy_o = 1;
                if(cipher_text_vld_i) begin
                    if(aes_round_counter == 0) begin   // initial aes_decryption round
                        plain_text_rdy_o = 0;  // plain text is not produced yet
                        if(!initial_round_done) begin  // request for round key 10
                            key_req_o = 1;
                            key_sel_o = 10;
                            if(key_vld_i) begin
                                initial_round_done = 1;
                            end
                        end
                        else begin
                            foreach(cipher_text_i[i,j]) begin
                                initial_matrix[i][j] = cipher_text_i[i][j] ^ cipher_key_i[i][j];
                            end
                            // inverse shift rows
                            inverse_shift_rows(initial_matrix, initial_matrix);
                            // inverse sub_bytes
                            if(!isbox_sub_valid) begin
                                key_req_o = 0;
                                isbox_sub_en = 1;
                                isbox_row_mask = 4'hF;
                                isbox_col_mask = 4'hF;
                            end
                            else begin
                                isbox_sub_en = 0;
                                aes_round_counter += 1;
                                $display("isbox_sub_matrix:%0p", isbox_sub_matrix);
                            end
                        end
                    end
                    else if(aes_round_counter > 0 && aes_round_counter < 10) begin // perform 0-9 aes_decryption rounds
                        cipher_text_rdy_o = 0;
                        // add round key
                        if(!add_round_key_done) begin
                            key_req_o = 1;
                            key_sel_o = 10 - aes_round_counter;  // request for consecutive round_key i.e. round_key9,round_key8,round_key7....round_key1
                            if(key_vld_i) begin
                                foreach(initial_matrix[i,j]) begin  // round_key addition with isbox_sub_matrix
                                    initial_matrix[i][j] = isbox_sub_matrix[i][j] ^ cipher_key_i[i][j];
                                end
                                add_round_key_done = 1;
                            end
                        end
                        else if(!ishift_rw_mix_col_done) begin
                            key_req_o = 0;
                            // inverse mix column
                            inverse_mix_columns(cipher_text_matrix);
                            // inverse shift rows
                            inverse_shift_rows(cipher_text_matrix, initial_matrix);
                            ishift_rw_mix_col_done = 1;
                        end
                        // inverse sub_bytes
                        else if(!isbox_sub_valid) begin
                            isbox_sub_en = 1;
                            isbox_row_mask = 4'hF;
                            isbox_col_mask = 4'hF;
                        end
                        else begin
                                isbox_sub_en = 0;
                                aes_round_counter += 1;
                                $display("isbox_sub_matrix:%0p", isbox_sub_matrix);
                                add_round_key_done = 0;
                                ishift_rw_mix_col_done = 0;
                                // request for cipher key for the last round
                                key_req_o = 1;
                                key_sel_o = 10 - aes_round_counter;     // request for cipher key
                        end
                    end
                    else if(aes_round_counter == 10) begin    // last round
                        cipher_text_rdy_o = 0;
                        // xor with cipher key to retrieve plain_text matrix
                        if(key_vld_i) begin
                            foreach(plain_text_matrix[i,j]) begin
                                plain_text_matrix[i][j] = isbox_sub_matrix[i][j] ^ cipher_key_i[i][j];
                            end
                            key_req_o = 0;
                            // drive output
                            foreach(plain_text_o[i,j]) begin
                                plain_text_o [i][j] = plain_text_matrix[i][j];
                            end
                            plain_text_rdy_o = 1;
                            aes_round_counter = 0;
                            initial_round_done = 0;
                        end
                    end 
                end
            end 
            else begin  // aes core disable
                plain_text_rdy_o = 0;
                aes_round_counter = 0;
                initial_round_done = 0;
                isub_byte_done = 0;
                ishift_rw_mix_col_done = 0;
            end
        end
    end

    // Instantiation  of isbox module
    isbox #(
            // parameters
            .NO_ROWS(NO_ROWS),
            .NO_COLS(NO_COLS)    
        ) I_AES_DECRYPT_ISBOX(
            // IO ports
            .resetn(resetn),
            .isbox_en(isbox_sub_en),
            .isbox_ip_char_matrix(initial_matrix),
            .isbox_ip_char_row_mask(isbox_row_mask),
            .isbox_ip_char_col_mask(isbox_col_mask),
            .isbox_op_char_matrix_valid(isbox_sub_valid),
            .isbox_op_char_matrix(isbox_sub_matrix)
        );

    task inverse_shift_rows(input logic [7:0] input_matrix[NO_ROWS-1:0][NO_COLS-1:0], output logic [7:0] shifted_matrix[NO_ROWS-1:0][NO_COLS-1:0]);
        logic [7:0] temp;

        for(int i=0; i<NO_ROWS; i++) begin
            case(i) 
                0:  begin    // no shift
                        for(int j=0; j<NO_COLS; j++) begin
                            input_matrix[i][j] = input_matrix[i][j];
                        end
                    end
                1:  begin
                        for(int j=NO_COLS-1; j>0; j--) begin    // rotate over 1 byte
                            temp = input_matrix[i][j];
                            input_matrix[i][j] = input_matrix[i][j-1];
                            input_matrix[i][j-1] = temp; 
                        end
                    end
                2:  begin
                        for(int j=NO_COLS-1; j>1; j--) begin  // rotate over 2 byte
                            temp = input_matrix[i][j];
                            input_matrix[i][j] = input_matrix[i][j-2];
                            input_matrix[i][j-2] = temp;
                        end
                    end
                3:  begin
                        for(int j=0; j<NO_COLS-1; j++) begin    // rotate over 3 byte (by performing 1 byte shift in reverse)
                            temp = input_matrix[i][j];
                            input_matrix[i][j] =  input_matrix[i][j+1];
                            input_matrix[i][j+1] = temp;
                        end
                    end
            endcase
        end
        // return output matrix
        foreach(shifted_matrix[i,j]) begin
            shifted_matrix[i][j] = input_matrix[i][j];
        end
    endtask

    task inverse_mix_columns(output logic [7:0] result_matrix[3:0][3:0]);
        logic [7:0] mix_column_matrix[3:0][3:0];
        logic [7:0] result;

        // the four values of each column is multiplied by Galios Field Matrix
        for(int i=0; i<NO_COLS; i++) begin  // No of column in initial_matrix
            for(int j=0; j<NO_ROWS; j++) begin  // No of rows in inv_galios_field_matrix
                mix_column_matrix[j][i] = 0;
                for(int k=0; k<NO_ROWS; k++) begin  // No of rows in initial_matrix and no of columns in inv_galios_field_matrix
//                    $display("inv_galios_field_matrix[%0d][%0d]:%0h, initial_matrix[%0d][%0d]:%0h", j, k, inv_galios_field_matrix[j][k], k,i, initial_matrix[k][i]);
                    do_galios_multiplication(inv_galios_field_matrix[j][k], initial_matrix[k][i], result);  // perform matrix multiplication 
//                    $display("result:%0h", result);
                    mix_column_matrix[j][i] = mix_column_matrix[j][i] ^ result;
//                    $display("mix_column_matrix[%0d][%0d]:%0h", j, i, mix_column_matrix[j][i]);
                end
            end
        end        
        // send the output
        foreach(result_matrix[i,j]) begin
            result_matrix[i][j] = mix_column_matrix[i][j];
        end
    endtask

    task do_galios_multiplication(input logic [7:0] gal_value, input logic [7:0] mat_value, output logic [7:0] result);
        logic [7:0] POM;    // product of multiplication 
        case(gal_value)
            8'h09:  begin
                        // x * 09 =   [{(x * 2) * 2} * 2 ] + x   over GF field
                        for(logic [3:0] i=0; i<3; i++) begin
                            if(i==0) begin
                                POM = do_GF_multiply_by_2(mat_value);
                            end
                            else begin
                                POM = do_GF_multiply_by_2(POM);
                            end
                        end
                        result = POM ^ mat_value;
                    end
            8'h0B:  begin
                        // x * 0B = ([{(x * 2) * 2} + x ] * 2) + x    over GF field
                        for(logic [3:0] i=0; i<2; i++) begin
                            if(i==0) begin
                                POM = do_GF_multiply_by_2(mat_value);
                            end
                            else begin
                                POM = do_GF_multiply_by_2(POM);
                            end
                        end
                        POM = POM ^ mat_value;
                        POM = do_GF_multiply_by_2(POM);
                        result = POM ^ mat_value;
                    end
            8'h0D:  begin
                        // x * 0D = [{((x * 2) + x) * 2} * 2 ] + x   over GF field
                        POM = do_GF_multiply_by_2(mat_value);
                        POM = POM ^ mat_value;
                        POM =  do_GF_multiply_by_2(POM);
                        POM =  do_GF_multiply_by_2(POM);
                        result = POM ^ mat_value;
                    end
            8'h0E:  begin
                        // x * 0E = ([{(x * 2) + x} * 2] + x) * 2 over GF field
                        POM = do_GF_multiply_by_2(mat_value);
                        POM = POM ^ mat_value;
                        POM =  do_GF_multiply_by_2(POM);
                        POM = POM ^ mat_value;
                        result =  do_GF_multiply_by_2(POM);
                    end
        endcase
    endtask

    function logic [7:0] do_GF_multiply_by_2(input logic [7:0] x);
        if(x[7] == 1) begin
            do_GF_multiply_by_2 = (x << 1) ^ 8'h1b;
        end
        else begin
            do_GF_multiply_by_2 = (x << 1);
        end
    endfunction

    /* galios field matrix
        0E  0B  0D  09
        09  0E  0B  0D
        0D  09  0E  0B
        0B  0D  09  0E
    */
    // generate galios_filed matrix
    assign inv_galios_field_matrix[0][0] = 8'h0E;
    assign inv_galios_field_matrix[0][1] = 8'h0B;
    assign inv_galios_field_matrix[0][2] = 8'h0D;
    assign inv_galios_field_matrix[0][3] = 8'h09;

    assign inv_galios_field_matrix[1][0] = 8'h09;
    assign inv_galios_field_matrix[1][1] = 8'h0E;
    assign inv_galios_field_matrix[1][2] = 8'h0B;
    assign inv_galios_field_matrix[1][3] = 8'h0D;

    assign inv_galios_field_matrix[2][0] = 8'h0D;
    assign inv_galios_field_matrix[2][1] = 8'h09;
    assign inv_galios_field_matrix[2][2] = 8'h0E;
    assign inv_galios_field_matrix[2][3] = 8'h0B;

    assign inv_galios_field_matrix[3][0] = 8'h0B;
    assign inv_galios_field_matrix[3][1] = 8'h0D;
    assign inv_galios_field_matrix[3][2] = 8'h09;
    assign inv_galios_field_matrix[3][3] = 8'h0E;
endmodule