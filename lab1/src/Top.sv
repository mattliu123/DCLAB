module Top (
	input        i_clk,
	input        i_rst_n, // key1
	input        i_start, // key0
	output [3:0] o_random_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first
// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;
logic [63:0] random_number_r, random_number_w;
logic [63:0] counter; 

// ===== Registers & Wires =====
logic state_r, state_w;

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;

// ===== Parameters ====
// Linear Congruential  Using C++ min_std_rand
// Reference: http://rdsl.csit-sun.pub.ro/docs/PROIECTARE%20cu%20FPGA%20CURS/lecture6[1].pdf
parameter multiplier = 48271;
parameter modulus = 2147483648;

// Counter parameters, clock rate = 50MHz
// If we want the count down to last for 3 secs,
// we need max_count = 50MHz x 3 secs = 150M counts
parameter max_count = 150000000;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w = o_random_out_r;
	state_w        = state_r;

	// Linear congruential generator
	random_number_w = ((random_number_r * multiplier) % modulus) % 16;

	// FSM
	case(state_r)
		S_IDLE: begin
			if (i_start) begin
				state_w = S_PROC;
				o_random_out_w = 4'd10;
			end
			else begin 
				state_w = state_r;
				o_random_out_w = o_random_out_r;
			end
		end

		S_PROC: begin

			// Final output state
			if (counter == max_count) begin 
				state_w = S_IDLE;
				o_random_out_w = random_number_w;
			end

			// Other outputs state, decaying display frequency
			else if (counter == ... || counter == ... )begin 
				state_w = state_r;
				o_random_out_w = random_number_w;
			end 

			// Darken LCD outputs
			else begin 
				state_w = state_r;
				o_random_out_w = o_random_out_r;
			end
		end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin // Key1, set counter = 0 
		state_r <= S_IDLE;
		counter <= 0;
		random_number_r <= 0;
		o_random_out_r <= 0;

	end
	else begin
		if (i_start) begin // Case for pressing start
			state_r <= S_PROC;
			counter <= 0;
			random_number_r <= counter;
			o_random_out_r <= o_random_out_w;
		end
		else begin // Case for ordinary
			state_r <= state_w;
			counter <= counter + 1;
			random_number_r <= random_number_w;
			o_random_out_r <= o_random_out_w;
		end
	end
end
endmodule
