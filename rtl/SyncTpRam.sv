// Copyright 2014 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/**
 * Inferable, Synchronous Two-Port RAM
 *
 * This RAM has a dedicated read and a dedicated write port.  When reading and writing from and to
 * the same address in a single clock cycle, the read port returns the data before the write.
 *
 * This module is designed to work with both Xilinx and Altera tools by following the respective
 * guidelines:
 * - Xilinx UG901 Vivado Design Suite User Guide: Synthesis (p. 106)
 * - Altera Quartus II Handbook Volume 1: Design and Synthesis (p. 768)
 *
 * Current Maintainers:
 * - Michael Schaffner  <schaffer@iis.ee.ethz.ch>
 */

module SyncTpRam
#(
  parameter ADDR_WIDTH = 10,
  parameter DATA_DEPTH = 1024, // usually 2**ADDR_WIDTH, but can be lower
  parameter DATA_WIDTH = 32,
  parameter OUT_REGS   = 0
) (
  input  logic                    Clk_CI,
  input  logic                    Rst_RBI,
  input  logic                    WrEn_SI,
  input  logic [ADDR_WIDTH-1:0]   WrAddr_DI,
  input  logic [DATA_WIDTH-1:0]   WrData_DI,
  input  logic                    RdEn_SI,
  input  logic [ADDR_WIDTH-1:0]   RdAddr_DI,
  output logic [DATA_WIDTH-1:0]   RdData_DO
);

  ////////////////////////////
  // signals, localparams
  ////////////////////////////

  logic [DATA_WIDTH-1:0] RdData_DN;
  logic [DATA_WIDTH-1:0] RdData_DP;
  logic [DATA_WIDTH-1:0] Mem_DP [DATA_DEPTH-1:0];

  ////////////////////////////
  // XILINX/ALTERA implementation
  ////////////////////////////

  always_ff @(posedge Clk_CI)
  begin
    if (RdEn_SI) begin
      RdData_DN <= Mem_DP[RdAddr_DI];
    end
    if (WrEn_SI) begin
      Mem_DP[WrAddr_DI] <= WrData_DI;
    end
  end

  ////////////////////////////
  // optional output regs
  ////////////////////////////

  // output regs
  generate
    if (OUT_REGS>0) begin : g_outreg
      always_ff @(posedge Clk_CI or negedge Rst_RBI) begin
        if(Rst_RBI == 1'b0)
        begin
          RdData_DP  <= 0;
        end
        else
        begin
          RdData_DP  <= RdData_DN;
        end
      end
    end
  endgenerate // g_outreg

  // output reg bypass
  generate
    if (OUT_REGS==0) begin : g_oureg_byp
      assign RdData_DP  = RdData_DN;
    end
  endgenerate// g_oureg_byp

  assign RdData_DO = RdData_DP;

  ////////////////////////////
  // assertions
  ////////////////////////////

  // pragma translate_off
  assert property
    (@(posedge Clk_CI) (longint'(2)**longint'(ADDR_WIDTH) >= longint'(DATA_DEPTH)))
     else $error("depth out of bounds");
  // pragma translate_on

endmodule // SyncTpRam
