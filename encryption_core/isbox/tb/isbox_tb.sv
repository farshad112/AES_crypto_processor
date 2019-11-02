`timescale 1ns/1ps

module isbox_tb;
    logic resetn;
    logic [15:0] isbox_ip_char_matrix[15:0][15:0];
    logic [15:0] isbox_ip_char_row_mask;
    logic isbox_op_char_matrix_valid;
    logic [15:0] isbox_op_char_matrix [15:0] [15:0];

    // Instantiation of DUT
    isbox DUT(
                .resetn(resetn),
                .isbox_ip_char_matrix(isbox_ip_char_matrix),
                .isbox_ip_char_row_mask(isbox_ip_char_row_mask),
                .isbox_op_char_matrix_valid(isbox_op_char_matrix_valid),
                .isbox_op_char_matrix(isbox_op_char_matrix)
    );

    initial begin
        resetn = 0;
        isbox_ip_char_row_mask = 0;
        foreach(isbox_ip_char_matrix[i,j]) begin
            isbox_ip_char_matrix[i][j] = 0;
        end   
        #20ns;
        resetn = 1;
        isbox_ip_char_row_mask = 16'hFFFF;
        foreach(isbox_ip_char_matrix[i,j]) begin
            isbox_ip_char_matrix[i][j] = 10*i+j;
        end
        #40ns;
        isbox_ip_char_row_mask = 16'h1;
        foreach(isbox_ip_char_matrix[i,j]) begin
            isbox_ip_char_matrix[i][j] = 10*i+j;
        end 
        #40ns;
        $finish();
    end
endmodule
