`timescale 1ns / 1ps

module top(input clk, input [31:0] rule, output update_done);

wire [5:0] col;
wire [5:0] row;
wire world_we;
wire world_out;
wire world_in;

automaton automaton(clk, rule, row, col, world_we, world_in, world_out, update_done);
world world(clk, row, col, world_we, world_out, world_in);

endmodule
