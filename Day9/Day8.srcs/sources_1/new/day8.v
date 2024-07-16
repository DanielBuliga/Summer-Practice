`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2024 11:34:22
// Design Name: 
// Module Name: day8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module reg_pc(clk, res, in, out);
    input clk, res;
    input [31:0] in;
    output reg [31:0] out = -4;
    
    always @ (posedge clk)
    begin
        if(res)
            out <= 32'b0;
        else
            out <= in; 
    end
    
endmodule 


module alu_sum(in, out);
    input [31:0] in;
    output reg [31:0] out;
    
    always @(in)
        out <= in + 4;
        
endmodule 


module im(addr, instr);
    input [31:0] addr; //input 
    output reg [31:0] instr; //output
    
    reg [7:0] data [31:0];
    
    initial
        $readmemb("im.mem", data);
    
    always @(addr)
    begin
        instr[7:0] <= data[addr];
        instr[15:8] <= data[addr + 1];
        instr[23:16] <= data[addr + 2];
        instr[31:24] <= data[addr + 3];
    end
    
endmodule


module alu(a, b, alu_op, out, zero);
    input [31:0] a,b; 
    input [3:0] alu_op;
    output reg zero;
    output reg [31:0] out;
    
    always @( a or b or alu_op)
    begin
        case(alu_op)
            4'b0000: begin out <= a & b;  zero <= (~out) ? 1 : 0; end
            4'b0001: begin out <= a | b;  zero <= (~out) ? 1 : 0; end
            4'b0010: begin out <= a + b;  zero <= (~out) ? 1 : 0; end
            4'b0110: begin out <= a - b;  zero <= (~out) ? 1 : 0; end
            4'b0111: begin out <= (a < b) ? 1 : 0;  zero <= (~out) ? 1 : 0; end
            4'b1100: begin out <= ~(a | b);  zero <= (~out) ? 1 : 0; end
            default: begin out <= 32'b0;  zero <= (~out) ? 1 : 0; end
        endcase
    end
    
endmodule


module mux2_1(in1, in2, sel, out);
    parameter N = 32;
    input [N-1:0] in1, in2;
    input  sel;
    output reg [N-1:0] out;
    
    always @ (in1 or in2 or sel)
    begin
        case(sel)
            1'b0: out <= in1;
            1'b1: out <= in2;
        endcase
    end
    
endmodule


module ext_sign(in, ext_op, out);
    input [15:0] in;
    input ext_op;
    output reg [31:0] out;
    
    //always @(in or ext_op)
    //    out <= { {16{ext_op}}, in};
    
    always @ (in or ext_op)
    begin
        if(ext_op)
            out <= {{16{in[15]}}, in};
        else
            out <= in;
    end
    
endmodule 


module register_bank(clk, ra1, ra2, wa, wd, reg_write, rd1, rd2);
    input clk, reg_write;
    input [4:0] ra1, ra2, wa;
    input [31:0] wd;
    output reg [31:0] rd1, rd2;
    
    reg [31:0] rg [31:0];
    
    //initializare toate reg cu 0
    integer i;
    
    initial
    begin
        for (i=0; i<32; i=i+1)
           rg[i]=32'b0;
    end
    
    
    always @(posedge  clk)
    begin
        if(reg_write)
            rg[wa] = wd;
    end
    
    always @(negedge clk)
    begin
        rd1 = rg[ra1];
        rd2 = rg[ra2];
    end
    
    
endmodule 


module dm(clk, address, wd, mem_write, rd); //FFFF 7777 
    input clk, mem_write;
    input [31:0] address, wd;
    output reg [31:0] rd;
    
    reg [7:0] mem [31:0] ;
    
    integer i;
    
    initial
    begin
        for (i=0; i<32; i=i+1)
           mem[i]=32'b0;
    end
    
    always @(posedge clk)
    begin
        if(mem_write)
        begin
            mem[address] = wd[7:0];
            mem[address + 1] = wd[15:8];
            mem[address + 2] = wd[23:16];
            mem[address + 3] = wd[31:24];            
        end
    end
    
    always @(negedge clk)
    begin
        rd = {mem[address + 3], mem[address + 2], mem[address + 1], mem[address]};        
        /*
         rd[7:0] = mem[address];
         rd[15:8] = mem[address + 1];
         rd[23:16] = mem[address + 2];
         rd[31:24] = mem[address + 3];
         */
    
    end
    
endmodule


module main_control(func, opcode, zero, reg_dst, reg_write, ext_op, alu_src, alu_op, mem_write, mem_to_reg);
    input [5:0] func, opcode;
    input zero;
    output reg reg_dst, reg_write, ext_op, alu_src, mem_write, mem_to_reg;
    output reg [3:0] alu_op;
        
    always @(func or opcode)
    begin 
        case(opcode)
            6'b000000:              // R-TYPE
                begin            
                    reg_dst = 1;    // 1 la R-TYPE,    0 la I-TYPE
                    alu_src = 0;    // 0 la R-TYPE,    1 la I-TYPE
                    mem_to_reg = 0;
                    reg_write = 1;
                    mem_write = 0;
                    ext_op = 0;   //0 la R-Type      1 la I-Type
                    
                    case(func)
                        6'b100000: alu_op = 4'b0010;    //ADD
                        6'b100010: alu_op = 4'b0110;    //SUB
                        6'b100100: alu_op = 4'b0000;    //AND
                        6'b100101: alu_op = 4'b0001;    //OR
                        6'b101010: alu_op = 4'b0111;    //SLT
                        default: alu_op = 4'b1100;      //NOR
                    endcase
                    
                end
        
            6'b001000:              // I-TYPE -> ADDI
                begin
                    reg_dst = 0;
                    alu_src = 1;
                    mem_to_reg = 0;
                    reg_write = 1;
                    mem_write = 0;
                    ext_op = 1;
                    alu_op = 4'b0010;    
                end
            /*    
            6'b011001:              // I-TYPE -> LHI  ????
                begin
                    reg_dst = 0;
                    alu_src = 1;
                    mem_to_reg = 0;
                    reg_write = 1;
                    mem_write = 0;
                    ext_op = 0;
                    alu_op = 4'b0010; 
                    
                end 
                
            6'b011000:              // I-TYPE -> LOI  ????
                begin
                    reg_dst = 0;
                    alu_src = 1;
                    mem_to_reg = 0;
                    reg_write = 1;
                    mem_write = 0;
                    ext_op = 0;
                    alu_op = 4'b0010; 
                    
                end
            */
                
            6'b100011:              // I-TYPE -> LW 
                begin
                    reg_dst = 0;
                    alu_src = 1;
                    mem_to_reg = 1;
                    reg_write = 1;
                    mem_write = 0;
                    ext_op = 0;
                    alu_op = 4'b0010;  // op de adunare <= adun adresa la registru
                    
                end           
        
            6'b101011:              // I-TYPE -> SW
                begin
                    reg_dst = 0;
                    alu_src = 1;
                    mem_to_reg = 0;
                    reg_write = 0;
                    mem_write = 1;
                    ext_op = 0;
                    alu_op = 4'b0010;   // op de adunare <= adun adresa la registru
                    
                end 
            
            default:
                begin
                    reg_dst = 0;
                    alu_src = 0;
                    mem_to_reg = 0;
                    reg_write = 0;
                    mem_write = 0;
                    ext_op = 0;
                    alu_op = 4'b1111;    
                end 
        
        endcase                      
    end
    
endmodule


module tb;
    reg clk, res;
    
    wire [31:0]  pc_out, sum_out, im_out, alu_out, rb1_out, rb2_out, dm_out, mux2_out, mux3_out, ext_sign_out;
    wire [4:0] mux1_out; 
    wire [3:0] alu_op;
    wire reg_write, reg_dst, alu_src, mem_write, mem_to_reg, ext_op, zero;
    wire [5:0] im_out1, im_out2;
    
    assign im_out1 = im_out[5:0];
    assign im_out2 = im_out[31:26];
    
    reg_pc pc_inst(clk, res, sum_out, pc_out); 
    //reg_pc(clk, res, in, out);
    
    alu_sum sum_inst(pc_out, sum_out);
    //alu_sum(in, out);
    
    im im_inst(pc_out, im_out); 
    //im(addr, instr);
    
    mux2_1 #(5) mux1(im_out[20:16], im_out[15:11], reg_dst, mux1_out);
    //mux2_1(in1, in2, sel, out);
    
    register_bank rb_inst(clk, im_out[25:21], im_out[20:16], mux1_out, mux3_out, reg_write, rb1_out, rb2_out);
    //register_bank(clk, ra1, ra2, wa, wd, reg_write, rd1, rd2);
    
    ext_sign es_inst(im_out[15:0], ext_op, ext_sign_out);
    //ext_sign(in, ext_op, out);
    
    mux2_1 mux2(rb2_out, ext_sign_out, alu_src, mux2_out);
    
    alu alu_inst(rb1_out, mux2_out, alu_op, alu_out, zero);
    //alu(a, b, alu_op, out, zero);
    
    dm dm_inst(clk, alu_out, rb2_out, mem_write, dm_out);
    //dm(clk, address, wd, mem_write, rd);
    
    mux2_1 mux3(dm_out, alu_out, mem_to_reg, mux3_out);
    
    main_control mc(im_out2, im_out1, zero, reg_dst, reg_write, ext_op, alu_src, alu_op, mem_write, mem_to_reg);
    //main_control(func, opcode, zero, reg_dst, reg_write, ext_op, alu_src, alu_op, mem_write, mem_to_reg);
  

    
    initial
    begin
        #0 clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial 
        #100 $finish;
    
    initial
    begin   
         #0 clk = 0; res=1;
         #10 res=0;
         
    end
endmodule