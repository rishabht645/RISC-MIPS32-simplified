module tb1 ();
    reg clk1,clk2; integer k;
    pipeline_mips32 P(.clk1(clk1),.clk2(clk2));

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (20) begin
            #5 clk1 = 1; #5  clk1 = 0;
            #5 clk2 = 1; #5  clk2 = 0;
        end
    end

    initial begin
        for (k = 0;k<=31 ;k=k+1 ) begin
            P.regbank[k] = k;
        end
        P.memory[0] = 32'h28010078;    // ADDI  R1,R0,120
        P.memory[1] = 32'h0c631800;    // OR    R3,R3,R3   -- dummy instr.
        P.memory[2] = 32'h20220000;    // LW    R2,0(R1)
        P.memory[3] = 32'h0c631800;    // OR    R3,R3,R3   -- dummy instr.
        P.memory[4] = 32'h2842002d;    // ADDI  R2,R2,45
        P.memory[5] = 32'h0c631800;    // OR    R3,R3,R3   -- dummy instr.
        P.memory[6] = 32'h24220001;    // SW    R2,1(R1)
        P.memory[7] = 32'hfc000000;    // HLT

        P.memory[120] = 85;


        P.PC = 0;
        P.HALTED = 0;
        P.BRANCH_TAKEN = 0;

        #280 
        $display("memory[120] = %4d \nmemory[121] = %4d", P.memory[120], P.memory[121]);
    end

    initial begin
        $dumpfile("P32.vcd");
        $dumpvars(0,tb1);
        #300 $finish;
    end
endmodule