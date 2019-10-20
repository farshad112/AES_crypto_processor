`timescale 1ns/1ps

module sbox#(
                // parameters
                parameter NO_ROWS = 16,     // Number of Rows in input char matrix
                parameter NO_COLS = 16      // Number of Columns in input char matrix
            )(
                // IO ports
                input logic resetn,                                                     // reset (active low)
                input logic sbox_en,                                                    // enable sbox 
                input logic [7:0] sbox_ip_char_matrix [NO_ROWS-1:0] [NO_COLS-1:0],      // sbox input char matrix
                input logic [NO_ROWS-1:0] sbox_ip_char_row_mask,                        // sbox row enable mask for selecting the rows for sbox substitution
                input logic [NO_COLS-1:0] sbox_ip_char_col_mask,                        // sbox column enable mask for selecting the columns for sbox substitution
                output logic sbox_op_char_matrix_valid,                                 // sbox output valid
                output logic [7:0] sbox_op_char_matrix [NO_ROWS-1:0] [NO_COLS-1:0]     // sbox output
            );

    // sbox related variables
    logic [7:0] sbox [15:0] [15:0];     // sbox matrix
    logic [3:0] sbox_row_index;         // sbox row index for substitution 
    logic [3:0] sbox_col_index;         // sbox column index for substitution

    always_comb begin
        if(!resetn) begin
            sbox_op_char_matrix_valid = 0;
            sbox_row_index = 0;
            sbox_col_index = 0;
        end
        else begin
            if(sbox_en) begin
                sbox_op_char_matrix_valid = 1;
                for(logic [4:0] i=0; i<NO_ROWS; i++) begin
                    for(logic [4:0] j=0; j<NO_COLS; j++) begin
                        if(sbox_ip_char_row_mask[i] && sbox_ip_char_col_mask[j]) begin
                            sbox_row_index = sbox_ip_char_matrix[i][j][7:4];
                            sbox_col_index = sbox_ip_char_matrix[i][j][3:0];
                            sbox_op_char_matrix[i][j] = sbox[sbox_row_index][sbox_col_index];
                        end
                        else begin
                            sbox_op_char_matrix[i][j] = 0;
                        end
                    end
                end
            end
            else begin
                sbox_op_char_matrix_valid = 0;
            end
        end
    end    

    /*   
        SBOX MATRIX
        hex	00	01	02	03	04	05	06	07	08	09	0a	0b	0c	0d	0e	0f
        00	63	7c	77	7b	f2	6b	6f	c5	30	01	67	2b	fe	d7	ab	76
        10	ca	82	c9	7d	fa	59	47	f0	ad	d4	a2	af	9c	a4	72	c0
        20	b7	fd	93	26	36	3f	f7	cc	34	a5	e5	f1	71	d8	31	15
        30	04	c7	23	c3	18	96	05	9a	07	12	80	e2	eb	27	b2	75
        40	09	83	2c	1a	1b	6e	5a	a0	52	3b	d6	b3	29	e3	2f	84
        50	53	d1	00	ed	20	fc	b1	5b	6a	cb	be	39	4a	4c	58	cf
        60	d0	ef	aa	fb	43	4d	33	85	45	f9	02	7f	50	3c	9f	a8
        70	51	a3	40	8f	92	9d	38	f5	bc	b6	da	21	10	ff	f3	d2
        80	cd	0c	13	ec	5f	97	44	17	c4	a7	7e	3d	64	5d	19	73
        90	60	81	4f	dc	22	2a	90	88	46	ee	b8	14	de	5e	0b	db
        a0	e0	32	3a	0a	49	06	24	5c	c2	d3	ac	62	91	95	e4	79
        b0	e7	c8	37	6d	8d	d5	4e	a9	6c	56	f4	ea	65	7a	ae	08
        c0	ba	78	25	2e	1c	a6	b4	c6	e8	dd	74	1f	4b	bd	8b	8a
        d0	70	3e	b5	66	48	03	f6	0e	61	35	57	b9	86	c1	1d	9e
        e0	e1	f8	98	11	69	d9	8e	94	9b	1e	87	e9	ce	55	28	df
        f0	8c	a1	89	0d	bf	e6	42	68	41	99	2d	0f	b0	54	bb	16
    */

    // generate sbox matrix
    assign sbox[8'h0][8'h0] = 16'h63;
    assign sbox[8'h0][8'h1] = 16'h7c;
    assign sbox[8'h0][8'h2] = 16'h77;
    assign sbox[8'h0][8'h3] = 16'h7b; 
    assign sbox[8'h0][8'h4] = 16'hf2;
    assign sbox[8'h0][8'h5] = 16'h6b;
    assign sbox[8'h0][8'h6] = 16'h6f;
    assign sbox[8'h0][8'h7] = 16'hc5;
    assign sbox[8'h0][8'h8] = 16'h30;
    assign sbox[8'h0][8'h9] = 16'h01;
    assign sbox[8'h0][8'hA] = 16'h67;
    assign sbox[8'h0][8'hB] = 16'h2b; 
    assign sbox[8'h0][8'hC] = 16'hfe;
    assign sbox[8'h0][8'hD] = 16'hd7;
    assign sbox[8'h0][8'hE] = 16'hab;
    assign sbox[8'h0][8'hF] = 16'h76;

    assign sbox[8'h1][8'h0] = 16'hca; 
    assign sbox[8'h1][8'h1] = 16'h82;
    assign sbox[8'h1][8'h2] = 16'hc9;
    assign sbox[8'h1][8'h3] = 16'h7d;
    assign sbox[8'h1][8'h4] = 16'hfa;
    assign sbox[8'h1][8'h5] = 16'h59;
    assign sbox[8'h1][8'h6] = 16'h47;
    assign sbox[8'h1][8'h7] = 16'hf0;
    assign sbox[8'h1][8'h8] = 16'had;
    assign sbox[8'h1][8'h9] = 16'hd4;
    assign sbox[8'h1][8'hA] = 16'ha2;
    assign sbox[8'h1][8'hB] = 16'haf; 
    assign sbox[8'h1][8'hC] = 16'h9c;
    assign sbox[8'h1][8'hD] = 16'ha4;
    assign sbox[8'h1][8'hE] = 16'h72;
    assign sbox[8'h1][8'hF] = 16'hc0;

    assign sbox[8'h2][8'h0] = 16'hb7; 
    assign sbox[8'h2][8'h1] = 16'hfd;
    assign sbox[8'h2][8'h2] = 16'h93;
    assign sbox[8'h2][8'h3] = 16'h26;
    assign sbox[8'h2][8'h4] = 16'h36;
    assign sbox[8'h2][8'h5] = 16'h3f;
    assign sbox[8'h2][8'h6] = 16'hf7;
    assign sbox[8'h2][8'h7] = 16'hcc;
    assign sbox[8'h2][8'h8] = 16'h34;
    assign sbox[8'h2][8'h9] = 16'ha5;
    assign sbox[8'h2][8'hA] = 16'he5;
    assign sbox[8'h2][8'hB] = 16'hf1; 
    assign sbox[8'h2][8'hC] = 16'h71;
    assign sbox[8'h2][8'hD] = 16'hd8;
    assign sbox[8'h2][8'hE] = 16'h31;
    assign sbox[8'h2][8'hF] = 16'h15;

    assign sbox[8'h3][8'h0] = 16'h04; 
    assign sbox[8'h3][8'h1] = 16'hc7;
    assign sbox[8'h3][8'h2] = 16'h23;
    assign sbox[8'h3][8'h3] = 16'hc3;
    assign sbox[8'h3][8'h4] = 16'h18;
    assign sbox[8'h3][8'h5] = 16'h96;
    assign sbox[8'h3][8'h6] = 16'h05;
    assign sbox[8'h3][8'h7] = 16'h9a;
    assign sbox[8'h3][8'h8] = 16'h07;
    assign sbox[8'h3][8'h9] = 16'h12;
    assign sbox[8'h3][8'hA] = 16'h80;
    assign sbox[8'h3][8'hB] = 16'he2; 
    assign sbox[8'h3][8'hC] = 16'heb;
    assign sbox[8'h3][8'hD] = 16'h27;
    assign sbox[8'h3][8'hE] = 16'hb2;
    assign sbox[8'h3][8'hF] = 16'h75;

    assign sbox[8'h4][8'h0] = 16'h09; 
    assign sbox[8'h4][8'h1] = 16'h83;
    assign sbox[8'h4][8'h2] = 16'h2c;
    assign sbox[8'h4][8'h3] = 16'h1a;
    assign sbox[8'h4][8'h4] = 16'h1b;
    assign sbox[8'h4][8'h5] = 16'h6e;
    assign sbox[8'h4][8'h6] = 16'h5a;
    assign sbox[8'h4][8'h7] = 16'ha0;
    assign sbox[8'h4][8'h8] = 16'h52;
    assign sbox[8'h4][8'h9] = 16'h3b;
    assign sbox[8'h4][8'hA] = 16'hd6;
    assign sbox[8'h4][8'hB] = 16'hb3; 
    assign sbox[8'h4][8'hC] = 16'h29;
    assign sbox[8'h4][8'hD] = 16'he3;
    assign sbox[8'h4][8'hE] = 16'h2f;
    assign sbox[8'h4][8'hF] = 16'h84;

    assign sbox[8'h5][8'h0] = 16'h53; 
    assign sbox[8'h5][8'h1] = 16'hd1;
    assign sbox[8'h5][8'h2] = 16'h00;
    assign sbox[8'h5][8'h3] = 16'hed;
    assign sbox[8'h5][8'h4] = 16'h20;
    assign sbox[8'h5][8'h5] = 16'hfc;
    assign sbox[8'h5][8'h6] = 16'hb1;
    assign sbox[8'h5][8'h7] = 16'h5b;
    assign sbox[8'h5][8'h8] = 16'h6a;
    assign sbox[8'h5][8'h9] = 16'hcb;
    assign sbox[8'h5][8'hA] = 16'hbe;
    assign sbox[8'h5][8'hB] = 16'h39; 
    assign sbox[8'h5][8'hC] = 16'h4a;
    assign sbox[8'h5][8'hD] = 16'h4c;
    assign sbox[8'h5][8'hE] = 16'h58;
    assign sbox[8'h5][8'hF] = 16'hcf;

    assign sbox[8'h6][8'h0] = 16'hd0; 
    assign sbox[8'h6][8'h1] = 16'hef;
    assign sbox[8'h6][8'h2] = 16'haa;
    assign sbox[8'h6][8'h3] = 16'hfb;
    assign sbox[8'h6][8'h4] = 16'h43;
    assign sbox[8'h6][8'h5] = 16'h4d;
    assign sbox[8'h6][8'h6] = 16'h33;
    assign sbox[8'h6][8'h7] = 16'h85;
    assign sbox[8'h6][8'h8] = 16'h45;
    assign sbox[8'h6][8'h9] = 16'hf9;
    assign sbox[8'h6][8'hA] = 16'h02;
    assign sbox[8'h6][8'hB] = 16'h7f; 
    assign sbox[8'h6][8'hC] = 16'h50;
    assign sbox[8'h6][8'hD] = 16'h3c;
    assign sbox[8'h6][8'hE] = 16'h9f;
    assign sbox[8'h6][8'hF] = 16'ha8;

    assign sbox[8'h7][8'h0] = 16'h51; 
    assign sbox[8'h7][8'h1] = 16'ha3;
    assign sbox[8'h7][8'h2] = 16'h40;
    assign sbox[8'h7][8'h3] = 16'h8f;
    assign sbox[8'h7][8'h4] = 16'h92;
    assign sbox[8'h7][8'h5] = 16'h9d;
    assign sbox[8'h7][8'h6] = 16'h38;
    assign sbox[8'h7][8'h7] = 16'hf5;
    assign sbox[8'h7][8'h8] = 16'hbc;
    assign sbox[8'h7][8'h9] = 16'hb6;
    assign sbox[8'h7][8'hA] = 16'hda;
    assign sbox[8'h7][8'hB] = 16'h21; 
    assign sbox[8'h7][8'hC] = 16'h10;
    assign sbox[8'h7][8'hD] = 16'hff;
    assign sbox[8'h7][8'hE] = 16'hf3;
    assign sbox[8'h7][8'hF] = 16'hd2;

    assign sbox[8'h8][8'h0] = 16'hcd; 
    assign sbox[8'h8][8'h1] = 16'h0c;
    assign sbox[8'h8][8'h2] = 16'h13;
    assign sbox[8'h8][8'h3] = 16'hec;
    assign sbox[8'h8][8'h4] = 16'h5f;
    assign sbox[8'h8][8'h5] = 16'h97;
    assign sbox[8'h8][8'h6] = 16'h44;
    assign sbox[8'h8][8'h7] = 16'h17;
    assign sbox[8'h8][8'h8] = 16'hc4;
    assign sbox[8'h8][8'h9] = 16'ha7;
    assign sbox[8'h8][8'hA] = 16'h7e;
    assign sbox[8'h8][8'hB] = 16'h3d; 
    assign sbox[8'h8][8'hC] = 16'h64;
    assign sbox[8'h8][8'hD] = 16'h5d;
    assign sbox[8'h8][8'hE] = 16'h19;
    assign sbox[8'h8][8'hF] = 16'h73;

    assign sbox[8'h9][8'h0] = 16'h60; 
    assign sbox[8'h9][8'h1] = 16'h81;
    assign sbox[8'h9][8'h2] = 16'h4f;
    assign sbox[8'h9][8'h3] = 16'hdc;
    assign sbox[8'h9][8'h4] = 16'h22;
    assign sbox[8'h9][8'h5] = 16'h2a;
    assign sbox[8'h9][8'h6] = 16'h90;
    assign sbox[8'h9][8'h7] = 16'h88;
    assign sbox[8'h9][8'h8] = 16'h46;
    assign sbox[8'h9][8'h9] = 16'hee;
    assign sbox[8'h9][8'hA] = 16'hb8;
    assign sbox[8'h9][8'hB] = 16'h14; 
    assign sbox[8'h9][8'hC] = 16'hde;
    assign sbox[8'h9][8'hD] = 16'h5e;
    assign sbox[8'h9][8'hE] = 16'h0b;
    assign sbox[8'h9][8'hF] = 16'hdb;

    assign sbox[8'hA][8'h0] = 16'he0; 
    assign sbox[8'hA][8'h1] = 16'h32;
    assign sbox[8'hA][8'h2] = 16'h3a;
    assign sbox[8'hA][8'h3] = 16'h0a;
    assign sbox[8'hA][8'h4] = 16'h49;
    assign sbox[8'hA][8'h5] = 16'h06;
    assign sbox[8'hA][8'h6] = 16'h24;
    assign sbox[8'hA][8'h7] = 16'h5c;
    assign sbox[8'hA][8'h8] = 16'hc2;
    assign sbox[8'hA][8'h9] = 16'hd3;
    assign sbox[8'hA][8'hA] = 16'hac;
    assign sbox[8'hA][8'hB] = 16'h62; 
    assign sbox[8'hA][8'hC] = 16'h91;
    assign sbox[8'hA][8'hD] = 16'h95;
    assign sbox[8'hA][8'hE] = 16'he4;
    assign sbox[8'hA][8'hF] = 16'h79;

    assign sbox[8'hB][8'h0] = 16'he7; 
    assign sbox[8'hB][8'h1] = 16'hc8;
    assign sbox[8'hB][8'h2] = 16'h37;
    assign sbox[8'hB][8'h3] = 16'h6d;
    assign sbox[8'hB][8'h4] = 16'h8d;
    assign sbox[8'hB][8'h5] = 16'hd5;
    assign sbox[8'hB][8'h6] = 16'h4e;
    assign sbox[8'hB][8'h7] = 16'ha9;
    assign sbox[8'hB][8'h8] = 16'h6c;
    assign sbox[8'hB][8'h9] = 16'h56;
    assign sbox[8'hB][8'hA] = 16'hf4;
    assign sbox[8'hB][8'hB] = 16'hea; 
    assign sbox[8'hB][8'hC] = 16'h65;
    assign sbox[8'hB][8'hD] = 16'h7a;
    assign sbox[8'hB][8'hE] = 16'hae;
    assign sbox[8'hB][8'hF] = 16'h08;

    assign sbox[8'hC][8'h0] = 16'hba; 
    assign sbox[8'hC][8'h1] = 16'h78;
    assign sbox[8'hC][8'h2] = 16'h25;
    assign sbox[8'hC][8'h3] = 16'h2e;
    assign sbox[8'hC][8'h4] = 16'h1c;
    assign sbox[8'hC][8'h5] = 16'ha6;
    assign sbox[8'hC][8'h6] = 16'hb4;
    assign sbox[8'hC][8'h7] = 16'hc6;
    assign sbox[8'hC][8'h8] = 16'he8;
    assign sbox[8'hC][8'h9] = 16'hdd;
    assign sbox[8'hC][8'hA] = 16'h74;
    assign sbox[8'hC][8'hB] = 16'h1f; 
    assign sbox[8'hC][8'hC] = 16'h4b;
    assign sbox[8'hC][8'hD] = 16'hbd;
    assign sbox[8'hC][8'hE] = 16'h8b;
    assign sbox[8'hC][8'hF] = 16'h8a;

    assign sbox[8'hD][8'h0] = 16'h70; 
    assign sbox[8'hD][8'h1] = 16'h3e;
    assign sbox[8'hD][8'h2] = 16'hb5;
    assign sbox[8'hD][8'h3] = 16'h66;
    assign sbox[8'hD][8'h4] = 16'h48;
    assign sbox[8'hD][8'h5] = 16'h03;
    assign sbox[8'hD][8'h6] = 16'hf6;
    assign sbox[8'hD][8'h7] = 16'h0e;
    assign sbox[8'hD][8'h8] = 16'h61;
    assign sbox[8'hD][8'h9] = 16'h35;
    assign sbox[8'hD][8'hA] = 16'h57;
    assign sbox[8'hD][8'hB] = 16'hb9; 
    assign sbox[8'hD][8'hC] = 16'h86;
    assign sbox[8'hD][8'hD] = 16'hc1;
    assign sbox[8'hD][8'hE] = 16'h1d;
    assign sbox[8'hD][8'hF] = 16'h9e;

    assign sbox[8'hE][8'h0] = 16'he1; 
    assign sbox[8'hE][8'h1] = 16'hf8;
    assign sbox[8'hE][8'h2] = 16'h98;
    assign sbox[8'hE][8'h3] = 16'h11;
    assign sbox[8'hE][8'h4] = 16'h69;
    assign sbox[8'hE][8'h5] = 16'hd9;
    assign sbox[8'hE][8'h6] = 16'h8e;
    assign sbox[8'hE][8'h7] = 16'h94;
    assign sbox[8'hE][8'h8] = 16'h9b;
    assign sbox[8'hE][8'h9] = 16'h1e;
    assign sbox[8'hE][8'hA] = 16'h87;
    assign sbox[8'hE][8'hB] = 16'he9; 
    assign sbox[8'hE][8'hC] = 16'hce;
    assign sbox[8'hE][8'hD] = 16'h55;
    assign sbox[8'hE][8'hE] = 16'h28;
    assign sbox[8'hE][8'hF] = 16'hdf;

    assign sbox[8'hF][8'h0] = 16'h8c; 
    assign sbox[8'hF][8'h1] = 16'ha1;
    assign sbox[8'hF][8'h2] = 16'h89;
    assign sbox[8'hF][8'h3] = 16'h0d;
    assign sbox[8'hF][8'h4] = 16'hbf;
    assign sbox[8'hF][8'h5] = 16'he6;
    assign sbox[8'hF][8'h6] = 16'h42;
    assign sbox[8'hF][8'h7] = 16'h68;
    assign sbox[8'hF][8'h8] = 16'h41;
    assign sbox[8'hF][8'h9] = 16'h99;
    assign sbox[8'hF][8'hA] = 16'h2d;
    assign sbox[8'hF][8'hB] = 16'h0f; 
    assign sbox[8'hF][8'hC] = 16'hb0;
    assign sbox[8'hF][8'hD] = 16'h54;
    assign sbox[8'hF][8'hE] = 16'hbb;
    assign sbox[8'hF][8'hF] = 16'h16;
    
endmodule