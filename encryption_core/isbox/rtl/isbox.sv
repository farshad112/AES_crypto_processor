`timescale 1ns/1ps

module isbox#(
                // parameters
                parameter NO_ROWS = 16,     // Number of Rows in input char matrix
                parameter NO_COLS = 16      // Number of Columns in input char matrix
            )(
                // IO ports
                input logic resetn,                                                     // reset (active low)
                input logic isbox_en,                                                   // enable sbox 
                input logic [7:0] isbox_ip_char_matrix [NO_ROWS-1:0] [NO_COLS-1:0],     // sbox input char matrix
                input logic [NO_ROWS-1:0] isbox_ip_char_row_mask,                       // sbox row enable mask for selecting the rows for sbox substitution
                input logic [NO_COLS-1:0] isbox_ip_char_col_mask,                       // sbox column enable mask for selecting the columns for sbox substitution
                output logic isbox_op_char_matrix_valid,                                // sbox output valid
                output logic [7:0] isbox_op_char_matrix [NO_ROWS-1:0] [NO_COLS-1:0]     // sbox output
            );

    // isbox related variables
    logic [7:0] isbox [15:0] [15:0];     // sbox matrix
    logic [3:0] isbox_row_index;         // sbox row index for substitution 
    logic [3:0] isbox_col_index;         // sbox column index for substitution

    always_comb begin
        if(!resetn) begin
            isbox_op_char_matrix_valid = 0;
            isbox_row_index = 0;
            isbox_col_index = 0;
        end
        else begin
            if(isbox_en) begin
                isbox_op_char_matrix_valid = 1;
                for(logic [4:0] i=0; i<NO_ROWS; i++) begin
                    for(logic [4:0] j=0; j<NO_COLS; j++) begin
                        if(isbox_ip_char_row_mask[i] && isbox_ip_char_col_mask[j]) begin
                            isbox_row_index = isbox_ip_char_matrix[i][j][7:4];
                            isbox_col_index = isbox_ip_char_matrix[i][j][3:0];
                            isbox_op_char_matrix[i][j] = isbox[isbox_row_index][isbox_col_index];
                        end
                        else begin
                            isbox_op_char_matrix[i][j] = 0;
                        end
                    end
                end
            end
            else begin
                isbox_op_char_matrix_valid = 0;
            end
        end
    end

    /*  Inverse SBOX matrix
        hex 00 	01 	02 	03 	04 	05 	06 	07 	08 	09 	0a 	0b 	0c 	0d 	0e 	0f
        00 	52 	09 	6a 	d5 	30 	36 	a5 	38 	bf 	40 	a3 	9e 	81 	f3 	d7 	fb
        10 	7c 	e3 	39 	82 	9b 	2f 	ff 	87 	34 	8e 	43 	44 	c4 	de 	e9 	cb
        20 	54 	7b 	94 	32 	a6 	c2 	23 	3d 	ee 	4c 	95 	0b 	42 	fa 	c3 	4e
        30 	08 	2e 	a1 	66 	28 	d9 	24 	b2 	76 	5b 	a2 	49 	6d 	8b 	d1 	25
        40 	72 	f8 	f6 	64 	86 	68 	98 	16 	d4 	a4 	5c 	cc 	5d 	65 	b6 	92
        50 	6c 	70 	48 	50 	fd 	ed 	b9 	da 	5e 	15 	46 	57 	a7 	8d 	9d 	84
        60 	90 	d8 	ab 	00 	8c 	bc 	d3 	0a 	f7 	e4 	58 	05 	b8 	b3 	45 	06
        70 	d0 	2c 	1e 	8f 	ca 	3f 	0f 	02 	c1 	af 	bd 	03 	01 	13 	8a 	6b
        80 	3a 	91 	11 	41 	4f 	67 	dc 	ea 	97 	f2 	cf 	ce 	f0 	b4 	e6 	73
        90 	96 	ac 	74 	22 	e7 	ad 	35 	85 	e2 	f9 	37 	e8 	1c 	75 	df 	6e
        a0 	47 	f1 	1a 	71 	1d 	29 	c5 	89 	6f 	b7 	62 	0e 	aa 	18 	be 	1b
        b0 	fc 	56 	3e 	4b 	c6 	d2 	79 	20 	9a 	db 	c0 	fe 	78 	cd 	5a 	f4
        c0 	1f 	dd 	a8 	33 	88 	07 	c7 	31 	b1 	12 	10 	59 	27 	80 	ec 	5f
        d0 	60 	51 	7f 	a9 	19 	b5 	4a 	0d 	2d 	e5 	7a 	9f 	93 	c9 	9c 	ef
        e0 	a0 	e0 	3b 	4d 	ae 	2a 	f5 	b0 	c8 	eb 	bb 	3c 	83 	53 	99 	61
        f0 	17 	2b 	04 	7e 	ba 	77 	d6 	26 	e1 	69 	14 	63 	55 	21 	0c 	7d 
    */

    // generate isbox matrix
    assign isbox[8'h0][8'h0] = 16'h52;
    assign isbox[8'h0][8'h1] = 16'h09;
    assign isbox[8'h0][8'h2] = 16'h6a;
    assign isbox[8'h0][8'h3] = 16'hd5; 
    assign isbox[8'h0][8'h4] = 16'h30;
    assign isbox[8'h0][8'h5] = 16'h36;
    assign isbox[8'h0][8'h6] = 16'ha5;
    assign isbox[8'h0][8'h7] = 16'h38;
    assign isbox[8'h0][8'h8] = 16'hbf;
    assign isbox[8'h0][8'h9] = 16'h40;
    assign isbox[8'h0][8'hA] = 16'ha3;
    assign isbox[8'h0][8'hB] = 16'h9e; 
    assign isbox[8'h0][8'hC] = 16'h81;
    assign isbox[8'h0][8'hD] = 16'hf3;
    assign isbox[8'h0][8'hE] = 16'hd7;
    assign isbox[8'h0][8'hF] = 16'hfb;

    assign isbox[8'h1][8'h0] = 16'h7c; 
    assign isbox[8'h1][8'h1] = 16'he3;
    assign isbox[8'h1][8'h2] = 16'h39;
    assign isbox[8'h1][8'h3] = 16'h82;
    assign isbox[8'h1][8'h4] = 16'h9b;
    assign isbox[8'h1][8'h5] = 16'h2f;
    assign isbox[8'h1][8'h6] = 16'hff;
    assign isbox[8'h1][8'h7] = 16'h87;
    assign isbox[8'h1][8'h8] = 16'h34;
    assign isbox[8'h1][8'h9] = 16'h8e;
    assign isbox[8'h1][8'hA] = 16'h43;
    assign isbox[8'h1][8'hB] = 16'h44; 
    assign isbox[8'h1][8'hC] = 16'hc4;
    assign isbox[8'h1][8'hD] = 16'hde;
    assign isbox[8'h1][8'hE] = 16'he9;
    assign isbox[8'h1][8'hF] = 16'hcb;

    assign isbox[8'h2][8'h0] = 16'h54; 
    assign isbox[8'h2][8'h1] = 16'h7b;
    assign isbox[8'h2][8'h2] = 16'h94;
    assign isbox[8'h2][8'h3] = 16'h32;
    assign isbox[8'h2][8'h4] = 16'ha6;
    assign isbox[8'h2][8'h5] = 16'hc2;
    assign isbox[8'h2][8'h6] = 16'h23;
    assign isbox[8'h2][8'h7] = 16'h3d;
    assign isbox[8'h2][8'h8] = 16'hee;
    assign isbox[8'h2][8'h9] = 16'h4c;
    assign isbox[8'h2][8'hA] = 16'h95;
    assign isbox[8'h2][8'hB] = 16'h0b; 
    assign isbox[8'h2][8'hC] = 16'h42;
    assign isbox[8'h2][8'hD] = 16'hfa;
    assign isbox[8'h2][8'hE] = 16'hc3;
    assign isbox[8'h2][8'hF] = 16'h4e;

    assign isbox[8'h3][8'h0] = 16'h08; 
    assign isbox[8'h3][8'h1] = 16'h2e;
    assign isbox[8'h3][8'h2] = 16'ha1;
    assign isbox[8'h3][8'h3] = 16'h66;
    assign isbox[8'h3][8'h4] = 16'h28;
    assign isbox[8'h3][8'h5] = 16'hd9;
    assign isbox[8'h3][8'h6] = 16'h24;
    assign isbox[8'h3][8'h7] = 16'hb2;
    assign isbox[8'h3][8'h8] = 16'h76;
    assign isbox[8'h3][8'h9] = 16'h5b;
    assign isbox[8'h3][8'hA] = 16'ha2;
    assign isbox[8'h3][8'hB] = 16'h49; 
    assign isbox[8'h3][8'hC] = 16'h6d;
    assign isbox[8'h3][8'hD] = 16'h8b;
    assign isbox[8'h3][8'hE] = 16'hd1;
    assign isbox[8'h3][8'hF] = 16'h25;

    assign isbox[8'h4][8'h0] = 16'h72; 
    assign isbox[8'h4][8'h1] = 16'hf8;
    assign isbox[8'h4][8'h2] = 16'hf6;
    assign isbox[8'h4][8'h3] = 16'h64;
    assign isbox[8'h4][8'h4] = 16'h86;
    assign isbox[8'h4][8'h5] = 16'h68;
    assign isbox[8'h4][8'h6] = 16'h98;
    assign isbox[8'h4][8'h7] = 16'h16;
    assign isbox[8'h4][8'h8] = 16'hd4;
    assign isbox[8'h4][8'h9] = 16'ha4;
    assign isbox[8'h4][8'hA] = 16'h5c;
    assign isbox[8'h4][8'hB] = 16'hcc; 
    assign isbox[8'h4][8'hC] = 16'h5d;
    assign isbox[8'h4][8'hD] = 16'h65;
    assign isbox[8'h4][8'hE] = 16'hb6;
    assign isbox[8'h4][8'hF] = 16'h92;
      
    assign isbox[8'h5][8'h0] = 16'h6c; 
    assign isbox[8'h5][8'h1] = 16'h70;
    assign isbox[8'h5][8'h2] = 16'h48;
    assign isbox[8'h5][8'h3] = 16'h50;
    assign isbox[8'h5][8'h4] = 16'hfd;
    assign isbox[8'h5][8'h5] = 16'hed;
    assign isbox[8'h5][8'h6] = 16'hb9;
    assign isbox[8'h5][8'h7] = 16'hda;
    assign isbox[8'h5][8'h8] = 16'h5e;
    assign isbox[8'h5][8'h9] = 16'h15;
    assign isbox[8'h5][8'hA] = 16'h46;
    assign isbox[8'h5][8'hB] = 16'h57; 
    assign isbox[8'h5][8'hC] = 16'ha7;
    assign isbox[8'h5][8'hD] = 16'h8d;
    assign isbox[8'h5][8'hE] = 16'h9d;
    assign isbox[8'h5][8'hF] = 16'h84;
 	
    assign isbox[8'h6][8'h0] = 16'h90; 
    assign isbox[8'h6][8'h1] = 16'hd8;
    assign isbox[8'h6][8'h2] = 16'hab;
    assign isbox[8'h6][8'h3] = 16'h00;
    assign isbox[8'h6][8'h4] = 16'h8c;
    assign isbox[8'h6][8'h5] = 16'hbc;
    assign isbox[8'h6][8'h6] = 16'hd3;
    assign isbox[8'h6][8'h7] = 16'h0a;
    assign isbox[8'h6][8'h8] = 16'hf7;
    assign isbox[8'h6][8'h9] = 16'he4;
    assign isbox[8'h6][8'hA] = 16'h58;
    assign isbox[8'h6][8'hB] = 16'h05; 
    assign isbox[8'h6][8'hC] = 16'hb8;
    assign isbox[8'h6][8'hD] = 16'hb3;
    assign isbox[8'h6][8'hE] = 16'h45;
    assign isbox[8'h6][8'hF] = 16'h06;
 		
    assign isbox[8'h7][8'h0] = 16'hd0; 
    assign isbox[8'h7][8'h1] = 16'h2c;
    assign isbox[8'h7][8'h2] = 16'h1e;
    assign isbox[8'h7][8'h3] = 16'h8f;
    assign isbox[8'h7][8'h4] = 16'hca;
    assign isbox[8'h7][8'h5] = 16'h3f;
    assign isbox[8'h7][8'h6] = 16'h0f;
    assign isbox[8'h7][8'h7] = 16'h02;
    assign isbox[8'h7][8'h8] = 16'hc1;
    assign isbox[8'h7][8'h9] = 16'haf;
    assign isbox[8'h7][8'hA] = 16'hbd;
    assign isbox[8'h7][8'hB] = 16'h03; 
    assign isbox[8'h7][8'hC] = 16'h01;
    assign isbox[8'h7][8'hD] = 16'h13;
    assign isbox[8'h7][8'hE] = 16'h8a;
    assign isbox[8'h7][8'hF] = 16'h6b;

    assign isbox[8'h8][8'h0] = 16'h3a; 
    assign isbox[8'h8][8'h1] = 16'h91;
    assign isbox[8'h8][8'h2] = 16'h11;
    assign isbox[8'h8][8'h3] = 16'h41;
    assign isbox[8'h8][8'h4] = 16'h4f;
    assign isbox[8'h8][8'h5] = 16'h67;
    assign isbox[8'h8][8'h6] = 16'hdc;
    assign isbox[8'h8][8'h7] = 16'hea;
    assign isbox[8'h8][8'h8] = 16'h97;
    assign isbox[8'h8][8'h9] = 16'hf2;
    assign isbox[8'h8][8'hA] = 16'hcf;
    assign isbox[8'h8][8'hB] = 16'hce; 
    assign isbox[8'h8][8'hC] = 16'hf0;
    assign isbox[8'h8][8'hD] = 16'hb4;
    assign isbox[8'h8][8'hE] = 16'he6;
    assign isbox[8'h8][8'hF] = 16'h73;
 	
    assign isbox[8'h9][8'h0] = 16'h96; 
    assign isbox[8'h9][8'h1] = 16'hac;
    assign isbox[8'h9][8'h2] = 16'h74;
    assign isbox[8'h9][8'h3] = 16'h22;
    assign isbox[8'h9][8'h4] = 16'he7;
    assign isbox[8'h9][8'h5] = 16'had;
    assign isbox[8'h9][8'h6] = 16'h35;
    assign isbox[8'h9][8'h7] = 16'h85;
    assign isbox[8'h9][8'h8] = 16'he2;
    assign isbox[8'h9][8'h9] = 16'hf9;
    assign isbox[8'h9][8'hA] = 16'h37;
    assign isbox[8'h9][8'hB] = 16'he8; 
    assign isbox[8'h9][8'hC] = 16'h1c;
    assign isbox[8'h9][8'hD] = 16'h75;
    assign isbox[8'h9][8'hE] = 16'hdf;
    assign isbox[8'h9][8'hF] = 16'h6e;
 	
    assign isbox[8'hA][8'h0] = 16'h47; 
    assign isbox[8'hA][8'h1] = 16'hf1;
    assign isbox[8'hA][8'h2] = 16'h1a;
    assign isbox[8'hA][8'h3] = 16'h71;
    assign isbox[8'hA][8'h4] = 16'h1d;
    assign isbox[8'hA][8'h5] = 16'h29;
    assign isbox[8'hA][8'h6] = 16'hc5;
    assign isbox[8'hA][8'h7] = 16'h89;
    assign isbox[8'hA][8'h8] = 16'h6f;
    assign isbox[8'hA][8'h9] = 16'hb7;
    assign isbox[8'hA][8'hA] = 16'h62;
    assign isbox[8'hA][8'hB] = 16'h0e; 
    assign isbox[8'hA][8'hC] = 16'haa;
    assign isbox[8'hA][8'hD] = 16'h18;
    assign isbox[8'hA][8'hE] = 16'hbe;
    assign isbox[8'hA][8'hF] = 16'h1b;

    assign isbox[8'hB][8'h0] = 16'hfc; 
    assign isbox[8'hB][8'h1] = 16'h56;
    assign isbox[8'hB][8'h2] = 16'h3e;
    assign isbox[8'hB][8'h3] = 16'h4b;
    assign isbox[8'hB][8'h4] = 16'hc6;
    assign isbox[8'hB][8'h5] = 16'hd2;
    assign isbox[8'hB][8'h6] = 16'h79;
    assign isbox[8'hB][8'h7] = 16'h20;
    assign isbox[8'hB][8'h8] = 16'h9a;
    assign isbox[8'hB][8'h9] = 16'hdb;
    assign isbox[8'hB][8'hA] = 16'hc0;
    assign isbox[8'hB][8'hB] = 16'hfe; 
    assign isbox[8'hB][8'hC] = 16'h78;
    assign isbox[8'hB][8'hD] = 16'hcd;
    assign isbox[8'hB][8'hE] = 16'h5a;
    assign isbox[8'hB][8'hF] = 16'hf4;

    assign isbox[8'hC][8'h0] = 16'h1f; 
    assign isbox[8'hC][8'h1] = 16'hdd;
    assign isbox[8'hC][8'h2] = 16'ha8;
    assign isbox[8'hC][8'h3] = 16'h33;
    assign isbox[8'hC][8'h4] = 16'h88;
    assign isbox[8'hC][8'h5] = 16'h07;
    assign isbox[8'hC][8'h6] = 16'hc7;
    assign isbox[8'hC][8'h7] = 16'h31;
    assign isbox[8'hC][8'h8] = 16'hb1;
    assign isbox[8'hC][8'h9] = 16'h12;
    assign isbox[8'hC][8'hA] = 16'h10;
    assign isbox[8'hC][8'hB] = 16'h59; 
    assign isbox[8'hC][8'hC] = 16'h27;
    assign isbox[8'hC][8'hD] = 16'h80;
    assign isbox[8'hC][8'hE] = 16'hec;
    assign isbox[8'hC][8'hF] = 16'h5f;
 	
    assign isbox[8'hD][8'h0] = 16'h60; 
    assign isbox[8'hD][8'h1] = 16'h51;
    assign isbox[8'hD][8'h2] = 16'h7f;
    assign isbox[8'hD][8'h3] = 16'ha9;
    assign isbox[8'hD][8'h4] = 16'h19;
    assign isbox[8'hD][8'h5] = 16'hb5;
    assign isbox[8'hD][8'h6] = 16'h4a;
    assign isbox[8'hD][8'h7] = 16'h0d;
    assign isbox[8'hD][8'h8] = 16'h2d;
    assign isbox[8'hD][8'h9] = 16'he5;
    assign isbox[8'hD][8'hA] = 16'h7a;
    assign isbox[8'hD][8'hB] = 16'h9f; 
    assign isbox[8'hD][8'hC] = 16'h93;
    assign isbox[8'hD][8'hD] = 16'hc9;
    assign isbox[8'hD][8'hE] = 16'h9c;
    assign isbox[8'hD][8'hF] = 16'hef;	

    assign isbox[8'hE][8'h0] = 16'ha0; 
    assign isbox[8'hE][8'h1] = 16'he0;
    assign isbox[8'hE][8'h2] = 16'h3b;
    assign isbox[8'hE][8'h3] = 16'h4d;
    assign isbox[8'hE][8'h4] = 16'hae;
    assign isbox[8'hE][8'h5] = 16'h2a;
    assign isbox[8'hE][8'h6] = 16'hf5;
    assign isbox[8'hE][8'h7] = 16'hb0;
    assign isbox[8'hE][8'h8] = 16'hc8;
    assign isbox[8'hE][8'h9] = 16'heb;
    assign isbox[8'hE][8'hA] = 16'hbb;
    assign isbox[8'hE][8'hB] = 16'h3c; 
    assign isbox[8'hE][8'hC] = 16'h83;
    assign isbox[8'hE][8'hD] = 16'h53;
    assign isbox[8'hE][8'hE] = 16'h99;
    assign isbox[8'hE][8'hF] = 16'h61;

    assign isbox[8'hF][8'h0] = 16'h17; 
    assign isbox[8'hF][8'h1] = 16'h2b;
    assign isbox[8'hF][8'h2] = 16'h04;
    assign isbox[8'hF][8'h3] = 16'h7e;
    assign isbox[8'hF][8'h4] = 16'hba;
    assign isbox[8'hF][8'h5] = 16'h77;
    assign isbox[8'hF][8'h6] = 16'hd6;
    assign isbox[8'hF][8'h7] = 16'h26;
    assign isbox[8'hF][8'h8] = 16'he1;
    assign isbox[8'hF][8'h9] = 16'h69;
    assign isbox[8'hF][8'hA] = 16'h14;
    assign isbox[8'hF][8'hB] = 16'h63; 
    assign isbox[8'hF][8'hC] = 16'h55;
    assign isbox[8'hF][8'hD] = 16'h21;
    assign isbox[8'hF][8'hE] = 16'h0c;
    assign isbox[8'hF][8'hF] = 16'h7d;
endmodule