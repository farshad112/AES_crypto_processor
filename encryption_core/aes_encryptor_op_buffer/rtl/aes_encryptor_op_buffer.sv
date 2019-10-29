`timescale 1ns/1ps

module aes_encryptor_op_buffer #(
                                    // parameters
                                    parameter BUF_SIZE = 2048,
                                    parameter NO_ROWS = 4,
                                    parameter NO_COLS = 4
                                )(
                                    // IO ports
                                    input logic aes_clk,                                        // clock for aes
                                    input logic ofdm_clk,                                       // clock for ofdm
                                    input logic resetn,                                         // reset (active low)
                                    input logic cipher_txt_vld,                                 // cipher text valid
                                    output logic cipher_txt_rdy,                                // cipher text ready
                                    input logic [7:0] p_cipher_txt[NO_ROWS-1:0][NO_COLS-1:0],   // cipher text
                                    output logic ofdm_sdata_vld,                                // ofdm_serial_data valid
                                    input logic ofdm_sdata_rdy,                                 // ofdm_serial_data_rdy
                                    output logic ofdm_sdata                                     // ofdm_serial_data
                                );
    // internal memory, counters and control flag declarations
    logic [7:0] cipher_txt_mem [BUF_SIZE-1:0];
    logic [16:0] aes_wr_ptr;
    logic [16:0] ofdm_rd_ptr;
    logic buf_full;
    logic buf_empty;

    assign buf_full = (aes_wr_ptr >= BUF_SIZE) & (ofdm_rd_ptr <= 15);
    assign buf_empty = aes_wr_ptr == ofdm_rd_ptr;

    // write operation related logic
    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            foreach(cipher_txt_mem[i]) begin
                cipher_txt_mem[i] = 0;
            end
            aes_wr_ptr = 0;
            buf_full = 0;
            cipher_txt_rdy = 0;
        end
        else begin
            if(!buf_full) begin
                if(cipher_txt_vld) begin
                    foreach(p_cipher_txt[i,j]) begin
                        cipher_txt_mem[aes_wr_ptr] = p_cipher_txt[i][j];
                        aes_wr_ptr += 1;
                    end
                end
            end
            else begin
                cipher_txt_rdy = 0;
                if(ofdm_rd_ptr > 15 && aes_wr_ptr >= BUF_SIZE) begin
                    aes_wr_ptr = 0;
                end
            end
        end
    end

    always @(posedge ofdm_clk or negedge resetn) begin
        if(!resetn) begin
            ofdm_rd_ptr = 0;
            buf_empty = 0;
        end
        else begin
            
        end
    end

endmodule