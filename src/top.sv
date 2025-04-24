
// 
// Module: top
// 
// Notes:
// - Top level module to be used in an implementation.
// - To be used in conjunction with the constraints/defaults.xdc file.
// - Ports can be (un)commented depending on whether they are being used.
// - The constraints file contains a complete list of the available ports
//   including the chipkit/Arduino pins.
//

module top (
input               clk     , // Top level system clock input.
input               sw_0    , // Slide switches.
input               sw_1    , // Slide switches.
input   wire        uart_rxd, // UART Recieve pin.
output  wire        uart_txd, // UART transmit pin.
output  wire [3:0]  led,

// For debug
output wire rx_valid,
output wire tx_busy
);

// Clock frequency in hertz.
parameter CLK_HZ       = 50_000_000;
parameter BIT_RATE     = 9600;
parameter PAYLOAD_BITS = 8;

parameter FIFO_WIDTH = 8;
parameter FIFO_DEPTH = 16;


wire [PAYLOAD_BITS-1:0]  uart_rx_data;
wire        uart_rx_valid;
wire        uart_rx_break;

wire        uart_tx_busy;
wire [PAYLOAD_BITS-1:0]  uart_tx_data;
wire        uart_tx_en, uart_rx_en;


wire full_fifo, empty_fifo;


reg  [PAYLOAD_BITS-1:0]  led_reg;
assign      led = led_reg;

// ------------------------------------------------------------------------- 
assign uart_tx_en   = ~empty_fifo;  // Add enable from user
assign uart_rx_en   = ~full_fifo;   // Add enable from user 

// ----------------------------- DEBUG -------------------------------------
assign rx_valid = uart_rx_valid;
assign tx_busy  = uart_tx_busy;
// ----------------------------- DEBUG -------------------------------------

always @(posedge clk) begin
    if(!sw_0) begin
        led_reg <= 8'hF0;
    end else if(uart_rx_valid) begin
        led_reg <= uart_rx_data[7:0];
    end
end


// ------------------------------------------------------------------------- 

//
// UART RX
uart_rx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk          ), // Top level system clock input.
.resetn       (sw_0         ), // Asynchronous active low reset.
.uart_rxd     (uart_rxd     ), // UART Recieve pin.
.uart_rx_en   (uart_rx_en   ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data )  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_tx(
.clk          (clk          ),
.resetn       (sw_0         ),
.uart_txd     (uart_txd     ),
.uart_tx_en   (uart_tx_en   ),
.uart_tx_busy (uart_tx_busy ),
.uart_tx_data (uart_rx_data ) 
);

//
// FIFO module
//
fifo #(
    .WIDTH    (FIFO_WIDTH),
    .DEPTH    (FIFO_DEPTH)
)
i_fifo
(
    .clk          (     clk              ),
    .rst          (     ~sw_0            ),
    .push         (     uart_rx_valid    ),
    .pop          (     ~uart_tx_busy    ),
    .write_data   (     uart_rx_data     ),
    .read_data    (     uart_tx_data     ),
    .empty        (     empty_fifo       ),
    .full         (     full_fifo        )
);

endmodule
