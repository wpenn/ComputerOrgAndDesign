`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/

   //STAGE: FETCH
   wire [15:0] pc;
   wire [15:0] next_pc = branched_q_A ? alu_result_A :
                         branched_q_B ? alu_result_B :  
                         pipe_switch_q ? pc_plus_1 :
                         pc_plus_2;

   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   
   wire [15:0] pc_plus_1, pc_plus_2;
   cla16 cla_one(.a(pc), .b(0), .cin(1), .sum(pc_plus_1)); 
   cla16 cla_two(.a(pc), .b(2), .cin(0), .sum(pc_plus_2));  
   

   //STAGE: Decode - Registers A

   wire [1:0] stall_F_A = 2'b0;

   wire [15:0] pc_F_A = pipe_switch_q ? pc_D_B : pc;
   wire [15:0] pc_plus_1_F_A = pipe_switch_q ? pc_plus_1_D_B : pc_plus_1;
   wire [15:0] i_cur_insn_F_A = pipe_switch_q ? i_cur_insn_D_B : i_cur_insn_A;
   

   wire [15:0] pc_D_A, pc_plus_1_D_A, i_cur_insn_D_A;
   wire [1:0] stall_D_A;
   wire branched_q_D;
   Nbit_reg #(1, 0) branched_q_reg_D_A (.in(branched_q), .out(branched_q_D), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_reg_D_A (.in(pc_F_A), .out(pc_D_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_D_reg_A (.in(pc_plus_1_F_A), .out(pc_plus_1_D_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_D_A (.in(i_cur_insn_F_A), .out(i_cur_insn_D_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) stall_reg_D_A (.in(stall_F_A), .out(stall_D_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  

   //STAGE: Decode - DECODER A
   wire nzp_we_D_A;
   wire [2:0] r1sel_D_A, r2sel_D_A, wsel_D_A;
   wire regfile_we_D_A, select_pc_plus_one_D_A, is_load_D_A, r1re_D_A, r2re_D_A, is_store_D_A, is_branch_D_A, is_control_insn_D_A;
   lc4_decoder decoderA (.insn(i_cur_insn_D_A), .r1sel(r1sel_D_A), .r1re(r1re_D_A), .r2sel(r2sel_D_A), .r2re(r2re_D_A), .wsel(wsel_D_A), .regfile_we(regfile_we_D_A), .nzp_we(nzp_we_D_A), .select_pc_plus_one(select_pc_plus_one_D_A), .is_load(is_load_D_A), .is_store(is_store_D_A), .is_branch(is_branch_D_A), .is_control_insn(is_control_insn_D_A));

   wire branch_check_A = is_load_X_A && branched_q_A;
   wire check_A_uses_A = is_load_X_A && 
                         (wsel_X_A == r1sel_D_A && r1re_D_A || 
                         wsel_X_A == r2sel_D_A && r2re_D_A && ~is_store_D_A);
   wire check_A_uses_B = is_load_X_B && ~branched_q_A && 
                         (wsel_X_B == r1sel_D_A && r1re_D_A || 
                         wsel_X_B == r2sel_D_A && r2re_D_A && ~is_store_D_A);
   wire load_to_use_A =  branch_check_A || check_A_uses_B || check_A_uses_A;

   
   wire [1:0] stall_D_A_new = branched_q || branched_q_D ? 2'b10 :
                              load_to_use_A ? 2'b11 :
                              stall_D_A;

   
   //STAGE: Decode - Registers B

   wire [1:0] stall_F_B = 2'b0;
   wire pipe_switch_q = stall_D_B_new == 1;
   
   wire [15:0] pc_F_B = pipe_switch_q ? pc : pc_plus_1;
   wire [15:0] pc_plus_1_F_B = pipe_switch_q ? pc_plus_1 : pc_plus_2;
   wire [15:0] i_cur_insn_F_B = pipe_switch_q ? i_cur_insn_A : i_cur_insn_B;

   wire [15:0] i_cur_insn_D_B, pc_D_B, pc_plus_1_D_B;
   wire [1:0] stall_D_B;
   Nbit_reg #(16, 0) pc_reg_D_B (.in(pc_F_B), .out(pc_D_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_D_B (.in(pc_plus_1_F_B), .out(pc_plus_1_D_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_D_B (.in(i_cur_insn_F_B), .out(i_cur_insn_D_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) stall_reg_D_B (.in(stall_F_B), .out(stall_D_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //STAGE: Decode - DECODER B
   wire [2:0] r1sel_D_B, r2sel_D_B, wsel_D_B;
   wire nzp_we_B,regfile_we_D_B, select_pc_plus_one_D_B, is_load_D_B, r1re_D_B, r2re_D_B, is_store_D_B, is_branch_D_B, is_control_insn_D_B;
   lc4_decoder decoder (.insn(i_cur_insn_D_B), .r1sel(r1sel_D_B), .r1re(r1re_D_B), .r2sel(r2sel_D_B), .r2re(r2re_D_B), .wsel(wsel_D_B), .regfile_we(regfile_we_D_B), .nzp_we(nzp_we_B), .select_pc_plus_one(select_pc_plus_one_D_B), .is_load(is_load_D_B), .is_store(is_store_D_B), .is_branch(is_branch_D_B), .is_control_insn(is_control_insn_D_B));

   wire branch_check_B = (is_load_X_B || is_load_X_A) && branched_q_B;
   wire B_B_check = is_load_X_B && 
                    (wsel_X_B == r1sel_D_B && r1re_D_B || 
                    wsel_X_B == r2sel_D_B && r2re_D_B && ~is_store_D_B);
   wire B_A_check = is_load_X_A && 
                    (wsel_X_A == r1sel_D_B && r1re_D_B || 
                    wsel_X_A == r2sel_D_B && r2re_D_B && ~is_store_D_B);

   wire load_to_use_B = branch_check_B || B_A_check || B_B_check;

   wire is_pipe_switch_stall = regfile_we_D_A && 
                               (r1sel_D_B == wsel_D_A && r1re_D_B || 
                               r2sel_D_B == wsel_D_A && r2re_D_B && ~is_store_D_B) ||
                               mem_stall_q || load_to_use_A || is_branch_D_B;

   wire [1:0] stall_D_B_new = branched_q_D || branched_q ? 2'b10 : 
                              is_pipe_switch_stall ? 2'b01 :
                              load_to_use_B ? 2'b11 :
                              stall_D_B;

   wire [15:0] o_rs_data_D_A, o_rt_data_D_A, o_rs_data_B, o_rt_data_D_B;
   wire regfile_we_W_D_A, regfile_we_W_D_B;
   
   wire [2:0]  wsel_W_A, wsel_W_B;
   wire load_store_D_B = is_load_D_B || is_store_D_B;
   wire load_store_D_A = is_load_D_A || is_store_D_A;
   wire mem_stall_q = load_store_D_B && load_store_D_A;

   lc4_regfile_ss reg_file (.clk(clk), .gwe(gwe), .rst(rst), .i_rs_A(r1sel_D_A), .o_rs_data_A(o_rs_data_D_A), .i_rt_A(r2sel_D_A), .o_rt_data_A(o_rt_data_D_A), .i_rs_B(r1sel_D_B), .o_rs_data_B(o_rs_data_B), .i_rt_B(r2sel_D_B), .o_rt_data_B(o_rt_data_D_B), .i_rd_A(wsel_W_A), .i_wdata_A(i_wdata_A), .i_rd_we_A(regfile_we_W_D_A), .i_rd_B(wsel_W_B), .i_wdata_B(i_wdata_B), .i_rd_we_B(regfile_we_W_D_B)); 


   //STAGE: EXECUTE
   //STAGE: Execute - Registers A
   
   wire [15:0] pc_X_A, pc_plus_1_X_A, i_cur_insn_X_A, o_rs_data_X_A, o_rt_data_X_A;
   wire select_pc_plus_one_X_A, nzp_we_X_A, is_control_insn_X_A, is_branch_X_A, regfile_we_X_A, r1re_X_A, r2re_X_A, is_load_X_A, is_store_X_A;
   wire [1:0] stall_X_A;
   wire [2:0] r1sel_X_A, r2sel_X_A, wsel_X_A;
   
   wire flush_rst_A = rst || branched_q || load_to_use_A || branched_q_D;

   Nbit_reg #(16, 0) pc_reg_X_A (.in(pc_D_A), .out(pc_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_X_A (.in(pc_plus_1_D_A), .out(pc_plus_1_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_X_A (.in(i_cur_insn_D_A), .out(i_cur_insn_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_X_A (.in(wsel_D_A), .out(wsel_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_X_A (.in(nzp_we_D_A), .out(nzp_we_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_X_A (.in(select_pc_plus_one_D_A), .out(select_pc_plus_one_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_X_A (.in(is_load_D_A), .out(is_load_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(1, 0) is_store_reg_X_A (.in(is_store_D_A), .out(is_store_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(1, 0) is_control_reg_X_A (.in(is_control_insn_D_A), .out(is_control_insn_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(1, 0) is_branch_reg_X_A (.in(is_branch_D_A), .out(is_branch_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(1, 0) regfile_we_reg_X_A (.in(regfile_we_D_A), .out(regfile_we_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(2, 2'b10) stall_reg_X_A (.in(stall_D_A_new), .out(stall_X_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r1sel_reg_X_A (.in(r1sel_D_A), .out(r1sel_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) r1data_reg_X_A (.in(o_rs_data_D_A), .out(o_rs_data_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r1re_reg_X_A (.in(r1re_D_A), .out(r1re_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(3, 0) r2sel_reg_X_A (.in(r2sel_D_A), .out(r2sel_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) r2re_reg_X_A (.in(r2re_D_A), .out(r2re_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(flush_rst_A));
   Nbit_reg #(16, 0) r2data_reg_X_A (.in(o_rt_data_D_A), .out(o_rt_data_X_A), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));

   

   wire [15:0] bypass_rs_wx_A = r1sel_X_A == wsel_W_B && regfile_we_W_D_B ? i_wdata_B : 
                                r1sel_X_A == wsel_W_A && regfile_we_W_D_A ? i_wdata_A : 
                                o_rs_data_X_A;

   wire [15:0] bypass_rt_wx_A = r2sel_X_A == wsel_W_B && regfile_we_W_D_B ? i_wdata_B : 
                                r2sel_X_A == wsel_W_A && regfile_we_W_D_A ? i_wdata_A : 
                                o_rt_data_X_A;


   wire [15:0] bypass_rs_full_A = r1sel_X_A == wsel_M_B && regfile_we_M_B && r1re_X_A ? alu_result_M_B :
                                  r1sel_X_A == wsel_M_A && regfile_we_M_A && r1re_X_A ? alu_result_M_A : 
                                  bypass_rs_wx_A;

   wire [15:0] bypass_rt_full_A = r2sel_X_A == wsel_M_B && regfile_we_M_B && r2re_X_A ? alu_result_M_B :
                                  r2sel_X_A == wsel_M_A && regfile_we_M_A && r2re_X_A ? alu_result_M_A : 
                                  bypass_rt_wx_A;
   
   wire [15:0] alu_result_A;
   lc4_alu alu_A (.i_insn(i_cur_insn_X_A), .i_pc(pc_X_A), .i_r1data(bypass_rs_full_A), .i_r2data(bypass_rt_full_A), .o_result(alu_result_A));

   
  
   //STAGE: Execute - Registers B
   wire [15:0] pc_X_B, pc_plus_1_X_B, i_cur_insn_X_B, o_rs_data_X_B, o_rt_data_X_B;

   Nbit_reg #(16, 0) pc_reg_X_B (.in(pc_D_B), .out(pc_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_X_B (.in(pc_plus_1_D_B), .out(pc_plus_1_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) r1data_reg_X_B (.in(o_rs_data_B), .out(o_rs_data_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) r2data_reg_X_B (.in(o_rt_data_D_B), .out(o_rt_data_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));

   wire [2:0] r1sel_X_B, r2sel_X_B, wsel_X_B;
   wire [1:0] stall_X_B;
   wire select_pc_plus_one_X_B, nzp_we_X_B, is_control_insn_X_B, is_branch_X_B, is_store_X_B, regfile_we_X_B, r1re_X_B, r2re_X_B, is_load_X_B;
   wire pipe_switch_or_flush = pipe_switch_q || flush_rst_A;
   

   Nbit_reg #(3, 0) r1sel_reg_X_B (.in(r1sel_D_B), .out(r1sel_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_X_B (.in(r2sel_D_B), .out(r2sel_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_X_B (.in(wsel_D_B), .out(wsel_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));

   Nbit_reg #(1, 0) r1re_reg_X_B (.in(r1re_D_B), .out(r1re_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) r2re_reg_X_B (.in(r2re_D_B), .out(r2re_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) regfile_we_reg_X_B (.in(regfile_we_D_B), .out(regfile_we_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) nzp_we_reg_X_B (.in(nzp_we_B), .out(nzp_we_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_X_B (.in(select_pc_plus_one_D_B), .out(select_pc_plus_one_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_X_B (.in(is_load_D_B), .out(is_load_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) is_control_reg_X_B (.in(is_control_insn_D_B), .out(is_control_insn_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) is_branch_reg_X_B (.in(is_branch_D_B), .out(is_branch_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(1, 0) is_store_reg_X_B (.in(is_store_D_B), .out(is_store_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(pipe_switch_or_flush));
   Nbit_reg #(2, 2'b10) stall_reg_X_B (.in(stall_D_B_new), .out(stall_X_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_X_B (.in(i_cur_insn_D_B), .out(i_cur_insn_X_B), .clk(clk), .we(~load_to_use_A), .gwe(gwe), .rst(rst));



   //STAGE: MEMORY
   //STAGE: Memory - Registers A
   wire [15:0] pc_M_A, o_rt_data_M_A, i_cur_insn_M_A, pc_plus_1_M_A, alu_result_M_A;
   wire [2:0] r1sel_M_A, r2sel_M_A, nzp_bits_M_A, wsel_M_A;
   wire [1:0] stall_M_A;
   wire is_load_M_A, is_store_M_A, select_pc_plus_one_M_A, is_branch_M_A, regfile_we_M_A, nzp_we_M_A;

   Nbit_reg #(3, 0) r1sel_reg_M_A (.in(r1sel_X_A), .out(r1sel_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_M_A (.in(r2sel_X_A), .out(r2sel_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) r2data_reg_M_A (.in(bypass_rt_full_A), .out(o_rt_data_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_reg_M_A (.in(pc_X_A), .out(pc_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_result_reg_M_A (.in(alu_result_A), .out(alu_result_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_M_A (.in(is_load_X_A), .out(is_load_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_store_reg_M_A (.in(is_store_X_A), .out(is_store_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_M_A (.in(wsel_X_A), .out(wsel_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_M_A (.in(regfile_we_X_A), .out(regfile_we_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_insn_reg_M_A (.in(i_cur_insn_X_A), .out(i_cur_insn_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) stall_reg_M_A (.in(stall_X_A), .out(stall_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_M_A (.in(nzp_we_X_A), .out(nzp_we_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_M_A (.in(select_pc_plus_one_X_A), .out(select_pc_plus_one_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_M_A (.in(pc_plus_1_X_A), .out(pc_plus_1_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) nzp_bits_reg_M_A (.in(nzp_new_bits_A), .out(nzp_bits_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_branch_reg_M_A (.in(is_branch_X_A), .out(is_branch_M_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   


   //STAGE: Memory - Registers B
   wire [2:0] wsel_M_B;
   wire regfile_we_M_B;
   wire nzp_we_M_B, is_load_M_B, is_store_M_B, select_pc_plus_one_M_B, is_branch_M_B, r2re_M_B;
   wire [15:0] pc_M_B, o_rt_data_M_B, i_cur_insn_M_B, pc_plus_1_M_B, alu_result_M_B;
   wire [1:0] stall_M_B;
   wire [2:0] r1sel_M_B, r2sel_M_B, nzp_bits_M_B;
   wire flush_rst_B = branched_q_D || branched_q_A || rst;

   Nbit_reg #(16, 0) pc_reg_M_B (.in(pc_X_B), .out(pc_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) r2data_reg_M_B (.in(bypass_rt_full_B), .out(o_rt_data_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_result_reg_M_B (.in(alu_result_B), .out(alu_result_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_M_B (.in(is_load_X_B), .out(is_load_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(flush_rst_B));
   Nbit_reg #(1, 0) is_store_reg_M_B (.in(is_store_X_B), .out(is_store_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(flush_rst_B));
   Nbit_reg #(3, 0) wsel_reg_M_B (.in(wsel_X_B), .out(wsel_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_M_B (.in(regfile_we_X_B), .out(regfile_we_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(flush_rst_B));
   Nbit_reg #(16, 0) i_cur_insn_reg_M_B (.in(i_cur_insn_X_B), .out(i_cur_insn_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) stall_reg_M_B (.in(stall_X_B_new), .out(stall_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_M_B (.in(nzp_we_X_B), .out(nzp_we_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(flush_rst_B));
   Nbit_reg #(3, 0) r1sel_reg_M_B (.in(r1sel_X_B), .out(r1sel_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_M_B (.in(r2sel_X_B), .out(r2sel_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_M_B (.in(select_pc_plus_one_X_B), .out(select_pc_plus_one_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_M_B (.in(pc_plus_1_X_B), .out(pc_plus_1_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) nzp_bits_reg_M_B (.in(nzp_new_bits_B), .out(nzp_bits_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_branch_reg_M_B (.in(is_branch_X_B), .out(is_branch_M_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(flush_rst_B));
   

   wire [15:0] bypass_rs_wx_B = r1sel_X_B == wsel_W_B && regfile_we_W_D_B ? i_wdata_B : 
                                r1sel_X_B == wsel_W_A && regfile_we_W_D_A ? i_wdata_A : 
                                o_rs_data_X_B;

   wire [15:0] bypass_rt_wx_B = r2sel_X_B == wsel_W_B && regfile_we_W_D_B ? i_wdata_B : 
                                r2sel_X_B == wsel_W_A && regfile_we_W_D_A ? i_wdata_A : 
                                o_rt_data_X_B;

   wire [15:0] bypass_rs_full_B = r1sel_X_B == wsel_M_B && regfile_we_M_B ? alu_result_M_B :
                                  r1sel_X_B == wsel_M_A && regfile_we_M_A ? alu_result_M_A : 
                                  bypass_rs_wx_B;

   wire [15:0] bypass_rt_full_B = r2sel_X_B == wsel_M_B && regfile_we_M_B ? alu_result_M_B :
                                  r2sel_X_B == wsel_M_A && regfile_we_M_A ? alu_result_M_A : 
                                  bypass_rt_wx_B;
   
   wire [15:0] alu_result_B; 
   lc4_alu alu_B (.i_insn(i_cur_insn_X_B), .i_pc(pc_X_B),.i_r1data(bypass_rs_full_B), .i_r2data(bypass_rt_full_B), .o_result(alu_result_B));


   wire [1:0] stall_X_B_new = ~branched_q_A ? stall_X_B : 2'b10;

   wire [15:0] dmem_addr_M_A = is_load_M_A || is_store_M_A ? o_dmem_addr : 16'b0;
   wire [15:0] dmem_addr_M_B = is_load_M_B || is_store_M_B ? o_dmem_addr : 16'b0;

   wire [15:0] i_cur_dmem_data_M = is_store_M ? o_dmem_towrite : i_cur_dmem_data;
   
   

   wire [15:0] i_cur_dmem_data_M_A = is_mem_insn_A ? i_cur_dmem_data_M : 16'b0;
   wire [15:0] i_cur_dmem_data_M_B = is_mem_insn_B ? i_cur_dmem_data_M : 16'b0;

   //STAGE: Memory - NZP + BR CALC 
   wire [15:0] nzp_new_bits_inputs_A =  select_pc_plus_one_X_A ? pc_plus_1_X_A : 
                                        nzp_we_X_A ? alu_result_A : 
                                        data_mem_out_W_A;


   wire [2:0] nzp_new_bits_A = $signed(nzp_new_bits_inputs_A) < 0 ? 3'b100 :
                           $signed(nzp_new_bits_inputs_A) > 0 ? 3'b001 :
                           3'b010;

   wire [15:0] nzp_new_bits_inputs_B = select_pc_plus_one_X_B ? pc_plus_1_X_B :
                                       nzp_we_X_B ? alu_result_B :
                                       data_mem_out_W_B;



   wire [2:0] nzp_new_bits_B = $signed(nzp_new_bits_inputs_B) < 0 ? 3'b100 :
                           $signed(nzp_new_bits_inputs_B) > 0 ? 3'b001 :
                           3'b010;

   wire [2:0] nzp_new_bits_iwdata_A = $signed(i_wdata_A) < 0 ? 3'b100 :
                                      $signed(i_wdata_A) > 0 ? 3'b001 :
                                      3'b010;
   wire [2:0] nzp_new_bits_iwdata_B = $signed(i_wdata_B) < 0 ? 3'b100 :
                                      $signed(i_wdata_B) > 0 ? 3'b001 :
                                      3'b010;
   
   wire [2:0] nzp_old_bits;
   wire nzp_write_enable = is_load_W_A || is_load_W_B || nzp_we_X_A || nzp_we_X_B;
   wire [2:0] nzp_new_bits = nzp_we_X_B || is_load_W_B ? nzp_new_bits_B : nzp_new_bits_A; 
   Nbit_reg #(3) nzp_reg (.in(nzp_new_bits), .out(nzp_old_bits), .rst(rst), .clk(clk), .gwe(gwe), .we(nzp_write_enable));
   
   wire [2:0] nzp_correct_input = is_load_W_A && ~nzp_we_W_B ? nzp_new_bits_iwdata_A :
                                  is_load_W_B ? nzp_new_bits_iwdata_B : 
                                  nzp_old_bits;

   wire nzp_correct_A = i_cur_insn_X_A[11] == 1 && nzp_correct_input == 3'b100 || 
                        i_cur_insn_X_A[10] == 1 && nzp_correct_input == 3'b010 ||
                        i_cur_insn_X_A[9] == 1 && nzp_correct_input == 3'b001;

   wire nzp_correct_B = i_cur_insn_X_B[11] == 1 && nzp_correct_input == 3'b100 || 
                        i_cur_insn_X_B[10] == 1 && nzp_correct_input == 3'b010 ||
                        i_cur_insn_X_B[9] == 1 && nzp_correct_input == 3'b001;

   wire branched_q_A = is_control_insn_X_A || (is_branch_X_A && nzp_correct_A);
   wire branched_q_B =  is_control_insn_X_B || (is_branch_X_B && nzp_correct_B);
   wire branched_q = branched_q_A || branched_q_B;

   

   //STAGE: Writeback
   wire is_store_M = is_store_M_A || is_store_M_B;
   wire is_mem_insn_A = is_load_M_A || is_store_M_A;
   wire is_mem_insn_B = is_load_M_B || is_store_M_B;

   assign o_dmem_addr = is_mem_insn_A ? alu_result_M_A : 
                        is_mem_insn_B ? alu_result_M_B : 
                        16'b0;
   assign o_dmem_we = is_store_M;

   wire [15:0] o_dmem_towrite_M =   is_store_M_B && regfile_we_M_A && wsel_M_A == r2sel_M_B ? alu_result_M_A :
                                    regfile_we_W_D_B && ((is_store_M_A && r2sel_M_A == wsel_W_B) || (is_store_M_B && r2sel_M_B == wsel_W_B)) ? i_wdata_B :
                                    regfile_we_W_D_A && ((is_store_M_A && r2sel_M_A == wsel_W_A) || (is_store_M_B && r2sel_M_B == wsel_W_A)) ? i_wdata_A :
                                    is_store_M_A ? o_rt_data_M_A :
                                    is_store_M_B ? o_rt_data_M_B : 
                                    16'b0;
   assign o_dmem_towrite = o_dmem_towrite_M;
    

   
   //STAGE: Writeback - Registers A
   wire [15:0] pc_W_A, i_cur_insn_W_A, dmem_addr_W_A, i_cur_dmem_data_W_A, pc_plus_1_W_A, alu_result_W_A, data_mem_out_W_A;
   wire is_store_W_A, select_pc_plus_one_W_A, is_load_W_A, nzp_we_W_A;
   wire [1:0] stall_W_A;
   wire [2:0] r1sel_W_A, r2sel_W_A, nzp_bits_W_A;

   Nbit_reg #(16, 0) i_cur_insn_reg_W_A (.in(i_cur_insn_M_A), .out(i_cur_insn_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_W_A (.in(wsel_M_A), .out(wsel_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_W_A (.in(regfile_we_M_A), .out(regfile_we_W_D_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_W_A (.in(is_load_M_A), .out(is_load_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_reg_W_A (.in(pc_M_A), .out(pc_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_store_reg_W_A (.in(is_store_M_A), .out(is_store_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) dmem_addr_reg_W_A (.in(dmem_addr_M_A), .out(dmem_addr_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_dmem_data_reg_W_A (.in(i_cur_dmem_data_M_A), .out(i_cur_dmem_data_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) data_mem_out_reg_W_A (.in(i_cur_dmem_data), .out(data_mem_out_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) stall_reg_W_A (.in(stall_M_A), .out(stall_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_W_A (.in(nzp_we_M_A), .out(nzp_we_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r1sel_reg_W_A (.in(r1sel_M_A), .out(r1sel_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_W_A (.in(r2sel_M_A), .out(r2sel_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_W_A (.in(select_pc_plus_one_M_A), .out(select_pc_plus_one_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_W_A (.in(pc_plus_1_M_A), .out(pc_plus_1_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_result_reg_W_A (.in(alu_result_M_A), .out(alu_result_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) nzp_bits_reg_W_A (.in(nzp_bits_M_A), .out(nzp_bits_W_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //STAGE: Writeback - Registers B
   wire [15:0] pc_W_B, i_cur_insn_W_B, dmem_addr_W_B, i_cur_dmem_data_W_B, pc_plus_1_W_B, alu_result_W_B, data_mem_out_W_B;
   wire is_store_W_B, select_pc_plus_one_W_B, is_load_W_B, nzp_we_W_B;
   wire [1:0] stall_W_B;
   wire [2:0] r1sel_W_B, r2sel_W_B, nzp_bits_W_B;

   Nbit_reg #(16, 0) i_cur_insn_reg_W_B (.in(i_cur_insn_M_B), .out(i_cur_insn_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) wsel_reg_W_B (.in(wsel_M_B), .out(wsel_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) regfile_we_reg_W_B (.in(regfile_we_M_B), .out(regfile_we_W_D_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_load_reg_W_B (.in(is_load_M_B), .out(is_load_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_reg_W_B (.in(pc_M_B), .out(pc_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) is_store_reg_W_B (.in(is_store_M_B), .out(is_store_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) dmem_addr_reg_W_B (.in(dmem_addr_M_B), .out(dmem_addr_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) i_cur_dmem_data_reg_W_B (.in(i_cur_dmem_data_M_B), .out(i_cur_dmem_data_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) data_mem_out_reg_W_B (.in(i_cur_dmem_data), .out(data_mem_out_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10) stall_reg_W_B (.in(stall_M_B), .out(stall_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) nzp_we_reg_W_B (.in(nzp_we_M_B), .out(nzp_we_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r1sel_reg_W_B (.in(r1sel_M_B), .out(r1sel_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) r2sel_reg_W_B (.in(r2sel_M_B), .out(r2sel_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 0) select_pc_plus_one_reg_W_B (.in(select_pc_plus_one_M_B), .out(select_pc_plus_one_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) pc_plus_1_reg_W_B (.in(pc_plus_1_M_B), .out(pc_plus_1_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) alu_result_M_reg_W_B (.in(alu_result_M_B), .out(alu_result_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 0) nzp_bits_reg_W_B (.in(nzp_bits_M_B), .out(nzp_bits_W_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //TESTING + OUTPUTS
   wire [15:0] i_wdata_A = select_pc_plus_one_W_A ? pc_plus_1_W_A :
                           is_load_W_A ? data_mem_out_W_A : 
                           alu_result_W_A;
   wire [15:0] i_wdata_B = select_pc_plus_one_W_B ? pc_plus_1_W_B :
                           is_load_W_B ? data_mem_out_W_A : 
                           alu_result_W_B;

   assign o_cur_pc = pc;

   assign test_stall_A = stall_W_A;
   assign test_stall_B = stall_W_B;

   assign test_cur_pc_A = pc_W_A;
   assign test_cur_pc_B = pc_W_B;

   assign test_cur_insn_A = i_cur_insn_W_A;
   assign test_cur_insn_B = i_cur_insn_W_B;

   assign test_regfile_we_A = regfile_we_W_D_A;
   assign test_regfile_we_B = regfile_we_W_D_B;

   assign test_regfile_wsel_A = wsel_W_A;
   assign test_regfile_wsel_B = wsel_W_B;

   assign test_regfile_data_A = i_wdata_A;
   assign test_regfile_data_B = i_wdata_B;

   assign test_nzp_we_A = nzp_we_W_A;
   assign test_nzp_we_B = nzp_we_W_B;

   assign test_nzp_new_bits_A = is_load_W_A ? nzp_new_bits_iwdata_A : nzp_bits_W_A;
   assign test_nzp_new_bits_B = is_load_W_B ? nzp_new_bits_iwdata_B : nzp_bits_W_B;
   
   assign test_dmem_we_A = is_store_W_A;
   assign test_dmem_we_B = is_store_W_B;

   assign test_dmem_addr_A = dmem_addr_W_A;
   assign test_dmem_addr_B = dmem_addr_W_B;

   assign test_dmem_data_A = i_cur_dmem_data_W_A;
   assign test_dmem_data_B = i_cur_dmem_data_W_B;   

  
   always @(posedge gwe) begin
       // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // $display("PC: %h, PC_F_A: %h, PC_F_B: %h, NEXT_PC: %h, stall_d_b: %h", pc, pc_F_A, pc_F_B, next_pc, stall_D_B);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display();
   end
endmodule