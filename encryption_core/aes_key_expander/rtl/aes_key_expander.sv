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
                            input logic [3:0] key_sel,
                            output logic key_rdy,
                            output logic [7:0] round_key[3:0][3:0]
                        );
    
    // round constant matrix
    logic [7:0] rcon_matrix [4:0] [9:0];

    // register for holding round keys
    logic [7:0] round_key_matrix [3:0] [3:0][9:0];

    // counter and control flags for round key generation
    logic key_gen_done;
    logic [3:0] key_counter;

    // key gen algorithm related registers 
    logic [7:0] root_word [3:0];
    logic [7:0] shifted_root_word [3:0];
    logic [7:0] sb_root_word[3:0];
    logic [2:0] root_word_index;

    // sbox related signals
    logic sbox_en;
    

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

            // reset round key matrix
            foreach(round_key_matrix[i,j,k]) begin
                round_key_matrix[i][j][k] = 0;
            end
        end
        else begin
            if(encrypt_en) begin
                if(!key_gen_done) begin
                    if(key_counter == 0) begin
                        // get root word from cipher key
                        for(logic [2:0] i=0; i<4; i++) begin
                            root_word[i] = cipher_key[3][i];
                        end
                        $display("root_word:%p", root_word);
                        // perform shift operation on root word
                        shift_root_word(root_word, shifted_root_word);

                        // increment the key counter for round 2 key generation
                        key_counter +=1;
                    end
                    else if(key_counter == 1) begin
                        $display("round 1 key generation ..");
                    end
                end
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
/*
    // Instantiation of SBOX module
    sbox#(
            // parameters
            .NO_ROWS(SBOX_ROW_NO),
            .NO_COLS(SBOX_COL_NO)
        ) I_AES_KEY_GEN_SBOX(
            // IO ports
            .resetn(resetn),
            .sbox_en(sbox_en),
            .sbox_ip_char_matrix(root_word),
            .sbox_ip_char_row_mask(),
            .sbox_ip_char_col_mask(),
            .sbox_op_char_matrix_valid(),
            .sbox_op_char_matrix()
        );
*/

    ////////////////////////////////////////////////////// functions ///////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////
    // function name: shift_root_word                                                           //
    // parameters:                                                                              //
    //              -> logic [7:0] root_word [3:0] : root word matrix                           //
    //              -> ref logic [7:0] shifted_root_word [3:0] : shifted root word matrix       //
    // description: Perform shift operation on root_word                                        //
    //////////////////////////////////////////////////////////////////////////////////////////////
    function automatic void shift_root_word(logic [7:0] root_word [3:0], ref logic [7:0] shifted_root_word [3:0]);
        begin
            logic [1:0] root_word_index;
            logic [1:0] shifted_root_word_index;
            shifted_root_word_index = 3;

            for(root_word_index=0; root_word_index<4; root_word_index++) begin
                shifted_root_word[shifted_root_word_index] = root_word[root_word_index];
                shifted_root_word_index += 1; 
                $display("FROM FUNC :: shift_root_word :: shifted_root_word_index:%0d, root_word_index: %0d", shifted_root_word_index, root_word_index);   
            end
        end
    endfunction
endmodule
