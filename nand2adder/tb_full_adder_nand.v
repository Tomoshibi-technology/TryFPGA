
module tb_full_adder_nand;

    reg A, B, Cin;
    wire S, Cout;

    full_adder_nand adder (
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S),
        .Cout(Cout)
    );

    initial begin
        // $dumpfile("tb_full_adder_nand.vcd");
        $dumpvars(0, tb_full_adder_nand);
    end

    initial begin
        A = 0; B = 0; Cin = 0; #1;
        A = 0; B = 0; Cin = 1; #1;
        A = 0; B = 1; Cin = 0; #1;
        A = 0; B = 1; Cin = 1; #1;
        A = 1; B = 0; Cin = 0; #1;
        A = 1; B = 0; Cin = 1; #1;
        A = 1; B = 1; Cin = 0; #1;
        A = 1; B = 1; Cin = 1; #1;

        $finish;
    end
    
    initial begin
        $monitor("A=%b B=%b Cin=%b -> Cout=%b, S=%b",
                A, B, Cin, Cout, S);
    end

endmodule
