module bus_arbiter #(parameter NUM_PE = 4)(
    input        clk,
    input        reset,
    input  [3:0] req,       // Request signals from the PEs
    output reg [3:0] grant  // Grant signals to the PEs
);
    reg [1:0] current;      // Points to current priority slot

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            grant   <= 4'b0000;
            current <= 2'b00;
        end else begin
            // Default: no grant if no request
            grant <= 4'b0000;

            // Rotating priority arbitration
            case (current)
                2'b00: if (req[0]) grant <= 4'b0001;
                       else if (req[1]) grant <= 4'b0010;
                       else if (req[2]) grant <= 4'b0100;
                       else if (req[3]) grant <= 4'b1000;
                2'b01: if (req[1]) grant <= 4'b0010;
                       else if (req[2]) grant <= 4'b0100;
                       else if (req[3]) grant <= 4'b1000;
                       else if (req[0]) grant <= 4'b0001;
                2'b10: if (req[2]) grant <= 4'b0100;
                       else if (req[3]) grant <= 4'b1000;
                       else if (req[0]) grant <= 4'b0001;
                       else if (req[1]) grant <= 4'b0010;
                2'b11: if (req[3]) grant <= 4'b1000;
                       else if (req[0]) grant <= 4'b0001;
                       else if (req[1]) grant <= 4'b0010;
                       else if (req[2]) grant <= 4'b0100;
            endcase

            // Always rotate current to avoid lock
            current <= current + 1;
        end
    end
endmodule
