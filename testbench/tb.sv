// 
// Module: tb
// 
// Notes:
// - TX level simulation testbench.
//

`timescale 1ns/1ps

module tb;

reg         clk          ; // Top level system clock input.
reg         resetn       ;
reg   uart_rxd     ; 
wire  uart_txd     ; //

logic sw_0;
reg [7:0] sended_data;  // Data received from TX line



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
    
    // Data bits (LSB first)
    for(i = 0; i < 8; i = i + 1) 
    begin
        sended_data[i] = uart_txd;
        repeat (CYCLES_PER_BIT) @(posedge clk); 
    end

    repeat (CYCLES_PER_BIT) @(posedge clk);
    
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

    sended_data = 'b0;
    sw_0 = 'b0;
    #10;

    $display("Start of the task TOP ");  
    $dumpvars(0,tb);

    sw_0 = 'b1;
    #10;

    repeat(20) 
    begin
        to_send = $random;
        #10;
        send_byte(to_send); 
        receive_byte();
        check_byte(to_send, sended_data);
        sended_data = 'b0;
    end

    $display("BIT RATE      : %db/s", BIT_RATE );

    $display("Test Results:");
    $display("    PASSES: %d", passes);
    $display("    FAILS : %d", fails);

    $display("Finish simulation at time %d", $time);
    $finish;
end

logic rx_valid;
logic tx_busy;

// Instance of the DUT
top i_top
(
.clk          (clk          ), // Top level system clock input.
.sw_0         (sw_0         ), // 
.sw_1         (sw_0         ), // .
.uart_rxd     (uart_rxd     ), // 
.uart_txd     (uart_txd     ), 
.led          (led          ),

.rx_valid     (rx_valid     ),
.tx_busy      (tx_busy      )
);


/*
uart_rx #(
.BIT_RATE(BIT_RATE),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk          ), // Top level system clock input.
.resetn       (resetn       ), // Asynchronous active low reset.
.uart_rxd     (uart_txd     ), // UART Recieve pin.
.uart_rx_en   (uart_rx_en   ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data )  // The recieved data.
);

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
*/




endmodule