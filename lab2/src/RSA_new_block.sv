module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm

endmodule



// This module executes the montgomery algorithm by taking N,a,b
module Montgomery (
	input			i_clk,
	input			i_rst,
	input			i_start,
	input			
	input  [255:0]  i_a, // cipher text y
	input  [255:0]  i_b, // 
	input  [255:0]  i_n,

	output [255:0]	o_value,
	output 			o_finished
);
	// Logic Assignments
	logic [255:0] i_a_r, i_b_r, i_n_r, i_a_w, i_b_w, i_n_w;

	// Finished signals
	logic o_finished_r, o_finished_w;

	// Count from 0 to 255
	logic [7:0] counter_r, counter_w;

	// Variety of m
	logic [255:0] m_subtract, m_odd, m_r, m_w;

	// Combinational
	assign o_value = (m_r >= i_n_r) ? m_subtract[255:0] : m_r[255:0];
	assign m_subtract = m_r - i_n_r;
	assign m_odd = (i_a_r[0]) ? (m_r + i_b_r) : m_r;
	assign o_finished = o_finished_r;


	always_comb begin
		
	
	end




;