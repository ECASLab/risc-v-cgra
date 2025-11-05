module cluster_mem_arbiter #(parameter NUM_CLUSTERS = 4)(
    input        clk,
    input        reset,
    input  [NUM_CLUSTERS-1:0] req,       // Request signals from the Clusters
    input  [NUM_CLUSTERS-1:0] working,  // Signal indicating access to bus is being used
    output reg [NUM_CLUSTERS-1:0] grant  // Grant signals to the Clusters
);
    reg [1:0] current;      // Points to current priority slot
    reg [1:0] bus_owner;
    reg       bus_locked;
    reg [NUM_CLUSTERS-1:0] grant_pending;
    reg release_wait;
    

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        grant      <= 4'b0000;
        grant_pending <= 4'b0000;
        current    <= 2'b00;
        bus_owner  <= 2'b00;
        bus_locked <= 1'b0;
        release_wait <= 1'b0;
    end else begin
        if (req != 0) $display("GlobalArbiter: Request status is: %b", req);
        //$display("Current use of bus is %b for current %b", working, current);
        //$display("Value of grant pending: %b and bus locked %b and bus owner %b", grant_pending, bus_locked, bus_owner);

        // Default: no grant if no request
        grant <= 4'b0000;

        if (!bus_locked) begin
            // Try to grant access based on rotating priority
            case (current)
                2'b00: if (req[0]) begin grant_pending <= 4'b0001; end
                       else if (req[1]) begin grant_pending <= 4'b0010; end
                       else if (req[2]) begin grant_pending <= 4'b0100; end
                       else if (req[3]) begin grant_pending <= 4'b1000; end
                2'b01: if (req[1]) begin grant_pending <= 4'b0010; end
                       else if (req[2]) begin grant_pending <= 4'b0100; end
                       else if (req[3]) begin grant_pending <= 4'b1000; end
                       else if (req[0]) begin grant_pending <= 4'b0001; end
                2'b10: if (req[2]) begin grant_pending <= 4'b0100; end
                       else if (req[3]) begin grant_pending <= 4'b1000; end
                       else if (req[0]) begin grant_pending <= 4'b0001; end
                       else if (req[1]) begin grant_pending <= 4'b0010; end
                2'b11: if (req[3]) begin grant_pending <= 4'b1000; end
                       else if (req[0]) begin grant_pending <= 4'b0001; end
                       else if (req[1]) begin grant_pending <= 4'b0010; end
                       else if (req[2]) begin grant_pending <= 4'b0100; end
            endcase
        end else begin
            // Wait for Cluster to release the bus
            if (working[bus_owner] === 1'b0) begin
                if (release_wait) begin
                    bus_locked <= 0;
                    release_wait <= 0;
                    grant      <= 4'b0000;
                end else begin
                    release_wait <= 1;
                end
            end else begin
                release_wait <= 0; // Cluster is still working
            end
        end

        // Apply pending grant after Cluster has time to assert working
        if (grant_pending != 0 && !bus_locked) begin
            grant      <= grant_pending;
            bus_owner  <= (grant_pending[3] ? 3 :
                          grant_pending[2] ? 2 :
                          grant_pending[1] ? 1 : 0);
            bus_locked <= 1;
            grant_pending <= 0;
        end

        // Rotate priority every cycle
        current <= current + 1;
    end
end

endmodule

