// 
// Module: tb
// 
// Notes:
// - TX level simulation testbench.
//

`timescale 1ns/1ps

module tb_tx;

reg        clk          ; // Top level system clock input.
reg        resetn       ;
wire       uart_txd     ; // UART TX pin.

wire       uart_tx_busy ; // TX busy
reg        uart_tx_en   ; // Enable TX line
reg [7:0]  uart_tx_data ; // Data to be send.

reg [7:0] received_data;  // Data received from TX line
reg error;

//
// Bit rate of the UART line we are testing.
localparam BIT_RATE = 9600;

//
// Period and frequency of the system clock.
localparam CLK_HZ   = 50_000_000;

localparam CYCLES_PER_BIT     = CLK_HZ / BIT_RATE;

//
// Make the clock tick.
initial
begin
    clk = 1'b0;

    forever
        # 5 clk = ~ clk;
end

task receive_byte;
integer i;
begin
    // Start bit
    // Waiting for start bit 
    while (uart_txd == 1'b1) 
    begin
        @(posedge clk);
    end

    repeat (CYCLES_PER_BIT) @(posedge clk);
    repeat (CYCLES_PER_BIT) @(posedge clk);
    
    // Data bits (LSB first)
    for(i = 0; i < 8; i = i + 1) 
    begin
        received_data[i] = uart_txd;
        repeat (CYCLES_PER_BIT) @(posedge clk); 
    end
    
    uart_tx_en = 1'b1;
    #10;
end
endtask


//
// Checks that the output of the UART is the value we expect.
integer passes = 0;
integer fails  = 0;
task check_byte;
    input [7:0] expected_value;
    input [7:0] received_value;
    begin
        if(received_value == expected_value) begin
            passes = passes + 1;
            $display("%d/%d/%d [PASS] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, received_value);
        end else begin
            fails  = fails  + 1;
            $display("%d/%d/%d [FAIL] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, received_value);
        end
    end
endtask

//
// Run the test sequence.
reg [7:0] to_send;
initial begin
    $display("Start of the task TX data");

    resetn     = 1'b0;
    clk        = 1'b0;
    #10
    
    resetn     = 1'b1;
    #10
    
    $dumpvars(0,tb_tx);

    repeat(50) 
    begin
        uart_tx_data = $random;
        #10;
        uart_tx_en = 1'b1;
        receive_byte(); 
        check_byte(uart_tx_data, received_data);
        received_data = 'b0;
    end

    $display("BIT RATE      : %db/s", BIT_RATE );
    $display("CYCLES/BIT    : %d"   , i_uart_tx.CYCLES_PER_BIT);

    $display("Test Results:");
    $display("    PASSES: %d", passes);
    $display("    FAILS : %d", fails);

    $display("Finish simulation at time %d", $time);
    $stop;
end




/*
input  wire         clk         , // Top level system clock input.
input  wire         resetn      , // Asynchronous active low reset.
output wire         uart_txd    , // UART transmit pin.
output wire         uart_tx_busy, // Module busy sending previous item.
input  wire         uart_tx_en  , // Send the data on uart_tx_data
input  wire [PAYLOAD_BITS-1:0]   uart_tx_data  // The data to be sent
*/
//
// Instance of the DUT
uart_tx #(
.BIT_RATE(BIT_RATE),
.CLK_HZ  (CLK_HZ  )
) i_uart_tx(
.clk          (clk          ), // Top level system clock input.
.resetn       (resetn       ), // Asynchronous active low reset.
.uart_txd     (uart_txd     ), // UART TX pin.
.uart_tx_busy (uart_tx_busy ), // TX busy line
.uart_tx_en   (uart_tx_en   ), // Transmition enable
.uart_tx_data (uart_tx_data )  // Data to be send
);

endmodule