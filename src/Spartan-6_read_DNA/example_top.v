//*****************************************************************************
// Проект чтение DNA Spartan-6
//
// Вывод осуществляется циклически один раз в секунду, 
// в UART порт (115200 8N1), в бинарном виде.
//*****************************************************************************
//*****************************************************************************
`timescale 1ns/1ps

module example_top
(
    input  wire i_sys_clk,
    output wire d_fpg3,
    output wire o_led
);
localparam I_SYS_CLK = 32'd50_000_000; // входная тактовая частота

wire sys_clk_ibufg;

//-----------------------------------------------------------------------
IBUFG  u_ibufg_sys_clk
(
    .I  (i_sys_clk),
    .O  (sys_clk_ibufg)
);

wire dna_dout;
reg dna_read = 0;
reg dna_shift = 0;


DNA_PORT #(
    .SIM_DNA_VALUE(57'h000000000000000)  // Specifies the Pre-programmed factory ID value
)
DNA_PORT_inst (
    .DOUT   (dna_dout),        // 1-bit output: DNA output data
    .CLK    (sys_clk_ibufg),   // 1-bit input: Clock input
    .DIN    (1'b0),            // 1-bit input: User data input pin
    .READ   (dna_read),        // 1-bit input: Active high load DNA, active low read input
    .SHIFT  (dna_shift)        // 1-bit input: Active high shift enable input
);

reg [1:0] tick_sh = 0;
reg       tick = 0;

reg [25:0] led_count = 0;
reg        led = 0;
//------------------------------------------------------------------------------
// Led blink
//------------------------------------------------------------------------------
always @(posedge sys_clk_ibufg)
begin
    led_count <= led_count + 1'b1;
    if (led_count == I_SYS_CLK / 2) begin
        led_count <= 0;
        led       <= ~led;
    end

    tick_sh[0] <= ~led;
    tick_sh[1] <= tick_sh[0];
     
    if (tick_sh[1:0] == 2'b01) tick <= 1;
    else tick <= 0;
end

assign o_led  = led;

wire u_tx_busy;
reg [7:0] u_tx_data = 0;
reg       u_tx_we = 0;

uart_tx U_TX
(
    .i_clk      (sys_clk_ibufg),    // Clk input
    .i_en_h     (1'b1),       // module enable active-HIGH
    .i_div      (I_SYS_CLK / (4 * 115200)),        // div speed uart-rx. (baud = clk / div)
    .i_tx_data  (u_tx_data),  // data out
    .i_we_h     (u_tx_we),    // we strob Active HIGH, tx_data write to modul
    .i_parity_en_h(1'b0),      // bit parity disable(0) / enable (1)
    .i_parity_type_el_oh(1'b0),// bit parity type E (Even parity) вЂ" proverka na chetnost O (Odd parity) вЂ" proverka na NE chetnost;
//   .o_int_h    (),           // strob interupt active-HIGH, rx->data out
    .o_tx       (d_fpg3),     // rs-232 output
    .o_busy_h   (u_tx_busy)   // (STATUS) busy=1 uart tx byte
);

reg [7:0]  d_st = 0;
reg [6:0]  d_count = 0;
reg [63:0] dna_code = 0;

// MY debug port ----------------------------------------
always @(posedge sys_clk_ibufg)
begin
    case(d_st)
    0:
    begin
        dna_read <= 1;
        d_st <= 1;
    end

    1:
    begin
        dna_read <= 0;
        d_count <= 0;
        d_st <= 2;
    end
    
    2:
    begin
        d_count <= d_count + 1'b1;
        dna_code[0] <= dna_dout;
        dna_code[63:1] <= dna_code[62:0];
        if (d_count == 'd57 - 1) begin
            dna_shift <= 0;
            d_st <= 3;
        end else dna_shift <= 1;
    end
    
    3:
    begin
        d_count <= 0;
        if (u_tx_busy == 0) d_st <= 4;
    end
     
    4:
    begin
        case(d_count)
        0: u_tx_data <= dna_code[63:56];
        1: u_tx_data <= dna_code[55:48];
        2: u_tx_data <= dna_code[47:40];
        3: u_tx_data <= dna_code[39:32];
        4: u_tx_data <= dna_code[31:24];
        5: u_tx_data <= dna_code[23:16];
        6: u_tx_data <= dna_code[15:8];
        7: u_tx_data <= dna_code[7:0];
        default:u_tx_data <= 0;
        endcase
        u_tx_we <= 1;
        d_st <= 5;
    end
     
    5:
    begin
        u_tx_we <= 0;
        d_st <= 6;
    end
     
    6:
    begin
        d_st <= 7;
    end
    
    7:
    begin
        if(u_tx_busy == 0) begin    
            if (d_count < 'd7) begin
                d_count <= d_count + 1;
                d_st <= 4;
            end else begin
                d_st <= 8;
            end
        end
    end 
     
    8:
    begin
        if (tick) d_st <= 3; 
    end
     
    default: d_st <= 0;
    endcase
end

endmodule   

