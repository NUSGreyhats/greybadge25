`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: By TL thanks TL
// 
// Create Date: 01.04.2024 17:29:55
// Design Name: 
// Module Name: encryption
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module des_encryption(
    input action,
    input [7:0] seed,
    input [63:0] data_in,
    output [63:0] data_out
    );
    wire [23:0] left = action == 0 ? encrypter(data_in[55:32], passkey[seed]) : decrypter(data_in[55:32], passkey[seed]);
    wire [23:0] right = action == 0 ? encrypter(data_in[31:8], passkey[seed]) : decrypter(data_in[31:8], passkey[seed]);
    wire [47:0] combined;
    assign data_out = {data_in[63:56], combined, data_in[7:0]};
    integer i = 0;
    wire [47:0] passkey [2:0];
    reg [2:0] temp; //for bitshift
    
    function [23:0] encrypter(
        input [23:0] plaintext,
        input [47:0] passkey); begin
        for (i = 0; i < 8; i = i + 1) begin
        plaintext = plaintext ^ passkey[47:24]; //Bitwise XOR with left half of passkey
        //left shift
        temp = plaintext[23:21];
        plaintext = plaintext << 3;
        plaintext[2:0] = temp;
        plaintext = plaintext ^ passkey[23:0]; //Bitwise XOR with right half of passkey
        end
        encrypter = plaintext;
    end endfunction 
    
    function [27:0] decrypter(
        input [27:0] ciphertext,
        input [55:0] passkey
        ); begin
        for (i = 0; i < 8; i = i + 1) begin
            ciphertext = ciphertext ^ passkey[23:0]; //XOR with right half
            temp = ciphertext[2:0];
            ciphertext = ciphertext >> 3; //shift right
            ciphertext[23:21] = temp;
            ciphertext = ciphertext ^ passkey[47:24]; //XOR with left half
        end
        
        decrypter = ciphertext;
    end endfunction
    
    assign combined = {left, right};
    

    assign passkey[0] = 48'b1100_0011_1010_0110_1001_0101_1100_0011_1010_0110_0011_1100;
    assign passkey[1] = 48'b0000_1111_0101_1100_1010_0011_0000_1111_0101_1100_1111_0000;
    assign passkey[2] = 48'b1101_0010_0100_1011_1110_0001_1101_0010_0100_1011_0010_1101;


    
    
/*
    reg [63:0] initial_permutation_table = {8'd58, 8'd50, 8'd42, 8'd34, 8'd26, 8'd18, 8'd10, 8'd2,
                                            8'd60, 8'd52, 8'd44, 8'd36, 8'd28, 8'd20, 8'd12, 8'd4,
                                            8'd62, 8'd54, 8'd46, 8'd38, 8'd30, 8'd22, 8'd14, 8'd6,
                                            8'd64, 8'd56, 8'd48, 8'd40, 8'd32, 8'd24, 8'd16, 8'd8,
                                            8'd57, 8'd49, 8'd41, 8'd33, 8'd25, 8'd17,  8'd9, 8'd1,
                                            8'd59, 8'd51, 8'd43, 8'd35, 8'd27, 8'd19, 8'd11, 8'd3,
                                            8'd61, 8'd53, 8'd45, 8'd37, 8'd29, 8'd21, 8'd13, 8'd5,
                                            8'd63, 8'd55, 8'd47, 8'd39, 8'd31, 8'd23, 8'd15, 8'd7};
                                            
    reg [63:0] final_permutation_table = {8'd40, 8'd8, 8'd48, 8'd16, 8'd56, 8'd24, 8'd64, 8'd32,
                                          8'd39, 8'd7, 8'd47, 8'd15, 8'd55, 8'd23, 8'd63, 8'd31,
                                          8'd38, 8'd6, 8'd46, 8'd14, 8'd54, 8'd22, 8'd62, 8'd30,
                                          8'd37, 8'd5, 8'd45, 8'd13, 8'd53, 8'd21, 8'd61, 8'd29,
                                          8'd36, 8'd4, 8'd44, 8'd12, 8'd52, 8'd20, 8'd60, 8'd28,
                                          8'd35, 8'd3, 8'd43, 8'd11, 8'd51, 8'd19, 8'd59, 8'd27,
                                          8'd34, 8'd2, 8'd42, 8'd10, 8'd50, 8'd18, 8'd58, 8'd26,
                                          8'd33, 8'd1, 8'd41, 8'd9, 8'd49, 8'd17, 8'd57, 8'd25};
                                          
    reg [47:0] expansion_table = {8'd32, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd4, 8'd5,
                                8'd6, 8'd7, 8'd8, 8'd9, 8'd8, 8'd9, 8'd10, 8'd11,
                                8'd12, 8'd13, 8'd12, 8'd13, 8'd14, 8'd15, 8'd16, 8'd17,
                                8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd21, 8'd20, 8'd21,
                                8'd22, 8'd23, 8'd24, 8'd25, 8'd24, 8'd25, 8'd26, 8'd27,
                                8'd28, 8'd29, 8'd28, 8'd29, 8'd30, 8'd31, 8'd32, 8'd1};
    
    //Hopefully BRAM                            
    reg [3:0] s_boxes [7:0][3:0][15:0];
    reg [7:0] keyp [55:0];
    reg [7:0] key_comp [47:0];
    reg [7:0] per [31:0];
        
    reg [7:0] i = 0, j = 0, k = 0, x = 0, y = 0, row = 0, col = 0; //constants for loops etc
    reg [31:0] left, right, to_swap; //Left and Right plaintext
    reg [47:0] right_expanded, xor_intermediate; //Text expansion
    reg [63:0] initial_permute; //For step 1
    reg [47:0] rkb [15:0], rkb_rev [15:0]; //Round keys binary (reverse)
    reg [55:0] key; //temp holder for 56-bit key generated
    reg [27:0] key_left, key_right; //Split into left and right
    reg [55:0] temp_keyp; //Key parity drop table -- Just to read from BRAM
    reg [47:0] temp_key_comp; //Key compression table -- Just to read from BRAM
    reg[31:0] temp_per; //Straight permutation table -- To read from BRAM
    reg [31:0] temp_val; //For s-boxing
    reg [31:0] d_box; //After s-boxing
    reg [63:0] combine, encrypted;
    assign data_out = encrypted;
    
    reg [63:0] result;
    function [63:0] permute(input [63:0] k, input [63:0] arr, input [7:0] n); begin
        for (i = 0; i < n; i = i + 1) begin
            result = result + k[arr[i] - 1];
        end
        permute = result;
    end
    endfunction
    
    initial begin
        //generate substitution boxes
        s_boxes[0][0][0] = 4'd14; s_boxes[0][0][1]  = 4'd4; s_boxes[0][0][2]  = 4'd13; s_boxes[0][0][3]  = 4'd1;
        s_boxes[0][0][4]  = 4'd2; s_boxes[0][0][5]  = 4'd15; s_boxes[0][0][6]  = 4'd11; s_boxes[0][0][7]  = 4'd8;
        s_boxes[0][0][8]  = 4'd3; s_boxes[0][0][9]  = 4'd10; s_boxes[0][0][10] = 4'd6; s_boxes[0][0][11] = 4'd12;
        s_boxes[0][0][12] = 4'd5; s_boxes[0][0][13] = 4'd9; s_boxes[0][0][14] = 4'd0; s_boxes[0][0][15] = 4'd7;
        
        s_boxes[0][1][0] = 4'd0; s_boxes[0][1][1] = 4'd15; s_boxes[0][1][2] = 4'd7; s_boxes[0][1][3] = 4'd4;
        s_boxes[0][1][4] = 4'd14; s_boxes[0][1][5] = 4'd2; s_boxes[0][1][6] = 4'd13; s_boxes[0][1][7] = 4'd1;
        s_boxes[0][1][8] = 4'd10; s_boxes[0][1][9] = 4'd6; s_boxes[0][1][10] = 4'd12; s_boxes[0][1][11] = 4'd11;
        s_boxes[0][1][12] = 4'd9; s_boxes[0][1][13] = 4'd5; s_boxes[0][1][14] = 4'd3; s_boxes[0][1][15] = 4'd8;
        
        s_boxes[0][2][0] = 4'd4; s_boxes[0][2][1] = 4'd1; s_boxes[0][2][2] = 4'd14; s_boxes[0][2][3] = 4'd8;
        s_boxes[0][2][4] = 4'd13; s_boxes[0][2][5] = 4'd6; s_boxes[0][2][6] = 4'd2; s_boxes[0][2][7] = 4'd11;
        s_boxes[0][2][8] = 4'd15; s_boxes[0][2][9] = 4'd12; s_boxes[0][2][10] = 4'd9; s_boxes[0][2][11] = 4'd7;
        s_boxes[0][2][12] = 4'd3; s_boxes[0][2][13] = 4'd10; s_boxes[0][2][14] = 4'd5; s_boxes[0][2][15] = 4'd0;
        
        s_boxes[0][3][0] = 4'd15; s_boxes[0][3][1] = 4'd12; s_boxes[0][3][2] = 4'd8; s_boxes[0][3][3] = 4'd2;
        s_boxes[0][3][4] = 4'd4; s_boxes[0][3][5] = 4'd9; s_boxes[0][3][6] = 4'd1; s_boxes[0][3][7] = 4'd7;
        s_boxes[0][3][8] = 4'd5; s_boxes[0][3][9] = 4'd11; s_boxes[0][3][10] = 4'd3; s_boxes[0][3][11] = 4'd14;
        s_boxes[0][3][12] = 4'd10; s_boxes[0][3][13] = 4'd0; s_boxes[0][3][14] = 4'd6; s_boxes[0][3][15] = 4'd13;
        
        s_boxes[1][0][0] = 4'd15; s_boxes[1][0][1]  = 4'd1; s_boxes[1][0][2]  = 4'd8; s_boxes[1][0][3]  = 4'd14;
        s_boxes[1][0][4]  = 4'd6; s_boxes[1][0][5]  = 4'd11; s_boxes[1][0][6]  = 4'd3; s_boxes[1][0][7]  = 4'd4;
        s_boxes[1][0][8]  = 4'd9; s_boxes[1][0][9]  = 4'd7; s_boxes[1][0][10] = 4'd2; s_boxes[1][0][11] = 4'd13;
        s_boxes[1][0][12] = 4'd12; s_boxes[1][0][13] = 4'd0; s_boxes[1][0][14] = 4'd5; s_boxes[1][0][15] = 4'd10;
        
        s_boxes[1][1][0] = 4'd3; s_boxes[1][1][1] = 4'd13; s_boxes[1][1][2] = 4'd4; s_boxes[1][1][3] = 4'd7;
        s_boxes[1][1][4] = 4'd15; s_boxes[1][1][5] = 4'd2; s_boxes[1][1][6] = 4'd8; s_boxes[1][1][7] = 4'd14;
        s_boxes[1][1][8] = 4'd12; s_boxes[1][1][9] = 4'd0; s_boxes[1][1][10] = 4'd1; s_boxes[1][1][11] = 4'd10;
        s_boxes[1][1][12] = 4'd6; s_boxes[1][1][13] = 4'd9; s_boxes[1][1][14] = 4'd11; s_boxes[1][1][15] = 4'd5;
    
        s_boxes[1][2][0] = 4'd0; s_boxes[1][2][1] = 4'd14; s_boxes[1][2][2] = 4'd7; s_boxes[1][2][3] = 4'd11;
        s_boxes[1][2][4] = 4'd10; s_boxes[1][2][5] = 4'd4; s_boxes[1][2][6] = 4'd13; s_boxes[1][2][7] = 4'd1;
        s_boxes[1][2][8] = 4'd5; s_boxes[1][2][9] = 4'd8; s_boxes[1][2][10] = 4'd12; s_boxes[1][2][11] = 4'd6;
        s_boxes[1][2][12] = 4'd9; s_boxes[1][2][13] = 4'd3; s_boxes[1][2][14] = 4'd2; s_boxes[1][2][15] = 4'd15;
    
        s_boxes[1][3][0] = 4'd13; s_boxes[1][3][1] = 4'd8; s_boxes[1][3][2] = 4'd10; s_boxes[1][3][3] = 4'd1;
        s_boxes[1][3][4] = 4'd3; s_boxes[1][3][5] = 4'd15; s_boxes[1][3][6] = 4'd4; s_boxes[1][3][7] = 4'd2;
        s_boxes[1][3][8] = 4'd11; s_boxes[1][3][9] = 4'd6; s_boxes[1][3][10] = 4'd7; s_boxes[1][3][11] = 4'd12;
        s_boxes[1][3][12] = 4'd0; s_boxes[1][3][13] = 4'd5; s_boxes[1][3][14] = 4'd14; s_boxes[1][3][15] = 4'd9;
        
        s_boxes[2][0][0] = 4'd10; s_boxes[2][0][1] = 4'd0; s_boxes[2][0][2] = 4'd9; s_boxes[2][0][3] = 4'd14;
        s_boxes[2][0][4] = 4'd6;  s_boxes[2][0][5] = 4'd3;  s_boxes[2][0][6] = 4'd15; s_boxes[2][0][7] = 4'd5;
        s_boxes[2][0][8] = 4'd1;  s_boxes[2][0][9] = 4'd13; s_boxes[2][0][10] = 4'd12; s_boxes[2][0][11] = 4'd7;
        s_boxes[2][0][12] = 4'd11; s_boxes[2][0][13] = 4'd4; s_boxes[2][0][14] = 4'd2; s_boxes[2][0][15] = 4'd8;
    
        s_boxes[2][1][0] = 4'd13; s_boxes[2][1][1] = 4'd7; s_boxes[2][1][2] = 4'd0; s_boxes[2][1][3] = 4'd9;
        s_boxes[2][1][4] = 4'd3; s_boxes[2][1][5] = 4'd4; s_boxes[2][1][6] = 4'd6; s_boxes[2][1][7] = 4'd10;
        s_boxes[2][1][8] = 4'd2; s_boxes[2][1][9] = 4'd8; s_boxes[2][1][10] = 4'd5; s_boxes[2][1][11] = 4'd14;
        s_boxes[2][1][12] = 4'd12; s_boxes[2][1][13] = 4'd11; s_boxes[2][1][14] = 4'd15; s_boxes[2][1][15] = 4'd1;
    
        s_boxes[2][2][0] = 4'd13; s_boxes[2][2][1] = 4'd6; s_boxes[2][2][2] = 4'd4; s_boxes[2][2][3] = 4'd9;
        s_boxes[2][2][4] = 4'd8; s_boxes[2][2][5] = 4'd15; s_boxes[2][2][6] = 4'd3; s_boxes[2][2][7] = 4'd0;
        s_boxes[2][2][8] = 4'd11; s_boxes[2][2][9] = 4'd1; s_boxes[2][2][10] = 4'd2; s_boxes[2][2][11] = 4'd12;
        s_boxes[2][2][12] = 4'd5; s_boxes[2][2][13] = 4'd10; s_boxes[2][2][14] = 4'd14; s_boxes[2][2][15] = 4'd7;
    
        s_boxes[2][3][0] = 4'd1; s_boxes[2][3][1] = 4'd10; s_boxes[2][3][2] = 4'd13; s_boxes[2][3][3] = 4'd0;
        s_boxes[2][3][4] = 4'd6; s_boxes[2][3][5] = 4'd9; s_boxes[2][3][6] = 4'd8; s_boxes[2][3][7] = 4'd7;
        s_boxes[2][3][8] = 4'd4; s_boxes[2][3][9] = 4'd15; s_boxes[2][3][10] = 4'd14; s_boxes[2][3][11] = 4'd3;
        s_boxes[2][3][12] = 4'd11; s_boxes[2][3][13] = 4'd5; s_boxes[2][3][14] = 4'd2; s_boxes[2][3][15] = 4'd12;
        
        s_boxes[3][0][0] = 4'd7;  s_boxes[3][0][1] = 4'd13; s_boxes[3][0][2] = 4'd14; s_boxes[3][0][3] = 4'd3;
        s_boxes[3][0][4] = 4'd0;  s_boxes[3][0][5] = 4'd6;  s_boxes[3][0][6] = 4'd9;  s_boxes[3][0][7] = 4'd10;
        s_boxes[3][0][8] = 4'd1;  s_boxes[3][0][9] = 4'd2;  s_boxes[3][0][10] = 4'd8; s_boxes[3][0][11] = 4'd5;
        s_boxes[3][0][12] = 4'd11; s_boxes[3][0][13] = 4'd12; s_boxes[3][0][14] = 4'd4; s_boxes[3][0][15] = 4'd15;

        s_boxes[3][1][0] = 4'd13; s_boxes[3][1][1] = 4'd8;  s_boxes[3][1][2] = 4'd11; s_boxes[3][1][3] = 4'd5;
        s_boxes[3][1][4] = 4'd6;  s_boxes[3][1][5] = 4'd15; s_boxes[3][1][6] = 4'd0;  s_boxes[3][1][7] = 4'd3;
        s_boxes[3][1][8] = 4'd4;  s_boxes[3][1][9] = 4'd7;  s_boxes[3][1][10] = 4'd2; s_boxes[3][1][11] = 4'd12;
        s_boxes[3][1][12] = 4'd1; s_boxes[3][1][13] = 4'd10; s_boxes[3][1][14] = 4'd14; s_boxes[3][1][15] = 4'd9;

        s_boxes[3][2][0] = 4'd10; s_boxes[3][2][1] = 4'd6;  s_boxes[3][2][2] = 4'd9;  s_boxes[3][2][3] = 4'd0;
        s_boxes[3][2][4] = 4'd12; s_boxes[3][2][5] = 4'd11; s_boxes[3][2][6] = 4'd7;  s_boxes[3][2][7] = 4'd13;
        s_boxes[3][2][8] = 4'd15; s_boxes[3][2][9] = 4'd1;  s_boxes[3][2][10] = 4'd3; s_boxes[3][2][11] = 4'd14;
        s_boxes[3][2][12] = 4'd5;  s_boxes[3][2][13] = 4'd2;  s_boxes[3][2][14] = 4'd8; s_boxes[3][2][15] = 4'd4;

        s_boxes[3][3][0] = 4'd3;  s_boxes[3][3][1] = 4'd15; s_boxes[3][3][2] = 4'd0;  s_boxes[3][3][3] = 4'd6;
        s_boxes[3][3][4] = 4'd10; s_boxes[3][3][5] = 4'd1;  s_boxes[3][3][6] = 4'd13; s_boxes[3][3][7] = 4'd8;
        s_boxes[3][3][8] = 4'd9;  s_boxes[3][3][9] = 4'd4;  s_boxes[3][3][10] = 4'd5; s_boxes[3][3][11] = 4'd11;
        s_boxes[3][3][12] = 4'd12; s_boxes[3][3][13] = 4'd7;  s_boxes[3][3][14] = 4'd2; s_boxes[3][3][15] = 4'd14;

        s_boxes[4][0][0] = 4'd2;  s_boxes[4][0][1] = 4'd12; s_boxes[4][0][2] = 4'd4;  s_boxes[4][0][3] = 4'd1;
        s_boxes[4][0][4] = 4'd7;  s_boxes[4][0][5] = 4'd10; s_boxes[4][0][6] = 4'd11; s_boxes[4][0][7] = 4'd6;
        s_boxes[4][0][8] = 4'd8;  s_boxes[4][0][9] = 4'd5;  s_boxes[4][0][10] = 4'd3; s_boxes[4][0][11] = 4'd15;
        s_boxes[4][0][12] = 4'd13; s_boxes[4][0][13] = 4'd0; s_boxes[4][0][14] = 4'd14; s_boxes[4][0][15] = 4'd9;

        s_boxes[4][1][0] = 4'd14; s_boxes[4][1][1] = 4'd11; s_boxes[4][1][2] = 4'd2;  s_boxes[4][1][3] = 4'd12;
        s_boxes[4][1][4] = 4'd4;  s_boxes[4][1][5] = 4'd7;  s_boxes[4][1][6] = 4'd13; s_boxes[4][1][7] = 4'd1;
        s_boxes[4][1][8] = 4'd5;  s_boxes[4][1][9] = 4'd0;  s_boxes[4][1][10] = 4'd15; s_boxes[4][1][11] = 4'd10;
        s_boxes[4][1][12] = 4'd3; s_boxes[4][1][13] = 4'd9;  s_boxes[4][1][14] = 4'd8;  s_boxes[4][1][15] = 4'd6;

        s_boxes[4][2][0] = 4'd4;  s_boxes[4][2][1] = 4'd2;  s_boxes[4][2][2] = 4'd1;  s_boxes[4][2][3] = 4'd11;
        s_boxes[4][2][4] = 4'd10; s_boxes[4][2][5] = 4'd13; s_boxes[4][2][6] = 4'd7;  s_boxes[4][2][7] = 4'd8;
        s_boxes[4][2][8] = 4'd15; s_boxes[4][2][9] = 4'd9;  s_boxes[4][2][10] = 4'd12; s_boxes[4][2][11] = 4'd5;
        s_boxes[4][2][12] = 4'd6; s_boxes[4][2][13] = 4'd3; s_boxes[4][2][14] = 4'd0; s_boxes[4][2][15] = 4'd14;

        s_boxes[4][3][0] = 4'd11; s_boxes[4][3][1] = 4'd8;  s_boxes[4][3][2] = 4'd12; s_boxes[4][3][3] = 4'd7;
        s_boxes[4][3][4] = 4'd1;  s_boxes[4][3][5] = 4'd14; s_boxes[4][3][6] = 4'd2;  s_boxes[4][3][7] = 4'd13;
        s_boxes[4][3][8] = 4'd6;  s_boxes[4][3][9] = 4'd15; s_boxes[4][3][10] = 4'd0; s_boxes[4][3][11] = 4'd9;
        s_boxes[4][3][12] = 4'd10; s_boxes[4][3][13] = 4'd4; s_boxes[4][3][14] = 4'd5; s_boxes[4][3][15] = 4'd3;
        
        s_boxes[5][0][0] = 4'd12; s_boxes[5][0][1] = 4'd1;  s_boxes[5][0][2] = 4'd10; s_boxes[5][0][3] = 4'd15;
        s_boxes[5][0][4] = 4'd9;  s_boxes[5][0][5] = 4'd2;  s_boxes[5][0][6] = 4'd6;  s_boxes[5][0][7] = 4'd8;
        s_boxes[5][0][8] = 4'd0;  s_boxes[5][0][9] = 4'd13; s_boxes[5][0][10] = 4'd3; s_boxes[5][0][11] = 4'd4;
        s_boxes[5][0][12] = 4'd14; s_boxes[5][0][13] = 4'd7; s_boxes[5][0][14] = 4'd5; s_boxes[5][0][15] = 4'd11;

        s_boxes[5][1][0] = 4'd10; s_boxes[5][1][1] = 4'd15; s_boxes[5][1][2] = 4'd4;  s_boxes[5][1][3] = 4'd2;
        s_boxes[5][1][4] = 4'd7;  s_boxes[5][1][5] = 4'd12; s_boxes[5][1][6] = 4'd9;  s_boxes[5][1][7] = 4'd5;
        s_boxes[5][1][8] = 4'd6;  s_boxes[5][1][9] = 4'd1;  s_boxes[5][1][10] = 4'd13; s_boxes[5][1][11] = 4'd14;
        s_boxes[5][1][12] = 4'd0; s_boxes[5][1][13] = 4'd11; s_boxes[5][1][14] = 4'd3;  s_boxes[5][1][15] = 4'd8;

        s_boxes[5][2][0] = 4'd9;  s_boxes[5][2][1] = 4'd14; s_boxes[5][2][2] = 4'd15; s_boxes[5][2][3] = 4'd5;
        s_boxes[5][2][4] = 4'd2;  s_boxes[5][2][5] = 4'd8;  s_boxes[5][2][6] = 4'd12; s_boxes[5][2][7] = 4'd3;
        s_boxes[5][2][8] = 4'd7;  s_boxes[5][2][9] = 4'd0;  s_boxes[5][2][10] = 4'd4; s_boxes[5][2][11] = 4'd10;
        s_boxes[5][2][12] = 4'd1; s_boxes[5][2][13] = 4'd13; s_boxes[5][2][14] = 4'd11; s_boxes[5][2][15] = 4'd6;

        s_boxes[5][3][0] = 4'd4;  s_boxes[5][3][1] = 4'd3;  s_boxes[5][3][2] = 4'd2;  s_boxes[5][3][3] = 4'd12;
        s_boxes[5][3][4] = 4'd9;  s_boxes[5][3][5] = 4'd5;  s_boxes[5][3][6] = 4'd15; s_boxes[5][3][7] = 4'd10;
        s_boxes[5][3][8] = 4'd11; s_boxes[5][3][9] = 4'd14; s_boxes[5][3][10] = 4'd1; s_boxes[5][3][11] = 4'd7;
        s_boxes[5][3][12] = 4'd6; s_boxes[5][3][13] = 4'd0; s_boxes[5][3][14] = 4'd8; s_boxes[5][3][15] = 4'd13;

        s_boxes[6][0][0] = 4'd4;  s_boxes[6][0][1] = 4'd11; s_boxes[6][0][2] = 4'd2;  s_boxes[6][0][3] = 4'd14;
        s_boxes[6][0][4] = 4'd15; s_boxes[6][0][5] = 4'd0;  s_boxes[6][0][6] = 4'd8;  s_boxes[6][0][7] = 4'd13;
        s_boxes[6][0][8] = 4'd3;  s_boxes[6][0][9] = 4'd12; s_boxes[6][0][10] = 4'd9; s_boxes[6][0][11] = 4'd7;
        s_boxes[6][0][12] = 4'd5; s_boxes[6][0][13] = 4'd10; s_boxes[6][0][14] = 4'd6; s_boxes[6][0][15] = 4'd1;

        s_boxes[6][1][0] = 4'd13; s_boxes[6][1][1] = 4'd0;  s_boxes[6][1][2] = 4'd11; s_boxes[6][1][3] = 4'd7;
        s_boxes[6][1][4] = 4'd4;  s_boxes[6][1][5] = 4'd9;  s_boxes[6][1][6] = 4'd1;  s_boxes[6][1][7] = 4'd10;
        s_boxes[6][1][8] = 4'd14; s_boxes[6][1][9] = 4'd3;  s_boxes[6][1][10] = 4'd5; s_boxes[6][1][11] = 4'd12;
        s_boxes[6][1][12] = 4'd2; s_boxes[6][1][13] = 4'd15; s_boxes[6][1][14] = 4'd8; s_boxes[6][1][15] = 4'd6;

        s_boxes[6][2][0] = 4'd1;  s_boxes[6][2][1] = 4'd4;  s_boxes[6][2][2] = 4'd11; s_boxes[6][2][3] = 4'd13;
        s_boxes[6][2][4] = 4'd12; s_boxes[6][2][5] = 4'd3;  s_boxes[6][2][6] = 4'd7;  s_boxes[6][2][7] = 4'd14;
        s_boxes[6][2][8] = 4'd10; s_boxes[6][2][9] = 4'd15; s_boxes[6][2][10] = 4'd6; s_boxes[6][2][11] = 4'd8;
        s_boxes[6][2][12] = 4'd0; s_boxes[6][2][13] = 4'd5;  s_boxes[6][2][14] = 4'd9; s_boxes[6][2][15] = 4'd2;

        s_boxes[6][3][0] = 4'd6;  s_boxes[6][3][1] = 4'd11; s_boxes[6][3][2] = 4'd13; s_boxes[6][3][3] = 4'd8;
        s_boxes[6][3][4] = 4'd1;  s_boxes[6][3][5] = 4'd4;  s_boxes[6][3][6] = 4'd10; s_boxes[6][3][7] = 4'd7;
        s_boxes[6][3][8] = 4'd9;  s_boxes[6][3][9] = 4'd5;  s_boxes[6][3][10] = 4'd0; s_boxes[6][3][11] = 4'd15;
        s_boxes[6][3][12] = 4'd14; s_boxes[6][3][13] = 4'd2;  s_boxes[6][3][14] = 4'd3; s_boxes[6][3][15] = 4'd12;

        s_boxes[7][0][0] = 4'd13; s_boxes[7][0][1] = 4'd2;  s_boxes[7][0][2] = 4'd8;  s_boxes[7][0][3] = 4'd4;
        s_boxes[7][0][4] = 4'd6;  s_boxes[7][0][5] = 4'd15; s_boxes[7][0][6] = 4'd11; s_boxes[7][0][7] = 4'd1;
        s_boxes[7][0][8] = 4'd10; s_boxes[7][0][9] = 4'd9;  s_boxes[7][0][10] = 4'd3; s_boxes[7][0][11] = 4'd14;
        s_boxes[7][0][12] = 4'd5; s_boxes[7][0][13] = 4'd0; s_boxes[7][0][14] = 4'd12; s_boxes[7][0][15] = 4'd7;

        s_boxes[7][1][0] = 4'd1;  s_boxes[7][1][1] = 4'd15; s_boxes[7][1][2] = 4'd13; s_boxes[7][1][3] = 4'd8;
        s_boxes[7][1][4] = 4'd10; s_boxes[7][1][5] = 4'd3;  s_boxes[7][1][6] = 4'd7;  s_boxes[7][1][7] = 4'd4;
        s_boxes[7][1][8] = 4'd12; s_boxes[7][1][9] = 4'd5;  s_boxes[7][1][10] = 4'd6; s_boxes[7][1][11] = 4'd11;
        s_boxes[7][1][12] = 4'd0; s_boxes[7][1][13] = 4'd14; s_boxes[7][1][14] = 4'd9; s_boxes[7][1][15] = 4'd2;

        s_boxes[7][2][0] = 4'd7;  s_boxes[7][2][1] = 4'd11; s_boxes[7][2][2] = 4'd4;  s_boxes[7][2][3] = 4'd1;
        s_boxes[7][2][4] = 4'd9;  s_boxes[7][2][5] = 4'd12; s_boxes[7][2][6] = 4'd14; s_boxes[7][2][7] = 4'd2;
        s_boxes[7][2][8] = 4'd0;  s_boxes[7][2][9] = 4'd6;  s_boxes[7][2][10] = 4'd10; s_boxes[7][2][11] = 4'd13;
        s_boxes[7][2][12] = 4'd15; s_boxes[7][2][13] = 4'd3; s_boxes[7][2][14] = 4'd5;  s_boxes[7][2][15] = 4'd8;

        s_boxes[7][3][0] = 4'd2;  s_boxes[7][3][1] = 4'd1;  s_boxes[7][3][2] = 4'd14; s_boxes[7][3][3] = 4'd7;
        s_boxes[7][3][4] = 4'd4;  s_boxes[7][3][5] = 4'd10; s_boxes[7][3][6] = 4'd8;  s_boxes[7][3][7] = 4'd13;
        s_boxes[7][3][8] = 4'd15; s_boxes[7][3][9] = 4'd12; s_boxes[7][3][10] = 4'd9; s_boxes[7][3][11] = 4'd0;
        s_boxes[7][3][12] = 4'd3; s_boxes[7][3][13] = 4'd5;  s_boxes[7][3][14] = 4'd6; s_boxes[7][3][15] = 4'd11;
        
        
        keyp[0]  = 8'd57; keyp[1] = 8'd49; keyp[2]  = 8'd41; keyp[3]  = 8'd33; keyp[4]  = 8'd25; keyp[5]  = 8'd17; keyp[6]  = 8'd9; keyp[7]  = 8'd1;
        keyp[8]  = 8'd58; keyp[9]  = 8'd50; keyp[10] = 8'd42; keyp[11] = 8'd34; keyp[12] = 8'd26; keyp[13] = 8'd18; keyp[14] = 8'd10; keyp[15] = 8'd2;
        keyp[16] = 8'd59; keyp[17] = 8'd51; keyp[18] = 8'd43; keyp[19] = 8'd35; keyp[20] = 8'd27; keyp[21] = 8'd19; keyp[22] = 8'd11; keyp[23] = 8'd3;
        keyp[24] = 8'd60; keyp[25] = 8'd52; keyp[26] = 8'd44; keyp[27] = 8'd36; keyp[28] = 8'd63; keyp[29] = 8'd55; keyp[30] = 8'd47; keyp[31] = 8'd39;
        keyp[32] = 8'd31; keyp[33] = 8'd23; keyp[34] = 8'd15; keyp[35] = 8'd7; keyp[36] = 8'd62; keyp[37] = 8'd54; keyp[38] = 8'd46; keyp[39] = 8'd38; 
        keyp[40] = 8'd30; keyp[41] = 8'd22; keyp[42] = 8'd14; keyp[43] = 8'd6; keyp[44] = 8'd61; keyp[45] = 8'd53; keyp[46] = 8'd45; keyp[47] = 8'd37;
        keyp[48] = 8'd29; keyp[49] = 8'd21;  keyp[50] = 8'd13; keyp[51] = 8'd5; keyp[52] = 8'd28; keyp[53] = 8'd20; keyp[54] = 8'd12; keyp[55] = 8'd4;
        
        key_comp[0]  = 8'd14; key_comp[1]  = 8'd17; key_comp[2]  = 8'd11; key_comp[3]  = 8'd24; key_comp[4]  = 8'd1; key_comp[5]  = 8'd5; key_comp[6]  = 8'd3; key_comp[7]  = 8'd28;
        key_comp[8]  = 8'd15; key_comp[9]  = 8'd6; key_comp[10] = 8'd21; key_comp[11] = 8'd10; key_comp[12] = 8'd23; key_comp[13] = 8'd19; key_comp[14] = 8'd12; key_comp[15] = 8'd4;
        key_comp[16] = 8'd26; key_comp[17] = 8'd8; key_comp[18] = 8'd16; key_comp[19] = 8'd7; key_comp[20] = 8'd27; key_comp[21] = 8'd20; key_comp[22] = 8'd13; key_comp[23] = 8'd2;
        key_comp[24] = 8'd41; key_comp[25] = 8'd52; key_comp[26] = 8'd31; key_comp[27] = 8'd37; key_comp[28] = 8'd47; key_comp[29] = 8'd55; key_comp[30] = 8'd30; key_comp[31] = 8'd40;
        key_comp[32] = 8'd51; key_comp[33] = 8'd45; key_comp[34] = 8'd33; key_comp[35] = 8'd48; key_comp[36] = 8'd44; key_comp[37] = 8'd49; key_comp[38] = 8'd39; key_comp[39] = 8'd56;
        key_comp[40] = 8'd34; key_comp[41] = 8'd53; key_comp[42] = 8'd46; key_comp[43] = 8'd42; key_comp[44] = 8'd50; key_comp[45] = 8'd36; key_comp[46] = 8'd29; key_comp[47] = 8'd32;
        
        per[0] = 8'd16; per[1] = 8'd7; per[2] = 8'd20; per[3] = 8'd21;
        per[4] = 8'd29; per[5] = 8'd12; per[6] = 8'd28; per[7] = 8'd17;
        per[8] = 8'd1; per[9] = 8'd15; per[10] = 8'd23; per[11] = 8'd26;
        per[12] = 8'd5; per[13] = 8'd18; per[14] = 8'd31; per[15] = 8'd10;
        per[16] = 8'd2; per[17] = 8'd8; per[18] = 8'd24; per[19] = 8'd14;
        per[20] = 8'd32; per[21] = 8'd27; per[22] = 8'd3; per[23] = 8'd9;
        per[24] = 8'd19; per[25] = 8'd13; per[26] = 8'd30; per[27] = 8'd6;
        per[28] = 8'd22; per[29] = 8'd11; per[30] = 8'd4; per[31] = 8'd25;
        
        for (i = 0; i < 48; i = i + 1) temp_key_comp[i] = key_comp[i]; //read from BRAM
        for(i = 0; i < 56; i = i + 1) temp_keyp[i] = keyp[i]; //read from BRAM
        for (i = 0; i < 32; i = i + 1) temp_per[i] = per[i];
        
        key = permute(keyphrase, temp_keyp, 8'd56);
        key_left = key[27:0]; key_right = key[55:28];
        for (i = 0; i < 16; i = i + 1) begin
        key_left = (j == 1 || j == 2|| j == 9 ||j == 16) ? key_left << 1 : key_left << 2;
        key_right = (j == 1 || j == 2|| j == 9 ||j == 16) ? key_right << 1 : key_right << 2;
            rkb[i] = permute((key_left + key_right), temp_key_comp, 8'd48);
            rkb_rev[i] = rkb[15-i];
        end
        
        encrypted = encrypt(data_in);
    end
*/
/*reg [223:0] keyp = {8'd57, 8'd49, 8'd41, 8'd33, 8'd25, 8'd17, 8'd9, 8'd1, 
                        8'd58, 8'd50, 8'd42, 8'd34, 8'd26, 8'd18, 8'd10, 8'd2, 
                        8'd59, 8'd51, 8'd43, 8'd35, 8'd27, 8'd19, 8'd11, 8'd3, 
                        8'd60, 8'd52, 8'd44, 8'd36, 8'd63, 8'd55, 8'd47, 8'd39, 
                        8'd31, 8'd23, 8'd15, 8'd7, 8'd62, 8'd54, 8'd46, 8'd38, 
                        8'd30, 8'd22, 8'd14, 8'd6, 8'd61, 8'd53, 8'd45, 8'd37, 
                        8'd29, 8'd21, 8'd13, 8'd5, 8'd28, 8'd20, 8'd12, 8'd4}; */
/*
    function [63:0] encrypt(
        input [63:0] plaintext
    ); begin
        initial_permute = permute(plaintext, initial_permutation_table, 8'd64);
        left = initial_permute[31:0]; right = initial_permute[63:32];
        for (j = 0; j < 16; j = j + 1) begin
            
            right_expanded = permute(right, expansion_table, 48);
            xor_intermediate = right_expanded ^ rkb[i];
            for (k = 0; k < 8; k = k + 1) begin
                row = xor_intermediate[6 * k] + xor_intermediate[k * 6 + 5];
                col = xor_intermediate[6 * k + 1] + xor_intermediate[6 * k + 2] + xor_intermediate[6 * k + 3] + xor_intermediate[6 * k + 4];
                temp_val[j] = s_boxes[j][row][col];
            end
            d_box = permute(temp_val, temp_per, 32);
            left = left ^ d_box;
            if (j != 15) begin
                to_swap = left;
                left = right;
                right = to_swap;
            end
        end
        combine = left + right;
        encrypt = permute(combine, final_permutation_table, 64);
    end
    endfunction
*/

endmodule
