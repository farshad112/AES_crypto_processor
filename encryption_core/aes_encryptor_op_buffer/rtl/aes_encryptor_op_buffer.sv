`timescale 1ns/1ps

module aes_encryptor_op_buffer #(
                                    // parameters
                                    parameter BUF_SIZE = 8,
                                    parameter NO_ROWS = 4,
                                    parameter NO_COLS = 4
                                )(
                                    // IO ports
                                    input logic aes_clk,                                        // clock for aes
                                    input logic ofdm_clk,                                       // clock for ofdm
                                    input logic resetn,                                         // reset (active low)
                                    input logic cipher_txt_vld,                                 // cipher text valid
                                    output logic cipher_txt_rdy,                                // cipher text ready
                                    input logic [7:0] aes_cipher_txt[NO_ROWS-1:0][NO_COLS-1:0],   // cipher text
                                    output logic ofdm_sdata_vld,                                // ofdm_serial_data valid
                                    input logic ofdm_sdata_rdy,                                 // ofdm_serial_data_rdy
                                    output logic ofdm_sdata                                     // ofdm_serial_data
                                );
    localparam MEM_SIZE = 16 * BUF_SIZE;
    // internal memory, counters and control flag declarations
    logic [7:0] cipher_txt_mem [MEM_SIZE-1:0];
    logic [16:0] aes_wr_ptr;
    logic [16:0] ofdm_rd_ptr;
    logic [3:0] ofdm_sdata_bit_cntr;
    logic wr_ptr_rollover_flag;
    logic rd_ptr_rollover_flag;

    // write logic (AES Domain)
    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            reset_buffer();             // reset memory
            aes_wr_ptr = 0;             // reset aes_wr_ptr
            wr_ptr_rollover_flag = 0;   // reset wr_rollover flag
            cipher_txt_rdy = 1;
        end
        else begin
            if(!wr_ptr_rollover_flag) begin
                if(aes_wr_ptr < MEM_SIZE) begin
                    cipher_txt_rdy = 1;
                    if(cipher_txt_vld) begin
                        // increment aes_wr_ptr by 16 to store 16 bytes of data in memory
                        foreach(aes_cipher_txt[i,j]) begin
                            cipher_txt_mem[aes_wr_ptr] = aes_cipher_txt[i][j];
                            aes_wr_ptr += 1;
                        end
                    end
                end
                if(aes_wr_ptr >= MEM_SIZE && ofdm_rd_ptr > 15) begin  // rollover is possible
                    wr_ptr_rollover_flag = 1;
                    aes_wr_ptr = 0;
                    cipher_txt_rdy = 1;
                end
                else begin  // rollover is not possible and fifo is full
                    cipher_txt_rdy = 0;
                end
            end
            else begin  // rollover wr logic
                if((aes_wr_ptr < MEM_SIZE) && (aes_wr_ptr < ofdm_rd_ptr) && ((ofdm_rd_ptr+1) % 16 == 0)) begin
                    if(cipher_txt_vld) begin
                        // increment aes_wr_ptr by 16 to store 16 bytes of data in memory
                        foreach(aes_cipher_txt[i,j]) begin
                            cipher_txt_mem[aes_wr_ptr] = aes_cipher_txt[i][j];
                            aes_wr_ptr += 1;
                        end
                    end
                end
                if(aes_wr_ptr >= MEM_SIZE && ofdm_rd_ptr > 15) begin  // rollover is possible
                    wr_ptr_rollover_flag = 0;
                    aes_wr_ptr = 0;
                    cipher_txt_rdy = 1;
                end
                else begin  // rollover is not possible and fifo is full
                    cipher_txt_rdy = 0;
                end
            end
        end
    end

    // read logic (OFDM Domain)
    always @(posedge ofdm_clk or negedge resetn) begin
        if(!resetn) begin
            ofdm_rd_ptr = 0;
            rd_ptr_rollover_flag = 0;
            ofdm_sdata_vld = 0;
            ofdm_sdata = 0;
            ofdm_sdata_bit_cntr = 0; 
        end
        else begin
            if(!rd_ptr_rollover_flag) begin
                if(ofdm_rd_ptr == aes_wr_ptr) begin  // fifo is empty
                    ofdm_sdata_vld = 0;
                    ofdm_sdata = 0;
                end
                else begin
                    if(ofdm_sdata_rdy) begin
                        ofdm_sdata_vld = 1;
                        ofdm_sdata = cipher_txt_mem[ofdm_rd_ptr][ofdm_sdata_bit_cntr];
                        if(ofdm_sdata_bit_cntr == 7) begin
                            if(ofdm_rd_ptr < MEM_SIZE) begin
                                ofdm_rd_ptr += 1;
                            end
                            else if(wr_ptr_rollover_flag == 1 && aes_wr_ptr > 0)begin
                                ofdm_rd_ptr = 0;
                                rd_ptr_rollover_flag = 1;
                            end
                        end
                        ofdm_sdata_bit_cntr += 1;
                    end
                end
            end
            else begin  // rollover logic
                if(ofdm_rd_ptr == aes_wr_ptr) begin  // fifo is empty
                    ofdm_sdata_vld = 0;
                    ofdm_sdata = 0;
                end
                else begin
                    if(ofdm_sdata_rdy) begin
                        ofdm_sdata_vld = 1;
                        ofdm_sdata = cipher_txt_mem[ofdm_rd_ptr][ofdm_sdata_bit_cntr];
                        if(ofdm_sdata_bit_cntr == 7) begin
                            if(ofdm_rd_ptr < MEM_SIZE) begin
                                ofdm_rd_ptr += 1;
                            end
                            else if(wr_ptr_rollover_flag == 1 && aes_wr_ptr > 0)begin
                                ofdm_rd_ptr = 0;
                                rd_ptr_rollover_flag = 0;
                            end
                        end
                        ofdm_sdata_bit_cntr += 1;
                    end
                end
            end
        end
    end

    function void reset_buffer();
        foreach(cipher_txt_mem[i]) begin
            cipher_txt_mem[i] = 0;
        end
    endfunction
endmodule
