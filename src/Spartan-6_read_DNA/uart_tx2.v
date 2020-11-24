// Module UART TX DATA(RS-232)-------------------------------------------------
// INPUT:
// i_clk  - global system clk
// i_en_h - =1 enable TX module
// i_div  - set predelitel () DIV[16] = F(clk) / (4 * SPEED(bit/s))
// i_we_h - strob 
// i_tx_data - byte data to tx
// i_parity_en_h - bit parity disable(0) / enable (1)
// i_parity_type_el_oh - bit parity type E (Even parity) — proverka na chetnost O (Odd parity) — proverka na NE chetnost;
//
// format slova: 8N1, 8E1, 8O1. (start-data-stop), (start-data-parity-stop)
//
// OUTPUT:
// o_int_h - interrupt(ACTIVE HIGH), byte recive
// o_tx   - TX data RS232
//
// v2.0 2015
// stop bit zakanchivaem peredachu ranhe na 1 c_pulse
//=============================================================================
// DIV[16] = F(clk) / (4 * SPEED(bit/s))
// div115200 = 25000000(25MHz) / (4 * 115200) = 54.25 => 54(10) => 36(16)
//
//
//data  kolichestvo 1  bit chetnosti
//                       even odd
//0000000   0               0  1
//1010001   3               1  0
//1101001   4               0  1
//1111111   7               1  0
//
//=============================================================================

//`define DEBUG

module uart_tx (
    input wire i_clk,              // Clk input
    input wire i_en_h,             // module enable active-HIGH
    input wire [15:0] i_div,       // div speed uart-rx. (baud = clk / div)
    input wire [7:0] i_tx_data,    // data out
    input wire i_we_h,             // we strob Active HIGH, tx_data write to modul

    input wire i_parity_en_h,      // bit parity disable(0) / enable (1)
    input wire i_parity_type_el_oh,// bit parity type E (Even parity) — proverka na chetnost O (Odd parity) — proverka na NE chetnost;
     
    output reg o_int_h = 0,        // strob interupt active-HIGH, rx->data out
    output reg o_tx = 1,           // rs-232 output
    output reg o_busy_h = 0        // (STATUS) busy=1 uart tx byte
     
// debug -------------------------------
`ifdef DEBUG
    ,
    output wire pulse_o,
    output wire [7:0] d,
    output wire [5:0] c_pulse_t
`endif
);

parameter TX_WAIT_DATA = 1'b0, TX_START = 1'b1;//, TX_B0 = 2, TX_B1 = 3, TX_B2 = 4, TX_B3 = 5, TX_B4 = 6, TX_B5 = 7, TX_B6 = 8, TX_B7 = 9, TX_STOP = 10; 
reg state = TX_WAIT_DATA; // sostoyanie avtomata = nachalnoe sostoyanie avtomata

reg enable_counter = 0;          // signal razreheniya raboti countera DIV(predelitela)
reg [7:0] tx_d = 0;              // promuhutochiny buffer dla prinatie danie 8 bit ot system
reg [15:0] div_q = 0;            // counter dla predilitela
reg [15:0] div = 0;              // counter dla predilitela
reg pulse = 0;                   // 1 tic, raboti DIV(predelitela)
reg [5:0] c_pulse = 0;           // counter pulse, avtomat, otscheti po kotorim chitaem intervali TX


always @( posedge i_clk)
begin
    case (state)
    TX_WAIT_DATA:                          // ohidaem zapisi danih strob we_h 0->1
    begin
        o_int_h <= 0;                        // Clear flag INT_H, itogo strob 1 takt !!!
        if (i_en_h && i_div != 0 && i_we_h) begin
            div <= i_div;
            state <= TX_START;
            enable_counter <= 1;
            o_tx <= 0;                       // send start
            tx_d <= i_tx_data;
            o_busy_h <= 1;                   // busy set, start tx byte
        end
    end
     
    TX_START:
    begin
    if (pulse) begin
        case (c_pulse)
        3,//: o_tx <= tx_d[ 0 ];// tx 0 bit 
        7,//: o_tx <= tx_d[ 1 ];// tx 1 bit
        11,//: o_tx <= tx_d[ 2 ];// tx 2 bit
        15,//: o_tx <= tx_d[ 3 ];// tx 3 bit
        19,//: o_tx <= tx_d[ 4 ];// tx 4 bit
        23,//: o_tx <= tx_d[ 5 ];// tx 5 bit
        27,//: o_tx <= tx_d[ 6 ];// tx 6 bit
        31:// o_tx <= tx_d[ 7 ];// tx 7 bit
        begin
            o_tx <= tx_d[ c_pulse[4:2] ];
        end
          
        35: // parity | tx stop bit
        begin
            if (i_parity_en_h) begin
                if (i_parity_type_el_oh == 0)
                    o_tx <= ^{tx_d, 1'b1}; // tx parity event
                else
                    o_tx <= ^{tx_d, 1'b0}; // tx parity odd 
                end else o_tx <= 1;  // tx stop bit
        end
          
        38:
        begin
            if (i_parity_en_h == 0) begin
                enable_counter <= 0;
                state <= TX_WAIT_DATA;
                o_int_h <= 1;
                o_busy_h <= 0;
            end 
        end
          
        39:
        begin
            if (i_parity_en_h) begin
                o_tx <= 1;  // tx stop bit
            end else begin
                enable_counter <= 0;
                state <= TX_WAIT_DATA;
                o_int_h <= 1;
                o_busy_h <= 0;
            end 
        end
          
        41:
        begin
            enable_counter <= 0;
            state <= TX_WAIT_DATA;
            o_int_h <= 1;
            o_busy_h <= 0;
        end
          
        endcase
    end // if
    end
 
    endcase
end

//-----------------------------------------------------------------------------
// counter 1 tic * 4
//-----------------------------------------------------------------------------
always @(posedge i_clk)
begin
    if (enable_counter) begin
        if (pulse)
            c_pulse <= c_pulse + 1'b1;
    end else 
        c_pulse <= 0;
end

//-----------------------------------------------------------------------------
// counter bit interval / 4
//-----------------------------------------------------------------------------
always @( posedge i_clk )
begin
    if (enable_counter == 0) begin
        div_q <= 0;
    end else begin
        if (div_q == div && div != 0) begin
            div_q <= 0;
            pulse <= 1;
        end else begin
            pulse <= 0;
            div_q <= div_q + 1'b1;
        end
    end
end

`ifdef DEBUG
assign pulse_o = pulse;
assign d = tx_d;
assign c_pulse_t = c_pulse;
`endif

endmodule