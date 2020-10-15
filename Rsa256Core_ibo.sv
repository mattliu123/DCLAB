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
	logic [255:0] i_a_r, i_a_w, i_d_r, i_d_w, i_n_r, i_n_w;
	logic         o_finished_r, o_finished_w;
	logic [255:0] o_a_pow_d_r, o_a_pow_d_w;

	// core states
	enum  {IDLE, PREP, MONT, WAIT, DONE} state_r, state_w;
	logic [8:0]   counter_r, counter_w;
	logic         mp_deliver_r, mp_deliver_w;

	// sub-modules I/O
	logic         mp_start, mp_finished, mont1_start, mont1_finished, mont2_start, mont2_finished;
	logic [255:0] mp_out, mont1_a, mont1_b, mont1_out, mont2_a, mont2_out;

	// assign sub-modules
	ModuloProduct MP(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(mp_start),
		.i_a({1'b1, {256{1'b0}}}),
		.i_b({1'b0, i_a}),
		.i_n({1'b0, i_n}),
		.o_result(mp_out),
		.o_finished(mp_finished)
	);
	Montgomery MONT1(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(mont1_start),
		.i_a(mont1_a),
		.i_b(mont1_b),
		.i_n(i_n),
		.o_result(mont1_out),
		.o_finished(mont1_finished)
	);
	Montgomery MONT2(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(mont2_start),
		.i_a(mont2_a),
		.i_b(mont2_a),
		.i_n(i_n),
		.o_result(mont2_out),
		.o_finished(mont2_finished)
	);

	///////////combinational part///////////
	assign o_a_pow_d = o_a_pow_d_r;
	assign o_finished = o_finished_r;
	
	always_comb begin
	// default
		i_a_w          = i_a_r;
		i_d_w          = i_d_r;
		i_n_w          = i_n_r;
		o_finished_w   = o_finished_r;
		o_a_pow_d_w    = o_a_pow_d_r;
		state_w        = state_r;
		counter_w      = counter_r;
		mp_deliver_w   = mp_deliver_r;
		
		mp_start       = 0;
		mont1_start    = 0;
		mont2_start    = 0;
		mont1_a        = 0;
		mont1_b        = 0;
		mont2_a        = 0;

		// FSM
		case (state_r)
			default: begin
				i_a_w          = i_a_r;
				i_d_w          = i_d_r;
				i_n_w          = i_n_r;
				o_finished_w   = o_finished_r;
				o_a_pow_d_w    = o_a_pow_d_r;
				state_w        = state_r;
				counter_w      = counter_r;
				mp_deliver_w   = mp_deliver_r;
			end
			IDLE: begin
				if (i_start) begin
					i_a_w          = i_a;
					i_d_w          = i_d;
					i_n_w          = i_n;
					state_w        = PREP;
					mp_start       = 1;
				end
				else begin
					i_a_w          = i_a_r;
					i_d_w          = i_d_r;
					i_n_w          = i_n_r;
					state_w        = IDLE;
					mp_start       = 0;
				end
			end
			PREP: begin
				state_w  = (mp_finished) ? MONT : PREP;
				
			end
			MONT: begin
				
				mont1_start = (i_d_r[0] && !mont2_finished) ? 1 : 0;
				mont2_start = (mont2_finished) ? 0 : 1;

				mont1_a = (!mp_deliver_r) ? 1 : mont1_out;
				mont1_b = (counter_r == 0) ? mp_out : mont2_out;
				mont2_a = (counter_r == 0) ? mp_out : mont2_out;

				mp_deliver_w = (mont1_finished) ? 1 : mp_deliver_r;
				state_w = (mont2_finished) ? WAIT : MONT;

			end
			WAIT: begin
				
				if (counter_r == 255) begin
					state_w = DONE;
					counter_w = counter_r;
					i_d_w = i_d_r;
					o_a_pow_d_w = mont1_out;
					o_finished_w = 1;
				end
				else begin
					state_w = MONT;
					counter_w = counter_r + 1;
					i_d_w = i_d_r >> 1;
					o_a_pow_d_w = o_a_pow_d_r;
					o_finished_w = o_finished_r;
				end

			end
			DONE: begin
				i_a_w   = 0;
				state_w = IDLE;
				o_finished_w = 0;
				mp_deliver_w = 0;
				counter_w = 0;
			end
		endcase
	end

	///////////sequential part///////////
	always_ff @(posedge i_clk or posedge i_rst) begin
		// reset
		if (i_rst) begin
			i_a_r          <= 0;
			i_d_r          <= 0;
			i_n_r          <= 0;
			o_finished_r   <= 0;
			o_a_pow_d_r    <= 0;
			state_r        <= IDLE;
			counter_r      <= 0;
			mp_deliver_r   <= 0;
		end
		else begin
			i_a_r          <= i_a_w;
			i_d_r          <= i_d_w;
			i_n_r          <= i_n_w;
			o_finished_r   <= o_finished_w;
			o_a_pow_d_r    <= o_a_pow_d_w;
			state_r        <= state_w;
			counter_r      <= counter_w;
			mp_deliver_r   <= mp_deliver_w;
		end
	end

endmodule


module ModuloProduct(
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [256:0] i_a, // a = 2^256
	input  [256:0] i_b,
	input  [256:0] i_n,
	output [255:0] o_result,
	output         o_finished
);
	
	logic [256:0] i_a_r, i_a_w, i_b_r, i_b_w, i_n_r, i_n_w;
	logic         o_finished_r, o_finished_w;
	
	enum  {IDLE, CALC, DONE} state_r, state_w;

	logic [8:0]   counter_r, counter_w;
	logic [257:0] t_r, t_w, m_r, m_w;

	///////////combinational part///////////
	assign o_result = m_r[255:0];
	assign o_finished = o_finished_r;

	always_comb begin
		// default
		i_a_w          = i_a_r;
		i_b_w          = i_b_r;
		i_n_w          = i_n_r;
		o_finished_w   = o_finished_r;
		state_w        = state_r;
		counter_w      = counter_r;
		t_w            = t_r;
		m_w            = m_r;
		// FSM
		case (state_r)
			default: begin
				i_a_w          = i_a_r;
				i_b_w          = i_b_r;
				i_n_w          = i_n_r;
				o_finished_w   = o_finished_r;
				state_w        = state_r;
				counter_w      = counter_r;
				t_w            = t_r;
				m_w            = m_r;
			end
			IDLE: begin
				if (i_start) begin
					i_a_w          = i_a;
					i_b_w          = i_b;
					i_n_w          = i_n;
					state_w        = CALC;
					counter_w      = 0;
					t_w            = i_b;
					m_w            = 0;
				end
				else begin
					i_a_w          = i_a_r;
					i_b_w          = i_b_r;
					i_n_w          = i_n_r;
					state_w        = state_r;
					counter_w      = counter_r;
					t_w            = t_r;
					m_w            = m_r;
				end
			end
			CALC: begin
				if (i_a_r[0]) begin
					m_w = ( (m_r + t_r) >= i_n_r) ? (m_r + t_r - i_n_r) : (m_r + t_r);
				end
				else begin
					m_w = m_r;
				end

				i_a_w = i_a_r >> 1;
				t_w = ( (t_r<<1) >= i_n_r) ? ((t_r<<1) - i_n_r) : (t_r<<1);

				if (counter_r == 256) begin
					state_w = DONE;
					o_finished_w = 1;
					counter_w = counter_r;
				end
				else begin
					state_w = state_r;
					o_finished_w = o_finished_r;
					counter_w = counter_r + 1;
				end
			end
			DONE: begin
				state_w = IDLE;
				o_finished_w = 0;
			end
		endcase
	end

	///////////sequential part///////////
	always_ff @(posedge i_clk or posedge i_rst) begin
		// reset
		if (i_rst) begin
			i_a_r          <= 0;
			i_b_r          <= 0;
			i_n_r          <= 0;
			o_finished_r   <= 0;
			state_r        <= IDLE;
			counter_r      <= 0;
			t_r            <= 0;
			m_r            <= 0;
		end
		else begin
			i_a_r          <= i_a_w;
			i_b_r          <= i_b_w;
			i_n_r          <= i_n_w;
			o_finished_r   <= o_finished_w;
			state_r        <= state_w;
			counter_r      <= counter_w;
			t_r            <= t_w;
			m_r            <= m_w;
		end
	end

endmodule

module Montgomery(
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a,
	input  [255:0] i_b,
	input  [255:0] i_n,
	output [255:0] o_result,
	output         o_finished
);
	
	logic [255:0] i_a_r, i_a_w, i_b_r, i_b_w, i_n_r, i_n_w;
	logic         o_finished_r, o_finished_w;
	
	enum  {IDLE, CALC, DONE} state_r, state_w;

	logic [7:0]   counter_r, counter_w;
	logic [257:0] m_r, m_w, m_temp, m_ans;

	///////////combinational part///////////
	assign m_temp = ((i_a_r[0]) ? (m_r + i_b_r) : m_r);
	assign m_ans = m_r - i_n_r;
	assign o_result = (m_r >= i_n_r) ? m_ans[255:0] : m_r[255:0];
	assign o_finished = o_finished_r;

	always_comb begin
		// default
		i_a_w          = i_a_r;
		i_b_w          = i_b_r;
		i_n_w          = i_n_r;
		o_finished_w   = o_finished_r;
		state_w        = state_r;
		counter_w      = counter_r;
		m_w            = m_r;
		// FSM
		case (state_r)
			default: begin
				i_a_w          = i_a_r;
				i_b_w          = i_b_r;
				i_n_w          = i_n_r;
				o_finished_w   = o_finished_r;
				state_w        = state_r;
				counter_w      = counter_r;
				m_w            = m_r;
			end
			IDLE: begin
				if (i_start) begin
					state_w        = CALC;
					counter_w      = 0;
					m_w            = 0;
					i_a_w          = i_a;
					i_b_w          = i_b;
					i_n_w          = i_n;
				end
				else begin
					i_a_w          = i_a_r;
					i_b_w          = i_b_r;
					i_n_w          = i_n_r;
					state_w        = state_r;
					counter_w      = counter_r;
					m_w            = m_r;
				end
			end
			CALC: begin
				m_w = (m_temp[0] ? ((m_temp + i_n_r) >> 1) : (m_temp >> 1)); 
				i_a_w = i_a_r >> 1;
				
				if (counter_r == 255) begin
					state_w = DONE;
					o_finished_w = 1;
					counter_w = counter_r;
				end
				else begin
					state_w = state_r;
					o_finished_w = o_finished_r;
					counter_w = counter_r + 1;
				end
			end
			DONE: begin
				state_w = IDLE;
				o_finished_w = 0;
			end
		endcase
	end

	///////////sequential part///////////
	always_ff @(posedge i_clk or posedge i_rst) begin
		// reset
		if (i_rst) begin
			i_a_r          <= 0;
			i_b_r          <= 0;
			i_n_r          <= 0;
			o_finished_r   <= 0;
			state_r        <= IDLE;
			counter_r      <= 0;
			m_r            <= 0;
		end
		else begin
			i_a_r          <= i_a_w;
			i_b_r          <= i_b_w;
			i_n_r          <= i_n_w;
			o_finished_r   <= o_finished_w;
			state_r        <= state_w;
			counter_r      <= counter_w;
			m_r            <= m_w;
		end
	end

endmodule
