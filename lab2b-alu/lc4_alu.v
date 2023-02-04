/* Jonathan Kogan, Wesley Penn -- jgkogan, wespenn */

`timescale 1ns / 1ps

`default_nettype none

module cla_input_rs ( //Right mux
      input wire [15:0] insn,
      input wire [15:0] pc,
      input wire [15:0] r1,
      output wire [15:0] rs
);
      assign rs = (insn[15:12] == 4'd1) | (insn[15:12] == 4'd6) | (insn[15:12] == 4'd7) ? r1 : pc;
endmodule

module cla_input_rt ( // Left mux
      input wire [15:0] insn,
      input wire [15:0] r2,
      input wire [15:0] imm11,
      input wire [15:0] imm5,
      input wire [15:0] uimm7,
      input wire [15:0] imm9,
      input wire [15:0] imm6,
      output wire [15:0] rt
);
      wire [15:0] mux1, mux2;
      assign mux1 = (insn[5:4] == 2'b00) ? r2 : ((insn[5:4] == 2'b01) ? ~r2 : imm5);
      assign mux2 = imm9;

      assign rt = (insn[15:12] == 4'b1100) ? imm11 : 
                  ((insn[15:12] == 4'b0001) ? mux1 : 
                   (insn[15:12] == 4'b0010) ? uimm7 :
                   (insn[15:12] == 4'b0000) ? mux2 :
                   (insn[15:12] == 4'b0110 | insn[15:12] == 4'b0111) ? imm6:
                   16'b0
                  );
endmodule


module cla_input_ci (
      input wire [15:0] insn,
      output wire cin
);
      wire mux_top = (insn[5:3] == 3'b010) ? ((insn[15:12] == 4'b0001) ? 1 : 0) : 0;
      wire mux_bot = (insn[15:12] == 4'b0000 | insn[15:12] == 4'b0100 | insn[15:12] == 4'b1100 | insn[15:12] == 4'b1111) ? 1 : 0;

      assign cin = mux_top | mux_bot;
endmodule

module comparators (
      input wire [15:0] insn,
      input wire [15:0] r1,
      input wire [15:0] r2,
      input wire [15:0] imm7,
      input wire [15:0] uimm7,
      output wire [15:0] comp_out
);
      // wire signed [15:0] signed_r1 = $signed(r1);
      // wire signed [15:0] signed_r2 = $signed(r2);
      wire [15:0] mux_rs = (insn[8:7] == 2'b00 | insn[8:7] == 2'b10) ? $signed(r1) : r1; 
      wire [15:0] mux_rt = (insn[8:7] == 2'b00) ? $signed(r2) : 
                        (insn[8:7] == 2'b01) ? r2 :
                        (insn[8:7] == 2'b10) ? imm7 :
                        uimm7;

      wire signed [15:0] signed_comp_out = ($signed(mux_rs) > $signed(mux_rt)) ? 16'b1 : ($signed(mux_rs) == $signed(mux_rt)) ? 16'b0 : 16'hFFFF;
      wire [15:0] unsigned_comp_out = (mux_rs > mux_rt) ? 16'b1 : (mux_rs == mux_rt) ? 16'b0 : 16'hFFFF;

      assign comp_out = (insn[8:7] == 2'b00 | insn[8:7] == 2'b10) ? signed_comp_out : unsigned_comp_out;
endmodule


module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/
      wire [15:0] imm5, imm6, imm7, imm9, imm11, uimm4, uimm7, uimm8;

      assign uimm4 = {12'b0, i_insn[3:0]};
      assign uimm7 = {9'b0, i_insn[6:0]};
      assign uimm8 = {8'b0, i_insn[7:0]};

      assign imm5 = {{12{i_insn[4]}}, i_insn[3:0]};
      assign imm6 = {{11{i_insn[5]}}, i_insn[4:0]};
      assign imm7 = {{10{i_insn[6]}}, i_insn[5:0]};
      assign imm9 = {{8{i_insn[8]}}, i_insn[7:0]};
      assign imm11 = {{6{i_insn[10]}}, i_insn[9:0]};
      
      wire cla_cin;
      wire [15:0] cla_rt, cla_rs;
      cla_input_ci get_cin(.insn(i_insn), .cin(cla_cin));
      cla_input_rs get_rs(.insn(i_insn), .pc(i_pc), .r1(i_r1data), .rs(cla_rs));
      cla_input_rt get_rt(.insn(i_insn), .r2(i_r2data), .imm11(imm11), .imm5(imm5), .uimm7(uimm7), .imm9(imm9), .imm6(imm6), .rt(cla_rt));


      wire [15:0] cla_output;
      cla16 get_cla_out(.a(cla_rs), .b(cla_rt), .cin(cla_cin), .sum(cla_output));

      wire [15:0] mult_out = i_r1data * i_r2data;

      wire [15:0] div_out, mod_out;
      lc4_divider div(.i_dividend(i_r1data), .i_divisor(i_r2data), .o_remainder(mod_out), .o_quotient(div_out));

      wire [15:0] math_mux = (i_insn[5:3] == 3'b011) ? div_out : (i_insn[5:3] == 3'b001) ? mult_out : cla_output;

      wire [15:0] comp_result;
      comparators get_comp(.insn(i_insn), .r1(i_r1data), .r2(i_r2data), .imm7(imm7), .uimm7(uimm7), .comp_out(comp_result));

      wire signed [15:0] sra_temp = $signed(i_r1data) >>> uimm4;
      wire [15:0] shift_result = (i_insn[5:4] == 2'b00) ? (i_r1data << uimm4) : 
                              (i_insn[5:4] == 2'b01) ? sra_temp : 
                              (i_insn[5:4] == 2'b10) ? (i_r1data >> uimm4) : 
                              mod_out;

      wire [15:0] hiconst = (i_r1data & 8'hFF) | (uimm8 << 8);

      wire [15:0] trap = 16'h8000 | uimm8;

      wire [15:0] basic_log = (i_insn[5:3] == 3'b000) ? i_r1data & i_r2data :
                              (i_insn[5:3] == 3'b001) ? ~i_r1data :
                              (i_insn[5:3] == 3'b010) ? i_r1data | i_r2data :
                              (i_insn[5:3] == 3'b011) ? i_r1data ^ i_r2data :
                              i_r1data & imm5;

      wire [15:0] jsr_out =  (i_insn[11] == 1) ? ((i_pc & 16'h8000) | (i_insn[10:0] << 4)) : i_r1data;
      
      wire [15:0] jmp_out = (i_insn[11] == 1) ? cla_output : i_r1data;


      assign o_result =  (i_insn[15:12] == 4'b0100) ? jsr_out : 
                        (i_insn[15:12] == 4'b0101) ? basic_log : 
                        (i_insn[15:12] == 4'b1101) ? hiconst : 
                        (i_insn[15:12] == 4'b1111) ? trap :  
                        (i_insn[15:12] == 4'b1001) ? imm9 : 
                        (i_insn[15:12] == 4'b1010) ? shift_result : 
                        (i_insn[15:12] == 4'b0010) ? comp_result : 
                        (i_insn[15:12] == 4'b0001) ? math_mux : 
                        (i_insn[15:12] == 4'b1100) ? jmp_out : 
                        (i_insn[15:12] == 4'b0000) ? cla_output : 
                        (i_insn[15:12] == 4'b0110) ? cla_output : 
                        (i_insn[15:12] == 4'b0111) ? cla_output :
                        (i_insn[15:12] == 4'b1000) ? i_r1data : 
                        16'b0;
endmodule