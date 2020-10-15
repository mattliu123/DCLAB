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
parameter IDLE = 3'd0;
parameter PREP = 3'd1;
parameter MONT = 3'd2;
parameter CALC = 3'd3;

logic o_finished_w, o_finished_r;
logic [2:0] state_r, state_w;
logic [257:0] t_r, t_w, m_r, m_w, mptout, mpmout, m1_r, m1_w, m2_r, m2_w, mn0out, mn1out, o_a_pow_d_r, o_a_pow_d_w;
logic [8:0] counter_r, counter_w, counter1_r, counter1_w;
logic[256:0] two_pow_256;
assign two_pow_256 = {1'b1, 256'd0};
ModuloProduct mp(
	.a(two_pow_256[counter_r]),
	.tin(t_r),
	.N(i_n),
	.Min(m_r),
	.Mout(mpmout),
	.tout(mptout)
	);
Montgomery mont0(
	.a(m_r[counter1_r]),
	.N(i_n),
	.Min(m1_r),
	.b(t_r),
	.Mout(mn0out)
	);
Montgomery mont1(
	.a(t_r[counter1_r]),
	.N(i_n),
	.Min(m2_r),
	.b(t_r),
	.Mout(mn1out)
	);
assign o_finished = o_finished_r;
assign o_a_pow_d = o_a_pow_d_r;
always_comb begin
	counter1_w = counter1_r;
	counter_w = counter_r;
	t_w = t_r;
	m_w = m_r;
	m1_w = m1_r;
	m2_w = m2_r;
	o_finished_w = o_finished_r;
	case (state_r)
		IDLE:begin
			o_finished_w = 0;
			if(i_start) begin
				state_w = PREP;
				t_w = i_a;
				m_w = 0;
			end
			else begin
				state_w = state_r;
			end
		end
		PREP:begin
			t_w = mptout;
			m_w = mpmout;
			if(counter_r==9'd256)begin
				state_w = MONT;
				counter_w = 9'd0;
				counter1_w = 9'd0;
				m1_w = 258'd0;
				m2_w = 258'd0;
				m_w = 258'd1;
				t_w = mpmout;
			end
			else begin
				state_w = state_r;
				counter_w = counter_r+1;
			end
		end
		MONT:begin
			if(counter1_r==9'd255)begin
				state_w = CALC;
				t_w = (mn1out>=i_n)?mn1out-i_n:mn1out;
				if(i_d[counter_r])begin
					m_w = (mn0out>=i_n)?mn0out-i_n:mn0out;
				end
				counter1_w = 9'd0;
			end
			else begin
				state_w = state_r;
				m1_w = mn0out;
				m2_w = mn1out;
				counter1_w = counter1_r+1;

			end


		end  
		CALC:begin
			if(counter_r==9'd255)begin
				counter_w = 9'd0;
				state_w = IDLE;
				o_finished_w = 1;
				o_a_pow_d_w = m_r;
			end
			else begin
				counter_w = counter_r+1;
				state_w = MONT;
				m1_w = 258'd0;
				m2_w = 258'd0;
			end
		end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		 state_r <= IDLE;
		 counter_r<=9'd0;
		 t_r <= 258'd0;
		 m_r <= 258'd0;
		 counter1_r<=9'd0;
		 m1_r<=258'd0;
		 m2_r<=258'd0;
		 o_finished_r<=0;
		 o_a_pow_d_r<=0;
	end else begin
		state_r <= state_w;
		counter_r <= counter_w;
		t_r <= t_w;
		m_r <= m_w;
		counter1_r<=counter1_w;
		m1_r<=m1_w;
		m2_r<=m2_w;
		o_finished_r<=o_finished_w;
		o_a_pow_d_r<=o_a_pow_d_w;
	end
end

// operations for RSA256 decryption
// namely, the Montgomery algorithm

endmodule

module ModuloProduct (
	input  a,
	input [257:0] tin,
	input [255:0] N,
	input [257:0] Min,
	output [257:0] Mout,
	output [257:0] tout
);
logic[257:0] temp;
logic[257:0] temp0;
assign Mout = temp;
assign tout = temp0;
always_comb begin
	if(a)begin
		if((Min+tin)>=N)begin
			temp = Min+tin-N;
		end
		else begin
			temp = Min+tin;
		end
	end
	else begin
		temp = Min;
	end
	if ((tin+tin)>N) begin
		temp0 = tin+tin-N;
	end
	else begin
		temp0 = tin+tin;
	end
end

endmodule

module Montgomery (
	input	a,
	input [255:0] N,
	input [257:0] Min,
	input [257:0] b,
	output [257:0] Mout
);

logic [257:0] temp0, temp1, temp2;
assign Mout = temp2;
always_comb begin
	if(a)begin
		temp0 = Min+b;
	end
	else begin
		temp0 = Min;
	end
	if (temp0[0]==1) begin
		temp1 = temp0+N;
	end
	else begin
		temp1 = temp0;
	end
	temp2 = temp1/2;
end

endmodule
