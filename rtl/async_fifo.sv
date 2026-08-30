`timescale 1ns/1ps

// =================================================
// Asynchronous FIFO module
// =================================================

module async_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 8
)(
    input logic iso_en,


    input logic wclk,
    input logic wrst_n,
    input logic w_inc,
    output logic w_full,
    input logic [DATA_WIDTH-1:0] w_data,


    input logic rclk,
    input logic rrst_n,
    input logic r_inc,
    output logic r_empty,
    output logic [DATA_WIDTH-1:0] r_data
);

    logic [ADDR_WIDTH-1:0] w_addr;
    logic [ADDR_WIDTH-1:0] r_addr;

    logic [ADDR_WIDTH:0] w_ptr_gray;
    logic [ADDR_WIDTH:0] r_ptr_gray;

    logic [ADDR_WIDTH:0] r_ptr_sync_gray;
    logic [ADDR_WIDTH:0] w_ptr_sync_gray;

    dual_port_bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_bram (
        .iso_en(iso_en),
        .wclk(wclk),
        .w_en(w_inc & ~w_full),
        .w_addr(w_addr),
        .w_data(w_data),

        .rclk(rclk),
        .rrst_n(rrst_n),
        .r_en(r_inc & ~r_empty),
        .r_addr(r_addr),
        .r_q_iso(r_data)
    );

    fifo_controller #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo_ctrl (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .w_inc(w_inc),
        .w_full(w_full),
        .w_addr(w_addr),
        .w_ptr_gray(w_ptr_gray),
        .r_ptr_sync_gray(r_ptr_sync_gray),

        .rclk(rclk),
        .rrst_n(rrst_n),
        .r_inc(r_inc),
        .r_empty(r_empty),
        .r_addr(r_addr),
        .r_ptr_gray(r_ptr_gray),
        .w_ptr_sync_gray(w_ptr_sync_gray)
    );

    // CDC(Clock domain crossing) for read pointer from read domain to write domain
    
    logic [ADDR_WIDTH:0] r_ptr_gray_meta;
    always_ff @(posedge wclk or negedge wrst_n)begin
        if(!wrst_n)begin
            r_ptr_sync_gray <= 0;
            r_ptr_gray_meta <= 0;
        end else begin
            r_ptr_gray_meta <= r_ptr_gray;
            r_ptr_sync_gray <= r_ptr_gray_meta;
        end
    end

    logic [ADDR_WIDTH:0] w_ptr_gray_meta;
    always_ff @(posedge rclk or negedge rrst_n)begin
        if(!rrst_n)begin
            w_ptr_sync_gray <= 0;
            w_ptr_gray_meta <= 0;
        end else begin
            w_ptr_gray_meta <= w_ptr_gray;
            w_ptr_sync_gray <= w_ptr_gray_meta;
        end
    end

endmodule