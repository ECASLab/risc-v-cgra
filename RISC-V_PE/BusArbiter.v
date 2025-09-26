module bus_arbiter #(parameter NUM_PE = 4)(
    input        clk,
    input        reset,
    input  [NUM_PE-1:0] req,       // Request signals from the PEs
    input  [NUM_PE-1:0] working,  // Signal indicating access to bus is being used
    output reg [3:0] grant  // Grant signals to the PEs
);
    reg [1:0] current;      // Points to current priority slot
    reg [1:0] bus_owner;
    reg       bus_locked;
    

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        grant      <= 4'b0000;
        current    <= 2'b00;
        bus_owner  <= 2'b00;
        bus_locked <= 1'b0;
    end else begin
        $display("Value of bus locked is: %b and bus owner is %b", bus_locked, bus_owner);
        $display("Request status is: %b", req);
        $display("Current use of bus is %b for current %b", working, current);

        // Default: no grant if no request
        grant <= 4'b0000;

        if (!bus_locked) begin
            // Try to grant access based on rotating priority
            case (current)
                2'b00: if (req[0]) begin grant <= 4'b0001; bus_owner <= 2'd0; bus_locked <= 1; end
                       else if (req[1]) begin grant <= 4'b0010; bus_owner <= 2'd1; bus_locked <= 1; end
                       else if (req[2]) begin grant <= 4'b0100; bus_owner <= 2'd2; bus_locked <= 1; end
                       else if (req[3]) begin grant <= 4'b1000; bus_owner <= 2'd3; bus_locked <= 1; end
                2'b01: if (req[1]) begin grant <= 4'b0010; bus_owner <= 2'd1; bus_locked <= 1; end
                       else if (req[2]) begin grant <= 4'b0100; bus_owner <= 2'd2; bus_locked <= 1; end
                       else if (req[3]) begin grant <= 4'b1000; bus_owner <= 2'd3; bus_locked <= 1; end
                       else if (req[0]) begin grant <= 4'b0001; bus_owner <= 2'd0; bus_locked <= 1; end
                2'b10: if (req[2]) begin grant <= 4'b0100; bus_owner <= 2'd2; bus_locked <= 1; end
                       else if (req[3]) begin grant <= 4'b1000; bus_owner <= 2'd3; bus_locked <= 1; end
                       else if (req[0]) begin grant <= 4'b0001; bus_owner <= 2'd0; bus_locked <= 1; end
                       else if (req[1]) begin grant <= 4'b0010; bus_owner <= 2'd1; bus_locked <= 1; end
                2'b11: if (req[3]) begin grant <= 4'b1000; bus_owner <= 2'd3; bus_locked <= 1; end
                       else if (req[0]) begin grant <= 4'b0001; bus_owner <= 2'd0; bus_locked <= 1; end
                       else if (req[1]) begin grant <= 4'b0010; bus_owner <= 2'd1; bus_locked <= 1; end
                       else if (req[2]) begin grant <= 4'b0100; bus_owner <= 2'd2; bus_locked <= 1; end
            endcase
        end else begin
            // Wait for PE to release the bus
            if (working[bus_owner] === 1'b0) begin
                bus_locked <= 0;
                grant      <= 4'b0000;
            end
        end

        // Rotate priority every cycle
        current <= current + 1;
    end
end

endmodule
