//============================================================================
//  Salamander for MiSTer FPGA - RetroAchievements RAM tap
//
//  Turns the main 68000's work RAM writes into the write port of
//  salamander_ra_mirror, laid out as FinalBurn Neo's "All Ram" block so the
//  ARM region table is the identity.
//
//  RA arcade sets were written against FinalBurn Neo. Its Nemesis-hardware
//  driver (src/burn/drv/konami/d_nemesis.cpp, MemIndex from AllRam) starts
//  the block with
//      0x00000 Drv68KRAM0  0x20000  (Salamander maps 0x8000 of it at
//                                    68K 0x080000-0x087FFF)
//  followed by other RAMs the sets do not read. The shadow is that 32 kB
//  work RAM (AW=15): shadow byte k = RA address k.
//
//  Byte order: FBNeo keeps 68K RAM as native 16-bit words, so RA byte k is
//  68K byte k^1. Each 68K word goes as-is into a little-endian lane of the
//  mirror (wr_din = D15..D0, wr_be = {UDS, LDS}), which is that layout.
//
//  The write strobe is a level (a 68K write holds /UDS//LDS for several
//  MCLK clocks, while the RAM samples every clock). It is reported once, on
//  the clock after it falls, with the address/data/byte enables of its last
//  clock - the value the RAM kept.
//
//  SPDX-License-Identifier: GPL-2.0-or-later (same terms as the rest of the core)
//============================================================================

module salamander_ra_tap (
    input             clk,

    input             wr,       // work RAM write strobe (level)
    input      [14:1] addr,     // word address in the 32 kB RAM
    input      [15:0] din,
    input      [ 1:0] be,       // {UDS, LDS} active high

    // salamander_ra_mirror write port
    output reg [14:0] ra_wr_word,
    output reg [15:0] ra_wr_din,
    output reg [ 1:0] ra_wr_be
);

reg        wr_l;
reg [14:1] addr_l;
reg [15:0] din_l;
reg  [1:0] be_l;

always_ff @(posedge clk) begin
    wr_l <= wr;
    if( wr ) begin addr_l <= addr; din_l <= din; be_l <= be; end
    ra_wr_be <= 2'b00;
    if( wr_l && !wr ) begin
        ra_wr_word <= { 1'b0, addr_l };
        ra_wr_din  <= din_l;
        ra_wr_be   <= be_l;
    end
end

endmodule
