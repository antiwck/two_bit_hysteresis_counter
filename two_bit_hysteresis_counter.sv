module two_bit_hysteresis_counter # (
    parameter       HYSTERESIS_WIDTH                = 2                             ,
    parameter       HYSTERESIS_ADDR_WIDTH           = 8                             ,
    parameter       HYSTERESIS_DEPTH                = 1 << HYSTERESIS_ADDR_WIDTH
) (
    input   logic                                   clk                             ,
    input   logic                                   rst_n                           ,
    input   logic                                   predict_update                  ,   // Indicate an update to the PHT
    input   logic                                   actual_taken                    ,   // 1 for taken, 0 for not taken, actual
    input   logic [HYSTERESIS_ADDR_WIDTH-1:0]       hysteresis_addr                 ,   // Addr of the PHY entry
    input   logic                                   predict_acquire                 ,   // Indicate to take hysteresis from PHT
    output  logic                                   predict_taken                       // 1 for taken, 0 for not taken, prediction
);

    (* ram_style = "block" *) logic   [HYSTERESIS_DEPTH-1:0][HYSTERESIS_WIDTH-1:0]    pattern_history_table         ;

    // 00 [Strong Taken], 01 [Weak Taken], 10 [Weak Not take], 11 [Strong Not Taken]

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_history_table                           <= '{default: '0}       ;
            predict_taken                                   <= '0                   ;
        end else begin

            // Update to PHT
            if (predict_update) begin

                // Update the PHT entry to TAKEN
                if (actual_taken) begin
                    // Only update if not at the extreme end
                    if (pattern_history_table[hysteresis_addr] != 2'b00) begin
                        pattern_history_table[hysteresis_addr]   <= pattern_history_table[hysteresis_addr] - 1    ;
                    end
                end
                // Update the PHT entry to NOT TAKEN
                else begin
                    // Only update if not at the extreme end
                    if (pattern_history_table[hysteresis_addr] == 2'b11) begin
                        pattern_history_table[hysteresis_addr]   <= pattern_history_table[hysteresis_addr] + 1    ;
                    end
                end
            end

            // Predict from PHT
            if (predict_acquire) begin
                predict_taken                                   <= ~pattern_history_table[hysteresis_addr][1]    ;
            end

        end
    end

endmodule
