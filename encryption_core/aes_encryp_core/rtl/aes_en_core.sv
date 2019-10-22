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
    logic initial_round_done;
    logic sub_byte_done;
    logic shift_rw_mix_col_done;

    // local variables for sbox substitution control
    logic sbox_sub_en;
    logic [3:0] sbox_row_mask;
    logic [3:0] sbox_col_mask;
    logic sbox_sub_valid;
    logic [7:0] sbox_sub_matrix [NO_ROWS-1:0][NO_COLS-1:0];

    // mix column related variables
    logic [7:0] galios_field_matrix [3:0][3:0];
    logic [7:0] cipher_text_matrix [3:0][3:0];

    // main encryption logic 
    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            cipher_text_rdy_o = 0;
            foreach(cipher_text_o[i,j]) begin
                cipher_text_o[i][j] = 0;
            end
            aes_round_counter = 0;
            initial_round_done = 0;
            sub_byte_done = 0;
            key_req_o = 0;
            shift_rw_mix_col_done = 0;
        end
        else begin
            if(aes_core_en) begin
                if(aes_round_counter == 0) begin   // initial aes_encryption round
                    cipher_text_rdy_o = 0;  // cipher text is not produced yet
                    if(!initial_round_done) begin  // request for cipher key
                        key_req_o = 1;
                        key_sel_o = 0;
                        if(key_vld_i) begin
                            initial_round_done = 1;
                        end
                    end
                    else begin
                        foreach(plain_text_i[i,j]) begin
                            initial_matrix[i][j] = plain_text_i[i][j] ^ cipher_key_i[i][j];
                        end
                        aes_round_counter += 1;
                        sub_byte_done = 0;
                        $display("initial matrix:%0p", initial_matrix);
                    end
                end
                else if(aes_round_counter > 0 && aes_round_counter < 10) begin // perform 0-9 aes_encryption rounds
                    // sub bytes
                    if(!sub_byte_done) begin
                        if(!sbox_sub_valid) begin
                            key_req_o = 0;
                            sbox_sub_en = 1;
                            sbox_row_mask = 4'hF;
                            sbox_col_mask = 4'hF;
                        end
                        else begin
                            sbox_sub_en = 0;
                            sub_byte_done = 1;
                        end
                    end
                    else if(!shift_rw_mix_col_done) begin  
                        // shift rows
                        shift_rows();
                        // mix columns
                        mix_columns(cipher_text_matrix);
                        // request a round key
                        key_req_o = 1;
                        key_sel_o = aes_round_counter;
                        shift_rw_mix_col_done = 1;
                    end
                    else if(key_vld_i) begin    // wait for valid round key to be delivered from aes_key_expander 
                        // perform xor with mixed column cipher_text_matrix and round key
                        foreach(initial_matrix[i,j]) begin
                            initial_matrix[i][j] = cipher_text_matrix[i][j] ^ cipher_key_i[i][j];
                        end
                        aes_round_counter += 1;
                        sub_byte_done = 0;
                        shift_rw_mix_col_done = 0;
                    end
                end
                else if(aes_round_counter == 10) begin    // last round
                    // sub bytes
                    if(!sub_byte_done) begin
                        if(!sbox_sub_valid) begin
                            key_req_o = 0;
                            sbox_sub_en = 1;
                            sbox_row_mask = 4'hF;
                            sbox_col_mask = 4'hF;
                        end
                        else begin
                            sbox_sub_en = 0;
                            sub_byte_done = 1;
                        end
                    end
                    else if(!shift_rw_mix_col_done) begin  
                        // shift rows
                        shift_rows();
                        // request a round key
                        key_req_o = 1;
                        key_sel_o = aes_round_counter;
                        shift_rw_mix_col_done = 1;
                    end
                    else if(key_vld_i) begin    // wait for valid round key to be delivered from aes_key_expander 
                        // perform xor with shifted row sbox_sub_matrix and round key
                        foreach(initial_matrix[i,j]) begin
                            initial_matrix[i][j] = sbox_sub_matrix[i][j] ^ cipher_key_i[i][j];
                        end
                        aes_round_counter = 0;  // reset aes_round counter
                        sub_byte_done = 0;
                        shift_rw_mix_col_done = 0;
                        initial_round_done = 0;
                        // deliver cipher text output
                        cipher_text_rdy_o = 1;
                        foreach(cipher_text_o[i,j]) begin
                            cipher_text_o[i][j] = initial_matrix[i][j];
                        end
                    end
                end                
            end
            else begin  // aes core disable
                cipher_text_rdy_o = 0;
                aes_round_counter = 0;
                initial_round_done = 0;
                sub_byte_done = 0;
                shift_rw_mix_col_done = 0;
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

    task mix_columns(output logic [7:0] result_matrix[3:0][3:0]);
        logic [7:0] mix_column_matrix[3:0][3:0];
        logic [7:0] result;

        // the four values of each column is multiplied by Galios Field Matrix
        for(int i=0; i<NO_COLS; i++) begin  // No of column in sbox_sub_matrix
            for(int j=0; j<NO_ROWS; j++) begin  // No of rows in galios_field_matrix
                mix_column_matrix[j][i] = 0;
                for(int k=0; k<NO_ROWS; k++) begin  // No of rows in sbox_sub_matrix and no of columns in galios_field_matrix
//                    $display("galios_field_matrix[%0d][%0d]:%0h, sbox_sub_matrix[%0d][%0d]:%0h", j, k, galios_field_matrix[j][k], k,i, sbox_sub_matrix[k][i]);
                    do_galios_multiplication(galios_field_matrix[j][k], sbox_sub_matrix[k][i], result);  // perform matrix multiplication 
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
        case(gal_value)
            1:  begin
                    result = mat_value;
                end
            2:  begin
                    if(mat_value[7] == 1) begin
                        result = (mat_value << 1) ^ 8'h1b;
                    end
                    else begin
                        result = mat_value << 1;
                    end
                end
            3:  begin
                    if(mat_value[7] == 1) begin
                        result = ((mat_value << 1) ^ 8'h1b ) ^ mat_value;
                    end
                    else begin
                        result = (mat_value << 1 ) ^ mat_value;
                    end
                end
        endcase
    endtask

    /* galios field matrix
        02  03  01  01
        01  02  03  01
        01  01  02  03
        03  01  01  02
    */
    // generate galios_filed matrix
    assign galios_field_matrix[0][0] = 8'h02;
    assign galios_field_matrix[0][1] = 8'h03;
    assign galios_field_matrix[0][2] = 8'h01;
    assign galios_field_matrix[0][3] = 8'h01;

    assign galios_field_matrix[1][0] = 8'h01;
    assign galios_field_matrix[1][1] = 8'h02;
    assign galios_field_matrix[1][2] = 8'h03;
    assign galios_field_matrix[1][3] = 8'h01;

    assign galios_field_matrix[2][0] = 8'h01;
    assign galios_field_matrix[2][1] = 8'h01;
    assign galios_field_matrix[2][2] = 8'h02;
    assign galios_field_matrix[2][3] = 8'h03;

    assign galios_field_matrix[3][0] = 8'h03;
    assign galios_field_matrix[3][1] = 8'h01;
    assign galios_field_matrix[3][2] = 8'h01;
    assign galios_field_matrix[3][3] = 8'h02;
endmodule