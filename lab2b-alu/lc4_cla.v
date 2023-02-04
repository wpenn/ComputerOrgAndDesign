/* TODO: Jonathan Kogan and Wesley Penn -- jgkogan and wespenn */

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
  assign pout = (&  pin [3:0]);
  assign gout = (gin[0] & pin[1] & pin[2] & pin[3]) |(gin[1] & pin[2] & pin[3])| (gin[2] & pin[3]) | gin[3];
  assign cout[0] = (gin[0] | pin[0] & cin); 
  assign cout[1] = (gin[1] | pin[1] & cout[0]);
  assign cout[2] = (gin[2] | pin[2] & cout[1]);
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);
  
  wire [15:0] gin, pin;

  genvar i;
  for(i = 0; i < 16; i=i+1) begin
    gp1 g(.a(a[i]), .b(b[i]), .g(gin[i]), .p(pin[i]));
  end

  wire [15:0] cout;
  wire g30_1, p30_1;
  gpn #(4) gf1(.gin(gin[3:0]), .pin(pin[3:0]), .cin(cin), .gout(g30_1), .pout(p30_1), .cout(cout[2:0]));
  assign cout[3] = (cin & p30_1) | g30_1;


  wire g30_2, p30_2;
  gp4 gf2(.gin(gin[7:4]), .pin(pin[7:4]), .cin(cout[3]), .gout(g30_2), .pout(p30_2), .cout(cout[6:4]));
  assign cout[7] = (cout[3] & p30_2) | g30_2;

  wire g30_3, p30_3;
  gp4 gf3(.gin(gin[11:8]), .pin(pin[11:8]), .cin(cout[7]), .gout(g30_3), .pout(p30_3), .cout(cout[10:8]));
  assign cout[11] = (cout[7] & p30_3) | g30_3;
  
  wire g30_4, p30_4;
  gp4 gf4(.gin(gin[15:12]), .pin(pin[15:12]), .cin(cout[11]), .gout(g30_4), .pout(p30_4), .cout(cout[14:12]));
  assign cout[15] = (cout[11] & p30_4) | g30_4;

  assign sum[0] = a[0] ^ b[0] ^ cin;
  for(i = 1; i < 16; i = i + 1) begin
    assign sum[i] = a[i] ^ b[i] ^ cout[i - 1];
  end
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
 


  assign pout = (&  pin [N - 1:0]);
  
  wire [N-2: 0] temp;

  genvar i;
  for (i = 0; i < N-1; i = i + 1) begin
    assign temp[i] = gin[i] & (& pin[N-1:i+1]);
  end
  

  assign gout = (| temp [N-2:0]) | gin[N-1];


  assign cout[0] = (gin[0] | pin[0] & cin); 
  for(i = 0; i < N - 2; i = i + 1) begin
    assign cout[i + 1] = (gin[i + 1] | pin[i + 1] & cout[i]);
  end

endmodule
