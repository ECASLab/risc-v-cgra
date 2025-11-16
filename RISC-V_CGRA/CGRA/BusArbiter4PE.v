module bus_arbiter4 #(parameter NUM_PE = 4)(
    input        clk,
    input        reset,
    input  [NUM_PE-1:0] req,       // Request signals from the PEs
    input  [NUM_PE-1:0] working,  // Signal indicating access to bus is being used
    output reg [3:0] grant  // Grant signals to the PEs
);
    reg [1:0] current;      // Points to current priority slot
    reg [NUM_PE-1:0] grant_pending;
    reg release_wait;
    integer i;
    

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        grant      <= 4'b0000;
        grant_pending <= 4'b0000;
        current    <= 2'b00;
    end else begin

        // Default: no grant if no request
        grant <= 4'b0000;

        // Try to grant access based on rotating priority
        for (i = 0; i < NUM_PE; i = i + 1) begin
            if (req[i]) begin
                grant_pending[i] <= 1'b1;
            end
            if (working[i] == 1) begin
                grant_pending[i] <= 1'b0;
            end
        end

        // Apply pending grant after PE has time to assert working
        if (grant_pending != 0) begin
            grant      <= grant_pending;
            grant_pending <= 0;
        end

        // Rotate priority every cycle
        current <= current + 1;
        end
    end

endmodule
