module full_adder_nand (
    input  A,
    input  B,
    input  Cin,
    output S,
    output Cout
);

    wire w1, w2, w3, w4, w5, w6, w7;

    //harf adder
    nand g1 (w1, A, B);
    nand g2 (w2, A, w1);
    nand g3 (w3, B, w1);
    nand g4 (w4, w2, w3);

    //harf adder
    nand g5 (w5, w4, Cin);
    nand g6 (w6, w4, w5);
    nand g7 (w7, Cin, w5);
    nand g8 (S, w6, w7);

    //carry
    nand g9 (Cout, w1, w5);

endmodule
