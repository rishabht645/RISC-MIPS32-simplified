module tb1 ();
    reg clk1,clk2; integer k;
    pipeline_mips32 P(.clk1(clk1),.clk2(clk2));

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (50) begin
            #5 clk1 = 1; #5  clk1 = 0;
            #5 clk2 = 1; #5  clk2 = 0;
        end
    end

    initial begin
        for (k = 0;k<=31 ;k=k+1 ) begin
            P.regbank[k] = k;
        end
        P.memory[0]  = 32'h280a00c8;    // ADDI  R10,R0,200
        P.memory[1]  = 32'h28020001;    // ADDI  R2,R0,1
        P.memory[2]  = 32'h0e94a000;    // OR    R20,R20,R20  -- dummy instr.
        P.memory[3]  = 32'h21430000;    // LW    R3,0(R10)
        P.memory[4]  = 32'h0e94a000;    // OR    R20,R20,R20  -- dummy instr.
        P.memory[5]  = 32'h14431000;    // Loop: MUL  R2,R2,R3
        P.memory[6]  = 32'h2c630001;    // SUBI  R3,R3,1
        P.memory[7]  = 32'h0e94a000;    // OR    R20,R20,R20  -- dummy instr.
        P.memory[8]  = 32'h3460fffc;    // BNEQZ R3,Loop (i.e. -4 offset)
        P.memory[9]  = 32'h2542fffe;    // SW    R2,-2(R10)
        P.memory[10] = 32'hfc000000;    // HLT


        P.memory[200] = 7;


        P.PC = 0;
        P.HALTED = 0;
        P.BRANCH_TAKEN = 0;

        #2000
        $display("memory[200] = %d \nmemory[198] = %d", P.memory[200], P.memory[198]);
    end

    initial begin
        $dumpfile("P32.vcd");
        $dumpvars(0,tb1);
        $monitor("R2 = %d", P.regbank[2]);
        #3000 $finish;
    end
endmodule