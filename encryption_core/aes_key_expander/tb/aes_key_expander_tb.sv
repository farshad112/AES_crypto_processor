`timescale 1ns/1ps

module tb;
    logic [7:0] cipher_key [3:0] [3:0];
    logic resetn;
    logic clk;
    logic encrypt_en;
    logic [3:0] key_sel;
    logic key_rdy;
    logic [7:0] round_key[3:0][3:0];

    // clock generation block
    initial begin
        clk = 0;
        forever begin
            #10ns clk = ~clk;
        end
    end

    // Instantiation of DUT
    aes_key_expander#(
                            // parameters
                            .KEY_WIDTH(128)

                    )DUT (
                            // IO ports
                            .cipher_key(cipher_key),
                            .resetn(resetn),
                            .clk(clk),
                            .encrypt_en(encrypt_en),
                            .key_sel(key_sel),
                            .key_rdy(key_rdy),
                            .round_key(round_key)
                    );

    // test block
    initial begin
        resetn = 0;
        key_sel = 0;
        encrypt_en = 0;
        #40ns;
        resetn = 1;
        @(negedge clk);
        encrypt_en = 1;
    end

    // terminate simualtion after timeout
    initial begin
        repeat(200)
            @(posedge clk);
        $finish();
    end

    // assign cipher key
    assign cipher_key[0][0] = 8'h2b;
    assign cipher_key[0][1] = 8'h28;
    assign cipher_key[0][2] = 8'hab;
    assign cipher_key[0][3] = 8'h09;

    assign cipher_key[1][0] = 8'h7e;
    assign cipher_key[1][1] = 8'hae;
    assign cipher_key[1][2] = 8'hf7;
    assign cipher_key[1][3] = 8'hcf;

    assign cipher_key[2][0] = 8'h15;
    assign cipher_key[2][1] = 8'hd2;
    assign cipher_key[2][2] = 8'h15;
    assign cipher_key[2][3] = 8'h4f;

    assign cipher_key[3][0] = 8'h16;
    assign cipher_key[3][1] = 8'ha6;
    assign cipher_key[3][2] = 8'h88;
    assign cipher_key[3][3] = 8'h3c;
endmodule