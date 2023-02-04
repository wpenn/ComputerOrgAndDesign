/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup


   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/
   
   //STAGE: FETCHING
   

   wire stall_load = is_load_X && ((r1sel_D_pre == wsel_X && r1re_D_pre) ||
                     ((r2sel_D_pre == wsel_X && r2re_D_pre) && ~is_store_D_pre));
   wire not_stall_q = ~stall_load && (~is_load_X || ~is_branch_D_pre);
   wire branched_q = (is_control_insn_X) || (is_branch_X & nzp_correct);
   wire [15:0] i_cur_insn_F = branched_q ? 16'b0 : i_cur_insn;
   wire [15:0] pc_F = branched_q ? 16'b0 : pc;
   wire [1:0] stall_F = branched_q ? 2'd2 : (not_stall_q ? 2'd0 : 2'd3);

   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(not_stall_q), .gwe(gwe), .rst(rst));

   
   //STAGE: DECODING
   wire [15:0] pc_D_pre, i_cur_insn_D_pre;


   Nbit_reg #(16, 16'h8200) pc_reg_D (.in(pc_F), .out(pc_D_pre), .clk(clk), .we(not_stall_q), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) i_cur_insn_reg_D (.in(i_cur_insn_F), .out(i_cur_insn_D_pre), .clk(clk), .we(not_stall_q), .gwe(gwe), .rst(rst));
   
   wire [1:0] stall_D_pre;
   Nbit_reg #(2, 2'b10) stall_reg_D(.in(stall_F), .out(stall_D_pre), .clk(clk), .we(not_stall_q), .gwe(gwe), .rst(rst));
   wire [2:0] r1sel_D_pre, r2sel_D_pre, wsel_D_pre;
   wire r1re_D_pre, r2re_D_pre, regfile_we_D_pre, nzp_we_D_pre, select_pc_plus_one_D_pre, is_load_D_pre, is_store_D_pre, is_branch_D_pre, is_control_insn_D_pre;
   lc4_decoder decodermain(.insn(i_cur_insn_D_pre),  .r1sel(r1sel_D_pre), .r1re(r1re_D_pre), .r2sel(r2sel_D_pre), .r2re(r2re_D_pre), .wsel(wsel_D_pre), .regfile_we(regfile_we_D_pre), .nzp_we(nzp_we_D_pre), .select_pc_plus_one(select_pc_plus_one_D_pre), .is_load(is_load_D_pre), .is_store(is_store_D_pre), .is_branch(is_branch_D_pre), .is_control_insn(is_control_insn_D_pre));


   wire [15:0] o_rs_data1, o_rt_data1;
   lc4_regfile #(16) theregisterfile(.clk(clk), .gwe(gwe), .rst(rst),
    .i_rs(r1sel_D_pre),      // rs selector
    .o_rs_data(o_rs_data1), // rs contents
    .i_rt(r2sel_D_pre),      // rt selector
    .o_rt_data(o_rt_data1), // rt contents
    .i_rd_we(regfile_we_W),    // write enable
    .i_rd(wsel_W),      // rd selector -- comes from WRITEBACK
    .i_wdata(i_wdata)   // data to write -- comes from WRITEBACK
    );
   

   //bypass wd
   wire[15:0] o_rs_data = (r1sel_D_pre == wsel_W) && regfile_we_W && r1re_D_pre ? i_wdata : o_rs_data1;
   wire[15:0] o_rt_data = (r2sel_D_pre == wsel_W) && regfile_we_W && r2re_D_pre ? i_wdata : o_rt_data1;

   wire [15:0] pc_plus_1, pc_plus_1_D;
   cla16 cla_one(.a(pc), .b(0), .cin(1), .sum(pc_plus_1));
   Nbit_reg #(16, 16'b0) pc_plus_one_reg_D(.in(pc_plus_1), .out(pc_plus_1_D), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));



   wire r1re_D, r2re_D, regfile_we_D, nzp_we_D, select_pc_plus_one_D, is_load_D, is_store_D, is_branch_D, is_control_insn_D;
   wire nop_question = branched_q || ~not_stall_q;
   wire [15:0] pc_D = nop_question ? 16'b0 :  pc_D_pre;
   wire[15:0] i_cur_insn_D = nop_question ? 16'b0 :  i_cur_insn_D_pre;
   wire [2:0] r1sel_D,r2sel_D, wsel_D;
   assign r1sel_D = nop_question ? 3'b0 :  r1sel_D_pre;
   assign r2sel_D = nop_question ? 3'b0 :  r2sel_D_pre;
   assign wsel_D = nop_question ? 3'b0 :  wsel_D_pre;
   assign r1re_D = nop_question ? 1'b0 :  r1re_D_pre;
   assign r2re_D = nop_question ? 1'b0 :  r2re_D_pre;
   assign regfile_we_D = nop_question ? 1'b0 :  regfile_we_D_pre;
   assign select_pc_plus_one_D = nop_question ? 1'b0 :  select_pc_plus_one_D_pre;
   assign is_load_D = nop_question ? 1'b0 : is_load_D_pre;
   assign is_store_D = nop_question ? 1'b0 :  is_store_D_pre;
   assign is_branch_D = nop_question ? 1'b0 :  is_branch_D_pre;
   assign is_control_insn_D = nop_question ? 1'b0 :  is_control_insn_D_pre;
   assign nzp_we_D = nop_question ? 1'b0 :  nzp_we_D_pre;
   wire [1:0] stall_D = branched_q ? 2'b10 : (not_stall_q ? stall_D_pre : 2'b11);

   //STAGE: EXECUTE
   wire [1:0] stall_X;
   wire [2:0] r1sel_X,r2sel_X, wsel_X;
   wire r1re_X, r2re_X, regfile_we_X, nzp_we_X, select_pc_plus_one_X, is_load_X, is_store_X, is_branch_X, is_control_insn_X;
   wire [15:0] pc_X, o_rs_data_X, o_rt_data_X, i_cur_insn_X, pc_plus_1_X;
   Nbit_reg #(2, 2'b10) stall_reg_X(.in(stall_D), .out(stall_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg_X (.in(pc_D), .out(pc_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) reg_rs_X (.in(o_rs_data), .out(o_rs_data_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) reg_rt_X (.in(o_rt_data), .out(o_rt_data_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) pc_plus_one_reg_X(.in(pc_plus_1_D), .out(pc_plus_1_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r1sel_reg_X (.in(r1sel_D), .out(r1sel_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_X (.in(r2sel_D), .out(r2sel_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_X (.in(wsel_D), .out(wsel_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r1re_reg_X (.in(r1re_D), .out(r1re_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r2re_reg_X (.in(r2re_D), .out(r2re_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_X (.in(regfile_we_D), .out(regfile_we_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_X (.in(nzp_we_D), .out(nzp_we_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_X (.in(select_pc_plus_one_D), .out(select_pc_plus_one_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_X (.in(is_load_D), .out(is_load_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_store_reg_X (.in(is_store_D), .out(is_store_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_branch_reg_X (.in(is_branch_D), .out(is_branch_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_control_insn_reg_X (.in(is_control_insn_D), .out(is_control_insn_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_X (.in(i_cur_insn_D), .out(i_cur_insn_X), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));





   //bypass
   wire [15:0] bypass_r1_1 = (r1sel_X == wsel_W) && regfile_we_W ? i_wdata : o_rs_data_X;
   wire [15:0] bypass_r2_1 = (r2sel_X == wsel_W) && regfile_we_W ? i_wdata : o_rt_data_X;
   
   wire [15:0] bypass_r1_full = (r1sel_X == wsel_M) && regfile_we_M ? alu_result_M : bypass_r1_1;
   wire [15:0] bypass_r2_full = (r2sel_X == wsel_M) && regfile_we_M ? alu_result_M : bypass_r2_1;


   wire [15:0] alu_result;
   lc4_alu alu_main(.i_insn(i_cur_insn_X), .i_pc(pc_X), .i_r1data(bypass_r1_full), .i_r2data(bypass_r2_full),
               .o_result(alu_result));

   //STAGE: DATAMEM

   //pipeline registers
   wire [1:0] stall_M;
   Nbit_reg #(2, 2'b10) stall_reg_M(.in(stall_X), .out(stall_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire [15:0] pc_M;
   Nbit_reg #(16, 16'h8200) pc_reg_M (.in(pc_X), .out(pc_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] o_rs_data_M;
   wire [15:0] o_rt_data_M_1;
   wire [15:0] alu_result_M;

   Nbit_reg #(16, 0) reg_rs_M (.in(bypass_r1_full), .out(o_rs_data_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) reg_rt_M (.in(bypass_r2_full), .out(o_rt_data_M_1), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_result_reg_M (.in(alu_result), .out(alu_result_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire[15:0] pc_plus_1_M;
   Nbit_reg #(16, 16'b0) pc_plus_one_reg_M(.in(pc_plus_1_X), .out(pc_plus_1_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [15:0] i_cur_insn_M;

   wire [2:0] r1sel_M, r2sel_M, wsel_M;
   wire r1re_M, r2re_M, regfile_we_M, nzp_we_M, select_pc_plus_one_M, is_load_M, is_store_M, is_branch_M, is_control_insn_M;
   
   Nbit_reg #(3, 0) r1sel_reg_M (.in(r1sel_X), .out(r1sel_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_M (.in(r2sel_X), .out(r2sel_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_M (.in(wsel_X), .out(wsel_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r1re_reg_M (.in(r1re_X), .out(r1re_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r2re_reg_M (.in(r2re_X), .out(r2re_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_M (.in(regfile_we_X), .out(regfile_we_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_M (.in(nzp_we_X), .out(nzp_we_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_M (.in(select_pc_plus_one_X), .out(select_pc_plus_one_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_M (.in(is_load_X), .out(is_load_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_store_reg_M (.in(is_store_X), .out(is_store_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_branch_reg_M (.in(is_branch_X), .out(is_branch_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_control_insn_reg_M (.in(is_control_insn_X), .out(is_control_insn_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_M (.in(i_cur_insn_X), .out(i_cur_insn_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //wm bypass
   wire [15:0] o_rt_data_M =  regfile_we_W && is_store_M && r2sel_M == wsel_W ? i_wdata : o_rt_data_M_1;

   wire [15:0] o_dmem_towrite_M = is_store_M ? o_rt_data_M : 16'b0;
   wire o_dmem_we_M = is_store_M;
   wire [15:0] o_dmem_addr_M = (is_load_M | is_store_M) ? alu_result_M : 16'b0;
   
   assign o_dmem_we = o_dmem_we_M;
   assign o_dmem_addr = o_dmem_addr_M;
   assign o_dmem_towrite = o_dmem_towrite_M;
   wire [15:0] i_cur_dmem_data_M = i_cur_dmem_data;
   

   //STAGE WRITEBACK
   Nbit_reg #(2, 2'b10) stall_reg_W(.in(stall_M), .out(test_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] o_dmem_addr_W, o_dmem_towrite_W, i_cur_dmem_data_W;
   wire o_dmem_we_W;

   Nbit_reg #(16, 0) o_dem_addr_reg_W (.in(o_dmem_addr_M), .out(o_dmem_addr_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) o_dem_towrite_reg_W (.in(o_dmem_towrite_M), .out(o_dmem_towrite_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) o_dem_we_reg_W (.in(o_dmem_we_M), .out(o_dmem_we_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_dmem_data_reg_W (.in(i_cur_dmem_data_M), .out(i_cur_dmem_data_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire[15:0] pc_plus_1_W;
   Nbit_reg #(16, 16'b0) pc_plus_one_reg_W(.in(pc_plus_1_M), .out(pc_plus_1_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire [15:0] pc_W;
   Nbit_reg #(16, 16'h8200) pc_reg_W (.in(pc_M), .out(pc_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] o_rs_data_W;
   wire [15:0] o_rt_data_W;
   wire [15:0] alu_result_W;

   Nbit_reg #(16, 0) reg_rs_W (.in(o_rs_data_M), .out(o_rs_data_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) reg_rt_W (.in(o_rt_data_M), .out(o_rt_data_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_result_reg_W (.in(alu_result_M), .out(alu_result_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));



   wire [15:0] i_cur_insn_W;

   wire [2:0] r1sel_W, r2sel_W, wsel_W;
   wire r1re_W, r2re_W, regfile_we_W, nzp_we_W, select_pc_plus_one_W, is_load_W, is_store_W, is_branch_W, is_control_insn_W;
   
   Nbit_reg #(3, 0) r1sel_reg_W (.in(r1sel_M), .out(r1sel_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_W (.in(r2sel_M), .out(r2sel_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_W (.in(wsel_M), .out(wsel_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r1re_reg_W (.in(r1re_M), .out(r1re_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r2re_reg_W (.in(r2re_M), .out(r2re_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_W (.in(regfile_we_M), .out(regfile_we_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_W (.in(nzp_we_M), .out(nzp_we_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_W (.in(select_pc_plus_one_M), .out(select_pc_plus_one_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_W (.in(is_load_M), .out(is_load_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_store_reg_W (.in(is_store_M), .out(is_store_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_branch_reg_W (.in(is_branch_M), .out(is_branch_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_control_insn_reg_W (.in(is_control_insn_M), .out(is_control_insn_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_W (.in(i_cur_insn_M), .out(i_cur_insn_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   

   wire [15:0] nzp_new_bits_input = is_load_M && stall_X == 2'd3 ? i_cur_dmem_data :
                                    (is_control_insn_X ? pc_X :
                                     alu_result);

   wire [2:0] nzp_new_bits = ($signed(nzp_new_bits_input) == 0) ? 3'b010 : 
                        ($signed(nzp_new_bits_input) > 0) ? 3'b001 :
                        3'b100;

   wire [2:0] nzp_new_bits_M;
   Nbit_reg #(3, 0) nzp_reg_M (.in(nzp_new_bits), .out(nzp_new_bits_M), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] nzp_new_bits_W;
   Nbit_reg #(3, 0) nzp_reg_W (.in(nzp_new_bits_M), .out(nzp_new_bits_W), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire nzp_correct = i_cur_insn_X[11] == 1 & nzp_old_bits == 3'b100 | 
                     i_cur_insn_X[10] == 1 & nzp_old_bits == 3'b010 |
                     i_cur_insn_X[9] == 1 & nzp_old_bits == 3'b001;

   wire [2:0] nzp_old_bits;
   Nbit_reg #(3, 0) nzp_reg (.in(nzp_new_bits), .out(nzp_old_bits), .clk(clk), .we(nzp_we_X), .gwe(gwe), .rst(rst));

   assign next_pc = (branched_q) ? alu_result : pc_plus_1;

   wire [15:0] alu_datamem_output = is_load_W ? i_cur_dmem_data_W : alu_result_W;
   wire [15:0] i_wdata = (select_pc_plus_one_W ? pc_plus_1_W : alu_datamem_output);

   assign test_cur_pc = pc_W;
   assign test_cur_insn = i_cur_insn_W;
   assign test_regfile_wsel = wsel_W;
   assign test_regfile_data = regfile_we_W ? i_wdata : 16'b0;
   assign test_nzp_we = nzp_we_W;
   assign test_dmem_we = is_store_W;
   assign test_nzp_new_bits = is_load_W ? ($signed(i_cur_dmem_data_W) == 0) ? 3'b010 : 
                        ($signed(i_cur_dmem_data_W) > 0) ? 3'b001 :
                        3'b100 : nzp_new_bits_W;
   assign test_dmem_addr = o_dmem_addr_W;
   assign test_dmem_data = is_store_W ? o_dmem_towrite_W : (is_load_W ? i_cur_dmem_data_W : 16'b0);
   assign test_regfile_we = regfile_we_W;
   assign o_cur_pc = pc;

`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      // $display("Stall F: %h , stall D: %h, stall x: %h", stall_F, stall_D, stall_X);
      // $display("Branched_q : %h , Not_stall_Q: %h, Stall_D_pre: %h", branched_q, not_stall_q, stall_D_pre);
      // pinstr(i_cur_insn_W);
      // $display("\n");
      
      // $display("pc: %h | pc_D: %h | pc_X: %h | pc_M: %h | pc_W: %h | alu_W: %h | regfile in: %h", pc, pc_D, pc_X, pc_M, pc_W, alu_result_W, test_regfile_data);
      // $display("pc: %h | pc_W: %h | ALU_RESULT: %h | ALU_M: %h | ALU_W: %h | regfile in: %h", pc, pc_W, alu_result, alu_result_M, alu_result_W, test_regfile_data);
      // $display("nzp_new: %h -- nzp_old: %h", nzp_new_bits, nzp_old_bits);
      
      // if (pc_D > 16'h8211 && pc_D < 16'h8219) begin
      //    $display("%h -- %h", pc_D,  stall_load);
      //    // is_load_X && ((r1sel_D_pre == wsel_X) || ((r2sel_D_pre == wsel_X) && ~is_store_D_pre)))
      //    $display("is_load_X: %h -- isload_D: %h -- isload_D_pre: %h -- r1sel_D: %h -- r2sel_D %h -- wsel_D: %h -- wsel_X: %h", is_load_X, is_load_D, is_load_D_pre, r1sel_D_pre, r2sel_D_pre, wsel_D, wsel_X);
         
      // end
   end
`endif
endmodule
