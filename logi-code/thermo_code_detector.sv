module thermo_code_detector (
    input logic [7:0] codeIn,
    output logic isThermometer
);
    logic [6:0] check;

    assign check = codeIn[7:1] ^ codeIn[6:0];
    assign isThermometer = |check && &~(check & (check - 1'b1));
endmodule