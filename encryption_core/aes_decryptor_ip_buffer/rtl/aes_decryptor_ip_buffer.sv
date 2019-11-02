`timescale 1ns/1ps

module aes_decryptor_ip_buffer #(
                                    // Parameters
                                    parameter BUF_SIZE = 8,
                                    parameter NO_ROWS = 4,
                                    parameter NO_COLS = 4
                                )(
                                    // IO Ports
                                    input logic ofdm_sclk,                                          // ofdm clk
                                    input logic aes_clk,                                            // aes clk
                                    input logic resetn,                                             // reset (active low)
                                    input logic ofdm_rx_sdata_valid_i,                              // ofdm Rx serial data valid
                                    input logic ofdm_rx_sdata_i,                                    // ofdm Rx serial data
                                    output logic ofdm_sdata_rdy_o,                                  // Buffer is ready for ofdm rx serial data data   
                                    input logic aes_cipher_text_rdy_i,                              // cipher_text_ready
                                    output logic aes_cipher_text_vld_o,                             // cipher_text valid
                                    output logic [7:0] aes_cipher_text_o[NO_ROWS-1:0][NO_COLS-1:0]  // cipher text matrix
                                );
    // local parameters
    localparam MEM_SIZE = 16 * BUF_SIZE;

    // internal memory, counters and control flag declarations
    logic [7:0] cipher_txt_mem[MEM_SIZE-1:0];
    logic [16:0] ofdm_wr_ptr;
    logic [16:0] aes_rd_ptr;
    logic [2:0] ofdm_sdata_bit_cntr;
    logic wr_ptr_rollover_flag;
    logic rd_ptr_rollover_flag;


    // write logic (OFDM Domain)
    always @(posedge ofdm_sclk or negedge resetn) begin
        if(!resetn) begin
            ofdm_wr_ptr = 0;
            wr_ptr_rollover_flag = 0;
            ofdm_sdata_rdy_o = 1;
            ofdm_sdata_bit_cntr = 0; 
            reset_buffer();
        end
        else begin
            if(!wr_ptr_rollover_flag) begin
                if(ofdm_wr_ptr < MEM_SIZE) begin    // fifo is not full
                    ofdm_sdata_rdy_o = 1;
                    if(ofdm_rx_sdata_valid_i) begin
                        cipher_txt_mem[ofdm_wr_ptr][ofdm_sdata_bit_cntr] = ofdm_rx_sdata_i;
                        $display("DEBUG :: cipher_txt_mem[%0d][%0d]:%0h", ofdm_wr_ptr, ofdm_sdata_bit_cntr, cipher_txt_mem[ofdm_wr_ptr][ofdm_sdata_bit_cntr]);
                        if(ofdm_sdata_bit_cntr == 7) begin
                            ofdm_wr_ptr += 1;
                        end
                        ofdm_sdata_bit_cntr += 1;
                    end
                end
                if(ofdm_wr_ptr >= MEM_SIZE && aes_rd_ptr > 0) begin   // roll over is possible
                    wr_ptr_rollover_flag = 1;
                    ofdm_wr_ptr = 0;
                    ofdm_sdata_bit_cntr = 0;
                    ofdm_sdata_rdy_o = 1;
                end
                else if(ofdm_wr_ptr >= MEM_SIZE) begin  // roll over is not possible. fifo is full
                    ofdm_sdata_rdy_o = 0;
                end
            end
            else begin  // rollover write logic
                if(ofdm_wr_ptr < MEM_SIZE && ofdm_wr_ptr < aes_rd_ptr) begin
                    ofdm_sdata_rdy_o = 1;
                    if(ofdm_rx_sdata_valid_i) begin
                        cipher_txt_mem[ofdm_wr_ptr][ofdm_sdata_bit_cntr] = ofdm_rx_sdata_i;
                        if(ofdm_sdata_bit_cntr == 7) begin
                            ofdm_wr_ptr += 1;
                        end
                        ofdm_sdata_bit_cntr += 1;
                    end
                end
                if(ofdm_wr_ptr >= MEM_SIZE && aes_rd_ptr > 0) begin   // roll over is possible
                    wr_ptr_rollover_flag = 0;
                    ofdm_wr_ptr = 0;
                    ofdm_sdata_bit_cntr = 0;
                    ofdm_sdata_rdy_o = 1;
                end
                else if( (ofdm_wr_ptr >= MEM_SIZE && aes_rd_ptr == 0) || (ofdm_wr_ptr == aes_rd_ptr) )begin  // roll over is not possible. fifo is full
                    ofdm_sdata_rdy_o = 0;
                end
            end
        end
    end

    // read logic (AES domain)
    always @(posedge aes_clk or negedge resetn) begin
        if(!resetn) begin
            aes_rd_ptr = 0;
            rd_ptr_rollover_flag = 0;
        end
        else begin
            if(!rd_ptr_rollover_flag) begin
                if(aes_cipher_text_rdy_i) begin
                    if(((aes_rd_ptr == ofdm_wr_ptr) || ( absolute_diff(ofdm_wr_ptr,aes_rd_ptr)<15) ) && (wr_ptr_rollover_flag == 0)) begin  // fifo is empty
                        aes_cipher_text_vld_o = 0;
                    end
                    else if(ofdm_wr_ptr %16 == 0)begin  // fifo has valid data
                        aes_cipher_text_vld_o = 1;
                        foreach(aes_cipher_text_o[i,j]) begin
                            aes_cipher_text_o[i][j] = cipher_txt_mem[aes_rd_ptr];
                            $display("DEBUG AES_RD :: aes_cipher_text_o[%0d][%0d]:%0h    --- cipher_txt_mem[%0d]:%0h", i, j, aes_cipher_text_o[i][j], aes_rd_ptr,cipher_txt_mem[aes_rd_ptr]);
                            aes_rd_ptr +=1;
                        end
                        if(aes_rd_ptr >= MEM_SIZE && wr_ptr_rollover_flag == 1) begin   // check if rollover is possible
                            rd_ptr_rollover_flag = 1;
                            aes_rd_ptr = 0;
                            aes_cipher_text_vld_o = 1;
                        end
                        else if(aes_rd_ptr >= MEM_SIZE) begin
                            aes_cipher_text_vld_o = 0;
                        end
                    end
                end
                else begin
                    aes_cipher_text_vld_o = 0;
                end
            end
            else begin  // read rollover logic 
                if(aes_cipher_text_rdy_i) begin
                    if(((aes_rd_ptr == ofdm_wr_ptr) || ( absolute_diff(ofdm_wr_ptr,aes_rd_ptr)<15) ) && (wr_ptr_rollover_flag == 1)) begin  // fifo is empty
                        aes_cipher_text_vld_o = 0;
                    end
                    else begin  // fifo has valid data
                        aes_cipher_text_vld_o = 1;
                        foreach(aes_cipher_text_o[i,j]) begin
                            aes_cipher_text_o[i][j] = cipher_txt_mem[aes_rd_ptr];
                            aes_rd_ptr +=1;
                        end
                        if(aes_rd_ptr >= MEM_SIZE && wr_ptr_rollover_flag == 0) begin   // check if rollover is possible
                            rd_ptr_rollover_flag = 0;
                            aes_rd_ptr = 0;
                            aes_cipher_text_vld_o = 1;
                        end
                        else if(aes_rd_ptr >= MEM_SIZE) begin
                            aes_cipher_text_vld_o = 0;
                        end
                    end
                end
                else begin
                    aes_cipher_text_vld_o = 0;
                end
            end
        end
    end

    function void reset_buffer();
        foreach(cipher_txt_mem[i]) begin
            cipher_txt_mem[i] = 0;
        end
    endfunction

    function logic [16:0] absolute_diff(logic [16:0] val1, logic [16:0] val2);
        if(val1 >= val2) begin
            absolute_diff = val1 - val2;
        end
        else begin
            absolute_diff = val2 - val1;
        end
    endfunction
endmodule
