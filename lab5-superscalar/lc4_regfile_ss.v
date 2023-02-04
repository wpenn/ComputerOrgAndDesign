`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/
    wire [7:0] registers_write_q_A;
    wire [7:0] registers_write_q_B;
    wire [n-1:0] o_data_temp_B [7:0];
    wire [n-1:0] o_data_temp_A [7:0];
    wire [n-1:0] o_data_temp_pre [7:0];
    
    genvar i;
    for (i = 0; i < 8; i=i+1) begin
        assign registers_write_q_A[i] = (i_rd_A == i) & i_rd_we_A;
        assign registers_write_q_B[i] = (i_rd_B == i) & i_rd_we_B;
        Nbit_reg #(n, 0) thing_register(.in(registers_write_q_B[i] ? i_wdata_B : i_wdata_A), .out(o_data_temp_pre[i]), .clk(clk), .we(registers_write_q_A[i] | registers_write_q_B[i]), .gwe(gwe), .rst(rst));
        assign o_data_temp_A[i] = registers_write_q_B[i] ? i_wdata_B : registers_write_q_A[i] ? i_wdata_A : o_data_temp_pre[i];
        assign o_data_temp_B[i] = registers_write_q_B[i] ? i_wdata_B : registers_write_q_A[i] ? i_wdata_A :  o_data_temp_pre[i];
    end

                       
    assign o_rs_data_A = o_data_temp_A[i_rs_A];
    assign o_rt_data_A = o_data_temp_A[i_rt_A];

    assign o_rs_data_B = o_data_temp_B[i_rs_B];
    assign o_rt_data_B = o_data_temp_B[i_rt_B];
endmodule
