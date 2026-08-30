`timescale 1ns/1ps

// =================================================
// Gray to Binary Converter
// =================================================

module gray_to_binary #(
    parameter int PTR_WIDTH = 9 // 8 bits + 1 bit for full/empty flag

) (
    input logic [PTR_WIDTH-1:0] gray_in,
    output logic [PTR_WIDTH-1:0] binary_out
);

    genvar i;
    generate
        assign binary_out[PTR_WIDTH-1] = gray_in[PTR_WIDTH-1];
        for (i = PTR_WIDTH-2; i >= 0; i--) begin : gen_b2g
            assign binary_out[i] = binary_out[i+1] ^ gray_in[i];
        end
    endgenerate

endmodule