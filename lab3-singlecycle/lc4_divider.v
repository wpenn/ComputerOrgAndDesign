/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] temp_rem [16:0];
      wire [15:0] temp_quot [16:0];
      wire [15:0] temp_div [16:0];
      assign temp_rem[0] = 16'b0;
      assign temp_quot[0] = 16'b0;
      assign temp_div[0] = i_dividend;
      genvar i;
      for (i = 0; i < 16; i = i + 1) begin
            lc4_divider_one_iter div_one_iter(.i_dividend(temp_div[i]),
                              .i_divisor(i_divisor),
                              .i_remainder(temp_rem[i]),
                              .i_quotient(temp_quot[i]),
                              .o_dividend(temp_div[i + 1]),
                              .o_remainder(temp_rem[i + 1]),
                              .o_quotient(temp_quot[i + 1]));
      end
      wire divisor_zero_check = (i_divisor == 16'b0);
      assign o_quotient = divisor_zero_check ? 16'b0 : temp_quot[16];
      assign o_remainder = divisor_zero_check ? 16'b0 : temp_rem[16];
endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
       wire zerocheck = 0 == i_divisor;
      assign o_dividend = i_dividend << 1;
      
      wire [15:0] div_shift_t, a_comp_t, prequot, preremainder, tempquot, remshift;
      
      assign remshift = i_remainder << 1;
      assign div_shift_t = (i_dividend >> 15) & 1'b1;
      assign a_comp_t =  div_shift_t | remshift;
      
      wire select_t = a_comp_t < i_divisor;

      assign preremainder = (select_t ? a_comp_t : (a_comp_t - i_divisor));
      assign o_remainder = zerocheck ? 16'b0 : preremainder;
      
      assign tempquot = i_quotient << 1;
      assign prequot = (select_t ? tempquot : tempquot | 1'b1);
      assign o_quotient = zerocheck ? 16'b0 : prequot;
endmodule
