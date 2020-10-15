module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first
parameter S_IDLE = 2'd0;
parameter S_PROC = 2'd1;
parameter S_FINAL = 2'd2; 
parameter S_COUNTDOWN = 2'd3;

//linear congruential generator coefficient
parameter A = 5'd5;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w, temp_random_out_w, temp_random_out_r;
logic [3:0] number_out_r, number_out_w;

// ===== Registers & Wires =====
logic [1:0] state_r, state_w;
logic [31:0] counter_r, counter_w;
logic [3:0] seed_r, seed_w, B_r, B_w;
logic [3:0] congruent_r, congruent_w;

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	seed_w = seed_r;
	counter_w = counter_r;
	temp_random_out_w = temp_random_out_r;
	congruent_w = congruent_r;
	B_w = B_r;

	// FSM
	case(state_r)
	S_IDLE: begin
		seed_w = (seed_r < 4'd15)?seed_r+2:1;
		$display("%d",seed_r);
		state_w = S_IDLE;
		o_random_out_w = o_random_out_r;
		if (i_start) begin
			state_w = S_PROC;
			o_random_out_w = seed_r;
			counter_w = 32'd0;
			B_w = seed_r;
		end
	end

	S_PROC: begin
		o_random_out_w = o_random_out_r;
		state_w = state_r;
		seed_w = (seed_r < 4'd15)?seed_r+2:1;
		temp_random_out_w = o_random_out_r;
		if (i_start) begin
			state_w = S_COUNTDOWN;
			counter_w = 32'd0;
			o_random_out_w = temp_random_out_r;
		end
		else begin
			counter_w = counter_r+1;
		end

		case(counter_r)
		0: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end	
		100000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		200000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		600000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		1000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		1500000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		2000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		5000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		10000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		16000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		24000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		34000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		60000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		100000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		200000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		340000000: begin
			congruent_w = (A*congruent_r+B_r)%16;
			o_random_out_w = congruent_r;
			state_w = S_PROC;
			$display("%d",o_random_out_w);
		end
		350000000: begin
			o_random_out_w = o_random_out_r;
			state_w = S_FINAL;
			temp_random_out_w = o_random_out_r;
			$display("%d",o_random_out_w);
			counter_w = 32'd0;
		end
		endcase
	end
	S_FINAL:begin
		state_w = S_FINAL;
		counter_w = counter_r+1;
		if (i_start) begin
			state_w = S_COUNTDOWN;
			counter_w = 32'd0;
			o_random_out_w = temp_random_out_r;
		end
		if(counter_r==20000000) begin
			o_random_out_w = 4'd0;
		end
		else if(counter_r==40000000) begin
			o_random_out_w = temp_random_out_r;
			counter_w = 32'd0;
		end
	end
	S_COUNTDOWN:begin
		if(i_start) begin
			state_w = S_PROC;
			counter_w = 32'd0;
			B_w = seed_r;
		end
		else begin
			counter_w = counter_r+1;
			state_w = S_COUNTDOWN;
			if(o_random_out_r==0) begin
				temp_random_out_w = 4'd0;
				o_random_out_w = 4'd0;
				state_w = S_IDLE;
				counter_w = 32'd0;
			end
			else if(counter_r==20000000) begin
				o_random_out_w = o_random_out_r-1;
				state_w = S_COUNTDOWN;
				counter_w = 32'd0;
			end
		end
	end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		state_r        <= S_IDLE;
		counter_r	   <= 32'd0;
		seed_r		   <= 4'd1;
		temp_random_out_r <= 4'd0;
		congruent_r    <= 4'd1;
		B_r            <= 4'd5;
	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
		counter_r	   <= counter_w;
		seed_r  	   <= seed_w;
		temp_random_out_r <= temp_random_out_w;
		congruent_r    <= congruent_w;
		B_r            <= B_w;
	end
end

endmodule
