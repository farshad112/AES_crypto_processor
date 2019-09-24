`timescale 1ns/1ps

module aes_key_expander#(
                            // parameters
                            parameter KEY_WIDTH=128

                        )(
                            // IO ports
                            input logic [7:0] cipher_key [3:0] [3:0],
                            input logic resetn,
                            input logic encrypt_en,
                            input logic clk,
                            input logic [3:0] key_sel,
                            output logic key_rdy,
                            output logic [7:0] round_key[3:0][3:0]
                        );
    
    // round constant matrix
    logic [7:0] rcon_matrix [4:0] [9:0];

    // register for holding round keys
    logic [7:0] round_key_matrix [3:0] [3:0][9:0];

    // counter and control flags for round key generation
    logic key_gen_done;
    logic [3:0] key_counter;

    // generate keys
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            key_rdy = 0;
            foreach(round_key[i,j]) begin
                round_key[i][j] = 0;
            end
            // reset control flags
            key_gen_done = 0;
            key_counter = 0;

            // reset round key matrix
            foreach(round_key_matrix[i,j,k]) begin
                round_key_matrix[i][j][k] = 0;
            end
        end
        else begin
            if(encrypt_en) begin
                if(!key_gen_done) begin
                    if(key_counter == 0) begin
                        $display("round 0 key generation");
                    end
                    else if(key_counter == 1) begin
                        $display("round 1 key generation ..");
                    end
                end
            end    
        end
    end    

    // create round constant table
    assign rcon_matrix[0][0] = 8'h1;
    assign rcon_matrix[0][1] = 8'h2;
    assign rcon_matrix[0][2] = 8'h4;
    assign rcon_matrix[0][3] = 8'h8;
    assign rcon_matrix[0][4] = 8'h10;
    assign rcon_matrix[0][5] = 8'h20;
    assign rcon_matrix[0][6] = 8'h40;
    assign rcon_matrix[0][7] = 8'h80;
    assign rcon_matrix[0][8] = 8'h1B;
    assign rcon_matrix[0][9] = 8'h36;

    assign rcon_matrix[1][0] = 8'h0;
    assign rcon_matrix[1][1] = 8'h0;
    assign rcon_matrix[1][2] = 8'h0;
    assign rcon_matrix[1][3] = 8'h0;
    assign rcon_matrix[1][4] = 8'h0;
    assign rcon_matrix[1][5] = 8'h0;
    assign rcon_matrix[1][6] = 8'h0;
    assign rcon_matrix[1][7] = 8'h0;
    assign rcon_matrix[1][8] = 8'h0;
    assign rcon_matrix[1][9] = 8'h0;

    assign rcon_matrix[2][0] = 8'h0;
    assign rcon_matrix[2][1] = 8'h0;
    assign rcon_matrix[2][2] = 8'h0;
    assign rcon_matrix[2][3] = 8'h0;
    assign rcon_matrix[2][4] = 8'h0;
    assign rcon_matrix[2][5] = 8'h0;
    assign rcon_matrix[2][6] = 8'h0;
    assign rcon_matrix[2][7] = 8'h0;
    assign rcon_matrix[2][8] = 8'h0;
    assign rcon_matrix[2][9] = 8'h0;

    assign rcon_matrix[3][0] = 8'h0;
    assign rcon_matrix[3][1] = 8'h0;
    assign rcon_matrix[3][2] = 8'h0;
    assign rcon_matrix[3][3] = 8'h0;
    assign rcon_matrix[3][4] = 8'h0;
    assign rcon_matrix[3][5] = 8'h0;
    assign rcon_matrix[3][6] = 8'h0;
    assign rcon_matrix[3][7] = 8'h0;
    assign rcon_matrix[3][8] = 8'h0;
    assign rcon_matrix[3][9] = 8'h0;

    assign rcon_matrix[4][0] = 8'h0;
    assign rcon_matrix[4][1] = 8'h0;
    assign rcon_matrix[4][2] = 8'h0;
    assign rcon_matrix[4][3] = 8'h0;
    assign rcon_matrix[4][4] = 8'h0;
    assign rcon_matrix[4][5] = 8'h0;
    assign rcon_matrix[4][6] = 8'h0;
    assign rcon_matrix[4][7] = 8'h0;
    assign rcon_matrix[4][8] = 8'h0;
    assign rcon_matrix[4][9] = 8'h0;


    ////////////////////////////////////////////////////// functions ///////////////////////////////////////////////////////////

    /////////////////////////////////////
    // function name:
    // parameters:
    // description:
    /////////////////////////////////////
endmodule
