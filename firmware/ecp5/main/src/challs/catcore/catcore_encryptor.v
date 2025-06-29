module catcore_decryptor(input clk, input [15:0] ciphertext, output [15:0] plaintext);
    assign plaintext = ciphertext ^ "AAAAAAAAAAAAAAAA";
endmodule
