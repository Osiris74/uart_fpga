// 
// Module: tb
// 

`timescale 1ns/1ps
`define WAVES_FILE "waves-rx.vcd"

module tb_rx;
    
reg        clk          ; // Top level system clock input.
reg        resetn       ; // Top level reset input
reg        uart_rxd     ; // UART Recieve pin.

reg        uart_rx_en   ; // Recieve enable
wire       uart_rx_break; // Did we get a BREAK message?
wire       uart_rx_valid; // Valid data recieved and available.
wire [7:0] uart_rx_data ; // The recieved data.

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

task send_byte;
input [7:0] data;
integer i;
begin
    // Start bit
    uart_rxd = 'b0;
    repeat (CYCLES_PER_BIT) @(posedge clk); 
    
    // Data bits (LSB first)
    for(i = 0; i < 8; i = i + 1) 
    begin
        uart_rxd = data[i];
        repeat (CYCLES_PER_BIT) @(posedge clk); 
    end

    // Stop bit
    uart_rxd = 1'b1;
    repeat (CYCLES_PER_BIT) @(posedge clk); 
end
endtask


//
// Checks that the output of the UART is the value we expect.
integer passes = 0;
integer fails  = 0;
task check_byte;
    input [7:0] expected_value;
    begin
        if(uart_rx_data == expected_value) begin
            passes = passes + 1;
            $display("%d/%d/%d [PASS] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, uart_rx_data);
        end else begin
            fails  = fails  + 1;
            $display("%d/%d/%d [FAIL] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, uart_rx_data);
        end
    end
endtask

//
// Run the test sequence.
reg [7:0] to_send;
initial begin
    $display("Start of the task RX data");
    
    resetn     = 1'b0;
    clk        = 1'b0;
    uart_rxd   = 1'b1;
    #100 
    
    resetn     = 1'b1;
    #100 
    
    //$dumpfile(`WAVES_FILE);
    $dumpvars(0,tb_rx);

    uart_rx_en = 1'b1;

    #100;

    repeat(100) begin
        to_send = $random;
        send_byte(to_send); 
        check_byte(to_send);
    end

    $display("BIT RATE      : %db/s", BIT_RATE );
    $display("CYCLES/BIT    : %d"   , i_uart_rx.CYCLES_PER_BIT);

    $display("Test Results:");
    $display("    PASSES: %d", passes);
    $display("    FAILS : %d", fails);

    $display("Finish simulation at time %d", $time);
    $finish;
end


//
// Instance of the DUT
uart_rx #(
.BIT_RATE(BIT_RATE),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk          ), // Top level system clock input.
.resetn       (resetn       ), // Asynchronous active low reset.
.uart_rxd     (uart_rxd     ), // UART Recieve pin.
.uart_rx_en   (uart_rx_en   ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data )  // The recieved data.
);

endmodule