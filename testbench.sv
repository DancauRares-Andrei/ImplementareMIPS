module MIPSProcessor_tb;

    reg clk;
    reg reset;
  wire [31:0] result;

    // Instantiate the MIPSProcessor module
    MIPSProcessor dut(
        .clk(clk),
        .reset(reset),
      .result(result)
    );

    // Clock generator
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        reset = 0;
        clk = 0;

        // Open the dump file
        $dumpfile("simulation.vcd");
        $dumpvars;

        // Wait for a few clock cycles after reset
//#80 reset = 1;
//      #20 reset = 0;

        // Stop the simulation
        #500 $finish;
    end

endmodule
