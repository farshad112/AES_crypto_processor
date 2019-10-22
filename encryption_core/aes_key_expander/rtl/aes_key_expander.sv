`timescale 1ns/1ps

module aes_key_expander#(
                            // parameters
                            parameter KEY_WIDTH=128,
                            parameter SBOX_ROW_NO = 4,
                            parameter SBOX_COL_NO = 1
                        )(
                            // IO ports
                            input logic [7:0] cipher_key [3:0] [3:0],
                            input logic resetn,
                            input logic encrypt_en,
                            input logic clk,
                            input logic key_req,
                            input logic [3:0] key_sel,
                            output logic key_rdy,
                            output logic [7:0] round_key[3:0][3:0]
                        );
    
    // round constant matrix
    logic [7:0] rcon_matrix [4:0] [9:0];
    logic [4:0] rcon_col_index;

    // register for holding round keys
    logic [7:0] round_key_matrix [3:0] [3:0][9:0];
    logic [1:0] round_key_row_index;
    logic [1:0] round_key_col_index;

    // counter and control flags for round key generation
    logic key_gen_done;
    logic [3:0] key_counter;

    // key gen algorithm related registers
    logic [1:0] cipher_key_col_index;           // select the columns of cipher key matrix 
    logic [7:0] root_word [3:0];                // root word for key generation
    logic [7:0] shifted_root_word [3:0];        // root word after column shifting
    logic [7:0] sb_root_word[3:0];              // rootword after subbytes
    logic [2:0] root_word_index;

    // sbox related signals
    logic sbox_en;              // sbox enable
    logic sbox_op_vld;          // sbox output valid

    // generate keys
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            key_rdy = 0;
            foreach(round_key[i,j]) begin
                round_key[i][j] = 0;
            end
            // reset control flags
            key_gen_done = 0;
            key_counter = 0;
            sbox_en = 0;
            rcon_col_index = 0;
            // reset round key matrix
            foreach(round_key_matrix[i,j,k]) begin
                round_key_matrix[i][j][k] = 0;
            end
        end
        else begin
            if(encrypt_en) begin
                if(!key_gen_done) begin
                    if(key_counter < 10 && sbox_op_vld == 0) begin
                        if(key_counter == 0) begin
                            // get root word from cipher key
                            for(logic [2:0] i=0; i<4; i++) begin
                                root_word[i] = cipher_key[i][3];
                            end
                        end
                        else begin
                            // get root word from round key [key_counter-1]
                            for(logic [2:0] i=0; i<4; i++) begin
                                root_word[i] = round_key_matrix[i][3][key_counter-1];
                            end
                        
                        end
                        $display("root_word:%0p", root_word);
                        // perform shift operation on root word
                        shift_root_word(root_word, shifted_root_word);
                        // perform sbox substitution
                        sbox_en = 1;
                    end
                    else if(key_counter < 10 && sbox_op_vld == 1) begin
                        $display("shifted_root_word: %0p, sb_root_word:%0p", shifted_root_word, sb_root_word);
                        for(logic [4:0] p=0; p<4; p++) begin
                            // perform xor operation with sb_root_word, cipher_key_matrix column 0 and round constant
                            $display("p:%0d", p);
                            rcon_col_index = key_counter;
                            cipher_key_col_index = p;
                            round_key_col_index = p;
                            print_rcon_col(rcon_matrix, key_counter);
                            if(p==0) begin
                                if(key_counter == 0) begin
                                    // first column of round key 1
                                    for(logic [4:0] i=0; i<$size(sb_root_word); i++) begin
                                        round_key_matrix[i][round_key_col_index][key_counter] = cipher_key[i][cipher_key_col_index] ^ sb_root_word[i] ^ rcon_matrix[i][rcon_col_index];
                                    end
                                end
                                else begin
                                    // first column of round key 2 and onward
                                    for(logic [4:0] i=0; i<$size(sb_root_word); i++) begin
                                        round_key_matrix[i][round_key_col_index][key_counter] = round_key_matrix[i][round_key_col_index][key_counter-1] ^ sb_root_word[i] ^ rcon_matrix[i][rcon_col_index];
                                    end
                                end
                            end
                            else begin
                                if(key_counter == 0) begin
                                    // perform xor operation with first column of round key 1 and 2nd column of cipher key
                                    for(logic [4:0] i=0; i<$size(sb_root_word); i++) begin
                                        round_key_matrix[i][round_key_col_index][key_counter] = cipher_key[i][cipher_key_col_index] ^ round_key_matrix[i][round_key_col_index-1][key_counter];
                                    end
                                end
                                else begin
                                    // perform xor operation with first column of round key 1 and 2nd column of round key[key_counter-1]
                                    for(logic [4:0] i=0; i<$size(sb_root_word); i++) begin
                                        round_key_matrix[i][round_key_col_index][key_counter] = round_key_matrix[i][round_key_col_index][key_counter-1] ^ round_key_matrix[i][round_key_col_index-1][key_counter];
                                    end
                                end
                            end
                        end
                        $display("round_key_matrix:%0p", round_key_matrix);
                        print_matrix(round_key_matrix, "round_key_matrix");
                        // increment the key counter
                        key_counter += 1;
                        sbox_en = 0;
                    end    
                    else begin
                        key_gen_done = 1;
                    end
                end
                else begin  // key is ready to deliver
                    if(key_req) begin   // encryptor has requested for a valid key
                        key_rdy = 1;
                        // deleiver the generated key to the output based on the selector pin
                        if(key_sel == 0) begin
                            foreach(round_key[i,j]) begin
                                round_key[i][j] = cipher_key[i][j];
                            end
                        end
                        else if(key_sel> 0 && key_sel < 11) begin
                            foreach(round_key[i,j]) begin
                                round_key[i][j] = round_key_matrix[i][j][key_sel-1];
                            end
                        end
                        else begin  // invalid key selector value
                            key_rdy = 0;
                            foreach(round_key[i,j]) begin
                                round_key[i][j] = 0;
                            end
                        end
                    end
                    else begin
                        key_rdy = 0;
                    end
                end
            end
            else begin
                key_gen_done = 0;
                key_rdy = 0;
            end
        end
    end    

    // create round constant table
    assign rcon_matrix[0][0] = 8'h1;
    assign rcon_matrix[0][1] = 8'h2;
    assign rcon_matrix[0][2] = 8'h4;
    assign rcon_matrix[0][3] = 8'h8;
    assign rcon_matrix[0][4] = 8'h10;
    assign rcon_matrix[0][5] = 8'h20;
    assign rcon_matrix[0][6] = 8'h40;
    assign rcon_matrix[0][7] = 8'h80;
    assign rcon_matrix[0][8] = 8'h1B;
    assign rcon_matrix[0][9] = 8'h36;

    assign rcon_matrix[1][0] = 8'h0;
    assign rcon_matrix[1][1] = 8'h0;
    assign rcon_matrix[1][2] = 8'h0;
    assign rcon_matrix[1][3] = 8'h0;
    assign rcon_matrix[1][4] = 8'h0;
    assign rcon_matrix[1][5] = 8'h0;
    assign rcon_matrix[1][6] = 8'h0;
    assign rcon_matrix[1][7] = 8'h0;
    assign rcon_matrix[1][8] = 8'h0;
    assign rcon_matrix[1][9] = 8'h0;

    assign rcon_matrix[2][0] = 8'h0;
    assign rcon_matrix[2][1] = 8'h0;
    assign rcon_matrix[2][2] = 8'h0;
    assign rcon_matrix[2][3] = 8'h0;
    assign rcon_matrix[2][4] = 8'h0;
    assign rcon_matrix[2][5] = 8'h0;
    assign rcon_matrix[2][6] = 8'h0;
    assign rcon_matrix[2][7] = 8'h0;
    assign rcon_matrix[2][8] = 8'h0;
    assign rcon_matrix[2][9] = 8'h0;

    assign rcon_matrix[3][0] = 8'h0;
    assign rcon_matrix[3][1] = 8'h0;
    assign rcon_matrix[3][2] = 8'h0;
    assign rcon_matrix[3][3] = 8'h0;
    assign rcon_matrix[3][4] = 8'h0;
    assign rcon_matrix[3][5] = 8'h0;
    assign rcon_matrix[3][6] = 8'h0;
    assign rcon_matrix[3][7] = 8'h0;
    assign rcon_matrix[3][8] = 8'h0;
    assign rcon_matrix[3][9] = 8'h0;

    assign rcon_matrix[4][0] = 8'h0;
    assign rcon_matrix[4][1] = 8'h0;
    assign rcon_matrix[4][2] = 8'h0;
    assign rcon_matrix[4][3] = 8'h0;
    assign rcon_matrix[4][4] = 8'h0;
    assign rcon_matrix[4][5] = 8'h0;
    assign rcon_matrix[4][6] = 8'h0;
    assign rcon_matrix[4][7] = 8'h0;
    assign rcon_matrix[4][8] = 8'h0;
    assign rcon_matrix[4][9] = 8'h0;

    // Instantiation of key_gen_sbox module
    key_gen_sbox#(
                    // parameters
                    .NO_ROWS(4),
                    .SBOX_ROWS(16),
                    .SBOX_COLS(16)
                ) I_AES_KEY_GEN_SBOX(
                    // IO ports
                    .resetn(resetn),
                    .sbox_en(sbox_en),
                    .sbox_ip_char_matrix(shifted_root_word),
                    .sbox_op_char_matrix_valid(sbox_op_vld),
                    .sbox_op_char_matrix(sb_root_word)
                );


    ////////////////////////////////////////////////////// Task and functions ///////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////
    // task name: shift_root_word                                                               //
    // parameters:                                                                              //
    //              -> logic [7:0] root_word [3:0] : root word matrix                           //
    //              -> ref logic [7:0] shifted_root_word [3:0] : shifted root word matrix       //
    // description: Perform shift operation on root_word                                        //
    //////////////////////////////////////////////////////////////////////////////////////////////
    task shift_root_word(input logic [7:0] root_word[3:0], output logic [7:0] shifted_root_word[3:0]);
        logic [2:0] i;  
        logic [1:0] j;  // use overflow to perform shift operation
        begin
            j=$size(root_word)-1;
            for(i=0; i<$size(root_word); i++) begin
                shifted_root_word[j] = root_word[i];
                j++;
            end
            `ifdef DEBUG_AES_KEY
                $display("root_word:%0p", root_word);
                $display("shifted_root_word:%0p", shifted_root_word);
            `endif
        end
    endtask

    //////////////////////////////////////////////////////////////////////////////////////////////
    // function name: print_matrix                                                              //
    // parameters:                                                                              //
    //                                                                                          //
    //                                                                                          //
    // description: Print the matrix                                                            //
    //////////////////////////////////////////////////////////////////////////////////////////////
    function void print_matrix(logic [7:0] mat[3:0][3:0][9:0], string name="mat");
        foreach(mat[i,j,k]) begin
            $display("%s[%d][%d][%d]:%0h", name, i, j, k, mat[i][j][k]);
        end
    endfunction    

    //////////////////////////////////////////////////////////////////////////////////////////////
    // function name: print_rcon_col                                                            //
    // parameters:                                                                              //
    //                                                                                          //
    //                                                                                          //
    // description: Print the matrix                                                            //
    //////////////////////////////////////////////////////////////////////////////////////////////
    function void print_rcon_col(logic [7:0] rcon[4:0][9:0], logic [4:0] col=0);
        for(int i=0; i<5; i++) begin
            $display("rcon[%0d][%0d]:%0h", i, col, rcon[i][col]);
        end
    endfunction
endmodule
