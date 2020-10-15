// ------ 2020/04/03 21:00 by BAO --------  //

module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
    //output [3:0] state
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_GET_KEY        = 0;
localparam S_GET_DATA       = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_GET_WRITE      = 3;
localparam S_SEND_DATA      = 4;


logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [3:0] state_r, state_w;
//logic [6:0] bytes_counter_r, bytes_counter_w;
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

logic [7:0] count_r, count_w;
logic done_r, done_w;

assign avm_address   = avm_address_r;
assign avm_read      = avm_read_r;
assign avm_write     = avm_write_r;
assign avm_writedata = dec_r[247-:8];
//assign state         = state_r;

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w    = 1;
        avm_write_w   = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w    = 0;
        avm_write_w   = 1;
        avm_address_w = addr;
    end
endtask

always_comb begin
    // TODO
    // default
    n_w             = n_r;
    d_w             = d_r;
    enc_w           = enc_r;
    dec_w           = dec_r;
    avm_address_w   = avm_address_r;
    avm_read_w      = avm_read_r;
    avm_write_w     = avm_write_r;
    state_w         = state_r;
    rsa_start_w     = rsa_start_r;
    count_w         = count_r;
    done_w          = done_r;

    case(state_r)
    S_GET_KEY: begin    // rrdy == 1 => goto get data state
        if (!avm_waitrequest) begin
            //StartRead(STATUS_BASE);
            if(avm_address_r == STATUS_BASE && avm_readdata[RX_OK_BIT] == 1) begin
                state_w = S_GET_DATA;
                StartRead(RX_BASE);
            end
            else state_w = S_GET_KEY;
        end
    end
    S_GET_DATA: begin   
        if (!avm_waitrequest && avm_address_r == RX_BASE) begin
            count_w = count_r + 1;
            if(count_r < 8'd32 && done_r == 0) begin
                n_w[255 - count_r*8 -: 8] = avm_readdata[7:0];
                enc_w       = enc_r;
                d_w         = d_r;
                state_w     = S_GET_KEY;
                rsa_start_w = rsa_start_r;
                StartRead(STATUS_BASE);
            end
            else if(count_r < 8'd31  && done_r == 1) begin
                enc_w[255 - count_r*8 -: 8] = avm_readdata[7:0];
                n_w         = n_r;
                d_w         = d_r;
                state_w     = S_GET_KEY;
                rsa_start_w = rsa_start_r;
                StartRead(STATUS_BASE);
            end
            else if(count_r == 8'd31  && done_r == 1) begin
                enc_w[255 - count_r*8 -: 8] = avm_readdata[7:0];
                n_w         = n_r;
                d_w         = d_r;
                state_w     = S_WAIT_CALCULATE;
                rsa_start_w = 1;
                avm_read_w  = 0;
            end
            else if (count_r < 8'd64 && count_r >= 8'd32 && done_r == 0) begin
                d_w[255 - (count_r-32)*8 -: 8] = avm_readdata[7:0];
                enc_w       = enc_r;
                n_w         = n_r;
                state_w     = S_GET_KEY;
                rsa_start_w = rsa_start_r;
                StartRead(STATUS_BASE);
            end
            else if(count_r < 8'd95 && count_r >= 8'd64 && done_r == 0) begin
                enc_w[255 - (count_r-64)*8 -: 8] = avm_readdata[7:0];
                n_w         = n_r;
                d_w         = d_r;
                state_w     = S_GET_KEY;
                rsa_start_w = rsa_start_r;
                StartRead(STATUS_BASE);
            end
            else if(count_r == 8'd95 && done_r == 0) begin
                enc_w[255 - (count_r-64)*8 -: 8] = avm_readdata[7:0];
                n_w         = n_r;
                d_w         = d_r;
                state_w     = S_WAIT_CALCULATE;
                rsa_start_w = 1;
                avm_read_w  = 0;
            end
            else begin
                n_w         = n_r;
                d_w         = d_r;
                enc_w       = enc_r;
                state_w     = state_r;
                rsa_start_w = rsa_start_r;
                avm_read_w  = avm_read_r;
            end
        end 
        else begin
            n_w         = n_r;
            d_w         = d_r;
            enc_w       = enc_r;
            count_w     = count_r;
            state_w     = state_r;
            rsa_start_w = rsa_start_r;
            avm_read_w  = avm_read_r;
        end

    end

    S_WAIT_CALCULATE:begin     
        if(rsa_finished == 1'b1) begin
            state_w = S_GET_WRITE;
            //StartRead(STATUS_BASE);
            rsa_start_w = 0;
            count_w = 0;
            StartRead(STATUS_BASE);
        end
        else begin 
            state_w     = S_WAIT_CALCULATE;
            rsa_start_w = rsa_start_r;   
            count_w     = 0; 
        end
    end

    S_GET_WRITE:begin   // trdy == 1 => goto send data state  
        if (!avm_waitrequest) begin
            //StartRead(STATUS_BASE);
            if(avm_address_r == STATUS_BASE && avm_readdata[TX_OK_BIT] == 1) begin
                state_w   = S_SEND_DATA;      
                if(count_r != 0) StartWrite(TX_BASE);
                //else              StartRead(STATUS_BASE);
            end
            else state_w  = S_GET_WRITE;
        end
    end

    S_SEND_DATA: begin
        if (!avm_waitrequest && avm_address_r == TX_BASE) begin 
            avm_address_w = STATUS_BASE;
            if(count_r < 6'd31) begin
                dec_w = (count_r == 0) ? rsa_dec : dec_r << 8;
                count_w         = count_r + 1;
                state_w         = S_GET_WRITE;
                StartRead(STATUS_BASE);
                done_w          = done_r;
                enc_w           = enc_r;
            end
            else begin
                dec_w           = dec_r;
                count_w         = 0;
                state_w         = S_GET_KEY;
                StartRead(STATUS_BASE);
                done_w          = 1;
                enc_w           = 0;
            end
        end
        else begin
            dec_w               = dec_r;
            count_w             = count_r;
            state_w             = state_r;
            done_w              = done_r;
            avm_write_w         = avm_write_r;
            enc_w               = enc_r;
        end
    end 
    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r             <= 0;
        d_r             <= 0;
        enc_r           <= 0;
        dec_r           <= 0;
        avm_address_r   <= STATUS_BASE;
        avm_read_r      <= 1;
        avm_write_r     <= 0;
        state_r         <= S_GET_KEY;
        rsa_start_r     <= 0;
        count_r         <= 0;
        done_r          <= 0;
    end else begin
        n_r             <= n_w;
        d_r             <= d_w;
        enc_r           <= enc_w;
        dec_r           <= dec_w;
        avm_address_r   <= avm_address_w;
        avm_read_r      <= avm_read_w;
        avm_write_r     <= avm_write_w;
        state_r         <= state_w;
        rsa_start_r     <= rsa_start_w;
        count_r         <= count_w;
        done_r          <= done_w;
    end
end

endmodule
