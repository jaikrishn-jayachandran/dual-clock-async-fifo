`timescale 1ns/1ps

// =================================================
// Gray to Binary Converter
// =================================================

module binary_to_gray #(
    parameter int PTR_WIDTH = 9 // 8 bits + 1 bit for full/empty flag

) (
    input logic [PTR_WIDTH-1:0] binary_in,
    output logic [PTR_WIDTH-1:0] gray_out
);

    assign gray_out = binary_in ^ (binary_in >> 1);

endmodule
