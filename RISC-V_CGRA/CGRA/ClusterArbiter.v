module cluster_mem_arbiter #(parameter NUM_CLUSTERS = 4)(
    input        clk,
    input        reset,
    input  [NUM_CLUSTERS-1:0] req_read,       // Read Request signals from the Clusters
    input  [NUM_CLUSTERS-1:0] req_write,       // Write Request signals from the Clusters
    input  [NUM_CLUSTERS-1:0] working,  // Signal indicating access to bus is being used
    output reg [NUM_CLUSTERS-1:0] grant_read,  // Grant signals to the Clusters to read
    output reg [NUM_CLUSTERS-1:0] grant_write  // Grant signals to the Clusters to write
);
    reg [1:0] current;      // Points to current priority slot
    reg [1:0] bus_owner;
    reg       bus_locked;
    reg [NUM_CLUSTERS-1:0] grant_pending_read;
    reg [NUM_CLUSTERS-1:0] grant_pending_write;
    reg release_wait;
    reg last_granted_type; // 0 = read, 1 = write
    

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        grant_read      <= 4'b0000;
        grant_write      <= 4'b0000;
        grant_pending_read <= 4'b0000;
        grant_pending_write <= 4'b0000;
        current    <= 2'b00;
        bus_owner  <= 2'b00;
        bus_locked <= 1'b0;
        release_wait <= 1'b0;
        last_granted_type <= 1'b0;
    end else begin
        // Default: no grant if no request
        grant_read <= 4'b0000;
        grant_write <= 4'b0000;

        if (!bus_locked) begin
            // Try to grant access based on rotating priority
            case (current)
                2'b00: 
                begin
                    if (req_read[0]) begin grant_pending_read <= 4'b0001; end
                    else if (req_read[1]) begin grant_pending_read <= 4'b0010; end
                    else if (req_read[2]) begin grant_pending_read <= 4'b0100; end
                    else if (req_read[3]) begin grant_pending_read <= 4'b1000; end
                    if (req_write[0]) begin grant_pending_write <= 4'b0001; end
                    else if (req_write[1]) begin grant_pending_write <= 4'b0010; end
                    else if (req_write[2]) begin grant_pending_write <= 4'b0100; end
                    else if (req_write[3]) begin grant_pending_write <= 4'b1000; end
                end
                2'b01: 
                begin
                    if (req_read[1]) begin grant_pending_read <= 4'b0010; end
                    else if (req_read[2]) begin grant_pending_read <= 4'b0100; end
                    else if (req_read[3]) begin grant_pending_read <= 4'b1000; end
                    else if (req_read[0]) begin grant_pending_read <= 4'b0001; end
                    if (req_write[1]) begin grant_pending_write <= 4'b0010; end
                    else if (req_write[2]) begin grant_pending_write <= 4'b0100; end
                    else if (req_write[3]) begin grant_pending_write <= 4'b1000; end
                    else if (req_write[0]) begin grant_pending_write <= 4'b0001; end
                end
                2'b10:
                begin
                    if (req_read[2]) begin grant_pending_read <= 4'b0100; end
                    else if (req_read[3]) begin grant_pending_read <= 4'b1000; end
                    else if (req_read[0]) begin grant_pending_read <= 4'b0001; end
                    else if (req_read[1]) begin grant_pending_read <= 4'b0010; end
                    if (req_write[2]) begin grant_pending_write <= 4'b0100; end
                    else if (req_write[3]) begin grant_pending_write <= 4'b1000; end
                    else if (req_write[0]) begin grant_pending_write <= 4'b0001; end
                    else if (req_write[1]) begin grant_pending_write <= 4'b0010; end
                end
                2'b11: 
                begin
                    if (req_read[3]) begin grant_pending_read <= 4'b1000; end
                    else if (req_read[0]) begin grant_pending_read <= 4'b0001; end
                    else if (req_read[1]) begin grant_pending_read <= 4'b0010; end
                    else if (req_read[2]) begin grant_pending_read <= 4'b0100; end
                    if (req_write[3]) begin grant_pending_write <= 4'b1000; end
                    else if (req_write[0]) begin grant_pending_write <= 4'b0001; end
                    else if (req_write[1]) begin grant_pending_write <= 4'b0010; end
                    else if (req_write[2]) begin grant_pending_write <= 4'b0100; end
                end
            endcase
        end else begin
            // Wait for Cluster to release the bus
            if (working[bus_owner] === 1'b0) begin
                if (release_wait) begin
                    bus_locked <= 0;
                    release_wait <= 0;
                    grant_read      <= 4'b0000;
                    grant_write      <= 4'b0000;
                end else begin
                    release_wait <= 1;
                end
            end else begin
                release_wait <= 0; // Cluster is still working
            end
        end

        // Apply pending grant after Cluster has time to assert working
        if ((grant_pending_read != 0 || grant_pending_write != 0) && !bus_locked) begin
           
            if (last_granted_type == 0 && grant_pending_write != 0) begin
                grant_write <= grant_pending_write;
                bus_owner <= (grant_pending_write[3] ? 3 :
                        grant_pending_write[2] ? 2 :
                        grant_pending_write[1] ? 1 : 0);
                last_granted_type <= 1;
            end else if (last_granted_type == 1 && grant_pending_read != 0) begin
                grant_read <= grant_pending_read;
                bus_owner <= (grant_pending_read[3] ? 3 :
                        grant_pending_read[2] ? 2 :
                        grant_pending_read[1] ? 1 : 0);
                last_granted_type <= 0;
            end else if (grant_pending_read != 0) begin
                grant_read <= grant_pending_read;
                bus_owner <= (grant_pending_read[3] ? 3 :
                        grant_pending_read[2] ? 2 :
                        grant_pending_read[1] ? 1 : 0);
                last_granted_type <= 0;
            end else if (grant_pending_write != 0) begin
                grant_write <= grant_pending_write;
                bus_owner <= (grant_pending_write[3] ? 3 :
                        grant_pending_write[2] ? 2 :
                        grant_pending_write[1] ? 1 : 0);
                last_granted_type <= 1;
            end

            bus_locked <= 1;
            grant_pending_read <= 0;
            grant_pending_write <= 0;
        end

        // Rotate priority every cycle
        current <= current + 1;
    end
end

endmodule

