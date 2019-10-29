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
            #100ns ofdm_sclk = ~ofdm_sclk; 
        end
    end

    // test block
    initial begin
        resetn = 0;
        aes_cipher_text_rdy = 0;
        #20ns;
        resetn = 1;
        aes_cipher_text_rdy = 1;

    end

    // Instantiation of DUT
    aes_encryptor_op_buffer #(
                                // parameters
                                .BUF_SIZE(2048),
                                .NO_ROWS(4),
                                .NO_COLS(4)
                            )I_AES_OP_BUF(
                                // IO ports
                                .aes_clk(aes_clk),                      // input
                                .ofdm_clk(ofdm_sclk),                   // input
                                .resetn(resetn),                        // input
                                .cipher_txt_vld(aes_cipher_text_rdy),   // input
                                .cipher_txt_rdy(aes_cipher_txt_ok),     // output
                                .p_cipher_txt(aes_cipher_text_o),       // input
                                .ofdm_sdata_vld(ofdm_tx_sdata_vld),     // output                          
                                .ofdm_sdata_rdy(ofdm_tx_rdy),           // input
                                .ofdm_sdata(ofdm_tx_sdata)              // output
                        );
endmodule
