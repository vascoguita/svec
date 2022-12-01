`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"
`include "svec_base_regs.svh"

import svec_base_regs_Consts::*;

module main;
   reg rst_n = 0;
   reg clk_125m_pllref = 0;

   initial begin
      repeat(20) @(posedge clk_125m_pllref);
      rst_n = 1;
   end

   // 125Mhz
   always #4ns clk_125m_pllref <= ~clk_125m_pllref;

   IVME64X VME(rst_n);

   `DECLARE_VME_BUFFERS(VME.slave);

   logic             ddr_reset_n;
   logic             ddr_ck_p;
   logic             ddr_ck_n;
   logic             ddr_cke;
   logic             ddr_ras_n;
   logic             ddr_cas_n;
   logic             ddr_we_n;
   wire  [1:0]       ddr_dm;
   logic [2:0]       ddr_ba;
   logic [13:0]      ddr_a;
   wire  [15:0]      ddr_dq;
   wire  [1:0]       ddr_dqs_p;
   wire  [1:0]       ddr_dqs_n;
   wire              ddr_rzq;
   logic             ddr_odt;

   logic [4:0]       slot_id = 5'h8;

   //---------------------------------------------------------------------------
   // The DUT
   //---------------------------------------------------------------------------

   svec_golden
     #(.g_VERBOSE(1'b1),
       .g_SIMULATION(1'b1))
      DUT (
         .rst_n_i(rst_n),

         .clk_125m_pllref_p_i      (clk_125m_pllref),
         .clk_125m_pllref_n_i      (~clk_125m_pllref),

         .vme_as_n_i               (VME_AS_n),
         .vme_sysreset_n_i         (VME_RST_n),
         .vme_write_n_i            (VME_WRITE_n),
         .vme_am_i                 (VME_AM),
         .vme_ds_n_i               (VME_DS_n),
         .vme_gap_i                (^slot_id),
         .vme_ga_i                 (~slot_id),
         .vme_berr_o               (VME_BERR),
         .vme_dtack_n_o            (VME_DTACK_n),
         .vme_retry_n_o            (VME_RETRY_n),
         .vme_retry_oe_o           (VME_RETRY_OE),
         .vme_lword_n_b            (VME_LWORD_n),
         .vme_addr_b               (VME_ADDR),
         .vme_data_b               (VME_DATA),
         .vme_irq_o                (VME_IRQ_n),
         .vme_iack_n_i             (VME_IACK_n),
         .vme_iackin_n_i           (VME_IACKIN_n),
         .vme_iackout_n_o          (VME_IACKOUT_n),
         .vme_dtack_oe_o           (VME_DTACK_OE),
         .vme_data_dir_o           (VME_DATA_DIR),
         .vme_data_oe_n_o          (VME_DATA_OE_N),
         .vme_addr_dir_o           (VME_ADDR_DIR),
         .vme_addr_oe_n_o          (VME_ADDR_OE_N),

         .fmc0_scl_b (),
         .fmc0_sda_b (),
         .fmc1_scl_b (),
         .fmc1_sda_b (),
         .fmc0_prsnt_m2c_n_i (),
         .fmc1_prsnt_m2c_n_i (),

         .onewire_b (),

         .carrier_scl_b (),
         .carrier_sda_b (),

         .spi_sclk_o (),
         .spi_ncs_o (),
         .spi_mosi_o (),
         .spi_miso_i (),

         .ddr4_a_o                  (ddr_a),
         .ddr4_ba_o                 (ddr_ba),
         .ddr4_cas_n_o              (ddr_cas_n),
         .ddr4_ck_p_o               (ddr_ck_p),
         .ddr4_ck_n_o               (ddr_ck_n),
         .ddr4_cke_o                (ddr_cke),
         .ddr4_dq_b                 (ddr_dq),
         .ddr4_ldm_o                (ddr_dm[0]),
         .ddr4_ldqs_n_b             (ddr_dqs_n[0]),
         .ddr4_ldqs_p_b             (ddr_dqs_p[0]),
         .ddr4_odt_o                (ddr_odt),
         .ddr4_ras_n_o              (ddr_ras_n),
         .ddr4_reset_n_o            (ddr_reset_n),
         .ddr4_rzq_b                (ddr_rzq),
         .ddr4_udm_o                (ddr_dm[1]),
         .ddr4_udqs_n_b             (ddr_dqs_n[1]),
         .ddr4_udqs_p_b             (ddr_dqs_p[1]),
         .ddr4_we_n_o               (ddr_we_n),

         .pcbrev_i (5'h2)
          );

   //---------------------------------------------------------------------------
   // DDR memory model
   //---------------------------------------------------------------------------

   ddr3 #
     (
      .DEBUG(0),
      .check_strict_timing(0),
      .check_strict_mrbits(0)
      )
   DDR_MEM
     (
      .rst_n   (ddr_reset_n),
      .ck      (ddr_ck_p),
      .ck_n    (ddr_ck_n),
      .cke     (ddr_cke),
      .cs_n    (1'b0),
      .ras_n   (ddr_ras_n),
      .cas_n   (ddr_cas_n),
      .we_n    (ddr_we_n),
      .dm_tdqs (ddr_dm),
      .ba      (ddr_ba),
      .addr    (ddr_a),
      .dq      (ddr_dq),
      .dqs     (ddr_dqs_p),
      .dqs_n   (ddr_dqs_n),
      .tdqs_n  (),
      .odt     (ddr_odt)
      );

   task automatic init_vme64x_core(ref CBusAccessor_VME64x acc);
      uint64_t rv;

      /* map func0 to 0x80000000, A32 */
      acc.write('h7ff63, 'h80, A32|CR_CSR|D08Byte3);
      acc.write('h7ff67, 0, CR_CSR|A32|D08Byte3);
      acc.write('h7ff6b, 0, CR_CSR|A32|D08Byte3);
      acc.write('h7ff6f, 36, CR_CSR|A32|D08Byte3);
      acc.write('h7ff33, 1, CR_CSR|A32|D08Byte3);
      acc.write('h7fffb, 'h10, CR_CSR|A32|D08Byte3); /* enable module (BIT_SET = 0x10) */

      acc.set_default_modifiers(A32 | D32 | SINGLE);
   endtask // init_vme64x_core

   initial begin
      uint64_t a, d;

      int i, result;

      automatic CBusAccessor_VME64x acc = new(VME.tb);

      #1us;
      init_vme64x_core(acc);

      //  Display meta data
      for (i = ADDR_SVEC_BASE_REGS_METADATA;
           i < ADDR_SVEC_BASE_REGS_METADATA + SVEC_BASE_REGS_METADATA_SIZE;
           i += 4)
      begin
         acc.read('h80000000 + i, d, A32|SINGLE|D32);
         $display("Read %x: %x", i, d);
      end

      acc.read('h80000000 + ADDR_SVEC_BASE_REGS_CSR_DDR_STATUS, d, A32|SINGLE|D32);
      $display("ddr status: %x", d);

      //  Write ddr4
      acc.write('h80000000 + ADDR_SVEC_BASE_REGS_CSR_DDR4_ADDR, 'h0, A32|SINGLE|D32);
      acc.write('h80000000 + ADDR_SVEC_BASE_REGS_DDR4_DATA, 'h11223344, A32|SINGLE|D32);
      acc.write('h80000000 + ADDR_SVEC_BASE_REGS_DDR4_DATA, 'h55667788, A32|SINGLE|D32);
      acc.write('h80000000 + ADDR_SVEC_BASE_REGS_DDR4_DATA, 'h99AABBCC, A32|SINGLE|D32);
      acc.write('h80000000 + ADDR_SVEC_BASE_REGS_DDR4_DATA, 'hDDEEFF00, A32|SINGLE|D32);

      //  Read DDR4
      acc.write('h80000000 + ADDR_SVEC_BASE_REGS_CSR_DDR4_ADDR, 'h0, A32|SINGLE|D32);
      for (i = 0; i < 4; i++)
        begin
           acc.read('h80000000 + ADDR_SVEC_BASE_REGS_CSR_DDR4_ADDR, a, A32|SINGLE|D32);
           acc.read('h80000000 + ADDR_SVEC_BASE_REGS_DDR4_DATA, d, A32|SINGLE|D32);
           $display("Read back data from %08x: %08x", a, d);
        end

      $finish;
   end

endmodule // main
