`timescale 1ns/1ps

module sbox_tb;
    logic resetn;
    logic [15:0] sbox_ip_char_matrix[15:0][15:0];
    logic [15:0] sbox_ip_char_row_mask;
    logic sbox_op_char_matrix_valid;
    logic [15:0] sbox_op_char_matrix [15:0] [15:0];

    // Instantiation of DUT
    sbox DUT(
                .resetn(resetn),
                .sbox_ip_char_matrix(sbox_ip_char_matrix),
                .sbox_ip_char_row_mask(sbox_ip_char_row_mask),
                .sbox_op_char_matrix_valid(sbox_op_char_matrix_valid),
                .sbox_op_char_matrix(sbox_op_char_matrix)
    );

    initial begin
        resetn = 0;
        sbox_ip_char_row_mask = 0;
        foreach(sbox_ip_char_matrix[i,j]) begin
            sbox_ip_char_matrix[i][j] = 0;
        end   
        #20ns;
        resetn = 1;
        sbox_ip_char_row_mask = 16'hFFFF;
        foreach(sbox_ip_char_matrix[i,j]) begin
            sbox_ip_char_matrix[i][j] = 10*i+j;
        end
        #40ns;
        sbox_ip_char_row_mask = 16'h1;
        foreach(sbox_ip_char_matrix[i,j]) begin
            sbox_ip_char_matrix[i][j] = 10*i+j;
        end 
        #40ns;
        $finish();
    end
endmodule