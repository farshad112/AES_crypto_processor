`timescale 1ns/1ps

module aes_encryptr_op_buf_tb;
   
    logic aes_clk;
    logic ofdm_sclk;
    logic resetn;
    logic aes_cipher_text_rdy;
    logic aes_cipher_txt_ok;
    logic [7:0] aes_cipher_text_o[3:0][3:0];
    logic ofdm_tx_sdata_vld;
    logic ofdm_tx_rdy;
    logic ofdm_tx_sdata;

    logic [255:0] ofdm_sdata_buffer;
    logic [16:0] ofdm_sdata_buf_cntr;

    // aes_clk generation block
    initial begin
        aes_clk = 0;
        forever begin
            #10ns aes_clk = ~aes_clk;
        end
    end 

    // ofdm_sclk generation block
    initial begin
        ofdm_sclk = 0;
        forever begin
            #10ns ofdm_sclk = ~ofdm_sclk; 
        end
    end

    // test block
    initial begin
        resetn = 0;
        aes_cipher_text_rdy = 0;
        #20ns;
        resetn = 1;
    end

    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            aes_cipher_text_rdy = 0;
            foreach(aes_cipher_text_o[i,j]) 
                aes_cipher_text_o[i][j] = 0;
        end
        else begin
            aes_cipher_text_rdy = 1;
            // drive cipher text data to buffer
            aes_cipher_text_o [0][0] = 8'h39;
            aes_cipher_text_o [0][1] = 8'h02;
            aes_cipher_text_o [0][2] = 8'hdc;
            aes_cipher_text_o [0][3] = 8'h19;

            aes_cipher_text_o [1][0] = 8'h25;
            aes_cipher_text_o [1][1] = 8'hdc;
            aes_cipher_text_o [1][2] = 8'h11;
            aes_cipher_text_o [1][3] = 8'h6a;
        
            aes_cipher_text_o [2][0] = 8'h84;
            aes_cipher_text_o [2][1] = 8'h09;
            aes_cipher_text_o [2][2] = 8'h85;
            aes_cipher_text_o [2][3] = 8'h0b;

            aes_cipher_text_o [3][0] = 8'h1d;
            aes_cipher_text_o [3][1] = 8'hfb;
            aes_cipher_text_o [3][2] = 8'h97;
            aes_cipher_text_o [3][3] = 8'h32;

            wait(aes_cipher_txt_ok);
        end
    end

    always @(posedge ofdm_sclk or negedge resetn) begin
        if(!resetn) begin
            ofdm_sdata_buffer = 0;
            ofdm_sdata_buf_cntr = 0;
            ofdm_tx_rdy = 1;
        end
        else begin
            ofdm_tx_rdy = 1;
            if(ofdm_tx_sdata_vld) begin
                ofdm_sdata_buffer[ofdm_sdata_buf_cntr] = ofdm_tx_sdata;
                ofdm_sdata_buf_cntr +=1;
            end
        end
    end

    // Instantiation of DUT
    aes_encryptor_op_buffer #(
                                // parameters
                                .BUF_SIZE(4),
                                .NO_ROWS(4),
                                .NO_COLS(4)
                            )I_AES_OP_BUF(
                                // IO ports
                                .aes_clk(aes_clk),                      // input
                                .ofdm_clk(ofdm_sclk),                   // input
                                .resetn(resetn),                        // input
                                .cipher_txt_vld(aes_cipher_text_rdy),   // input
                                .cipher_txt_rdy(aes_cipher_txt_ok),     // output
                                .aes_cipher_txt(aes_cipher_text_o),       // input
                                .ofdm_sdata_vld(ofdm_tx_sdata_vld),     // output                          
                                .ofdm_sdata_rdy(ofdm_tx_rdy),           // input
                                .ofdm_sdata(ofdm_tx_sdata)              // output
                        );
endmodule
