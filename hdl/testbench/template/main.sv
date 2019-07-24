`include "vme64x_bfm.svh"
`include "svec_vme_buffers.svh"
//`include "../regs/golden_regs.vh"

import wishbone_pkg::*;
   
module main;
   reg rst_n = 0;
   reg clk_125m_pllref = 0;
   var t_wishbone_master_data64_out ddr4_wb_out =
      '{cyc: 1'b0, stb: 1'b0, we: 1'b0, sel: 4'b0, adr: 32'b0, dat: 64'b0};

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

   svec_template_wr
     #(.g_with_vic (1'b1),
       .g_with_ddr4(1'b1),
       .g_SIMULATION(1'b0))
      DUT (
	      .rst_n_i(rst_n),

         .clk_125m_pllref_p_i      (clk_125m_pllref),
         .clk_125m_pllref_n_i      (~clk_125m_pllref),

         .clk_20m_vcxo_i (1'b0),
         .clk_125m_gtp_n_i (1'b0),
         .clk_125m_gtp_p_i (1'b1),

     
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

         .uart_rxd_i (),
         .uart_txd_o (),

         .plldac_sclk_o (),
         .plldac_din_o (),
         .pll25dac_cs_n_o (),
         .pll20dac_cs_n_o (),
         .pll20dac_din_o (),
         .pll20dac_sclk_o (),
         .pll20dac_sync_n_o (),
         .pll25dac_din_o (),
         .pll25dac_sclk_o (),
         .pll25dac_sync_n_o (),

         .sfp_txp_o (),
         .sfp_txn_o (),
         .sfp_rxp_i (),
         .sfp_rxn_i (),
         .sfp_mod_def0_i (),
         .sfp_mod_def1_b (),
         .sfp_mod_def2_b (),
         .sfp_rate_select_o (),
         .sfp_tx_fault_i (),
         .sfp_tx_disable_o (),
         .sfp_los_i (),

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

         .ddr5_a_o       (),
         .ddr5_ba_o      (),
         .ddr5_cas_n_o   (),
         .ddr5_ck_p_o    (),
         .ddr5_ck_n_o    (),
         .ddr5_cke_o     (),
         .ddr5_dq_b      (),
         .ddr5_ldm_o     (),
         .ddr5_ldqs_n_b  (),
         .ddr5_ldqs_p_b  (),
         .ddr5_odt_o     (),
         .ddr5_ras_n_o   (),
         .ddr5_reset_n_o (),
         .ddr5_rzq_b     (),
         .ddr5_udm_o     (),
         .ddr5_udqs_n_b  (),
         .ddr5_udqs_p_b  (),
         .ddr5_we_n_o    (),

         .pcbrev_i (5'h2),
         .ddr4_clk_i (1'b0),
         .ddr4_rst_n_i (1'b0),
         .ddr4_wb_i (ddr4_wb_out),
         .ddr4_wb_o (),
         .ddr5_clk_i (),
         .ddr5_rst_n_i (),
         .ddr5_wb_i (),
         .ddr5_wb_o (),
         .ddr4_wr_fifo_empty_o(),
         .ddr5_wr_fifo_empty_o(),

         .clk_sys_62m5_o (),
         .rst_sys_62m5_n_o (),
         .clk_ref_125m_o (),
         .rst_ref_125m_n_o (),

         .irq_user_i (),

         .wrf_src_o (),
         .wrf_src_i (),
         .wrf_snk_o (),
         .wrf_snk_i (),

         .wrs_tx_data_i (),
         .wrs_tx_valid_i (),
         .wrs_tx_dreq_o (),
         .wrs_tx_last_i (),
         .wrs_tx_flush_i (),
         .wrs_tx_cfg_i (),
         .wrs_rx_first_o (),
         .wrs_rx_last_o (),
         .wrs_rx_data_o (),
         .wrs_rx_valid_o (),
         .wrs_rx_dreq_i (),
         .wrs_rx_cfg_i (),

         .wb_eth_master_o (),
         .wb_eth_master_i (),

         .tm_link_up_o (),
         .tm_time_valid_o (),
         .tm_tai_o (),
         .tm_cycles_o (),

         .pps_p_o (),
         .pps_led_o (),

         .link_ok_o (),
         .led_link_o (),
         .led_act_o (),

         .app_wb_o (),
         .app_wb_i ()
  	  );

   ddr3
     cmp_ddr4 (
      .rst_n   (ddr_reset_n),
      .ck      (ddr_ck_p),
      .ck_n    (ddr_ck_n),
      .cke     (ddr_cke),
      .cs_n    (1'b0),
      .ras_n   (ddr_ras_n),
      .cas_n   (ddr_cas_n),
      .we_n    (ddr_we_n),
      .dm_tdqs ({ddr_dm[1], ddr_dm[0]}),
      .ba      (ddr_ba),
      .addr    (ddr_a),
      .dq      (ddr_dq),
      .dqs     ({ddr_dqs_p[1],ddr_dqs_p[0]}),
      .dqs_n   ({ddr_dqs_n[1],ddr_dqs_n[0]}),
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
      uint64_t d;
      
      int i, result;
      
      automatic CBusAccessor_VME64x acc = new(VME.tb);

      #1us;
      init_vme64x_core(acc);


//      acc.read('h80000000, d, A32|SINGLE|D32);
  //    $display("Read0: %x\n", d);
      for (i = 0; i < 8'h20; i += 4)
      begin
         acc.read('h80000000 | i, d, A32|SINGLE|D32);
         $display("Read %x: %x", i, d);
      end

      //  Read DDR3
      acc.read('h80000000 | 8'h5c, d, A32|SINGLE|D32);
      $display("Read data %x: %x", i, d);
      acc.read('h80000000 | 8'h58, d, A32|SINGLE|D32);
      $display("Read addr %x: %x", i, d);

/*
       acc.write('h80010000, d, A24|SINGLE|D32);
      acc.read('h80010000, d, A24|SINGLE|D32);

      acc.write('h80010000 + `ADDR_GLD_I2CR0, ~`GLD_I2CR0_SCL_OUT, A24|SINGLE|D32);
      acc.write('h80010000 + `ADDR_GLD_I2CR0, ~`GLD_I2CR0_SDA_OUT, A24|SINGLE|D32);

      acc.write('h810000 + `ADDR_GLD_I2CR1, ~`GLD_I2CR0_SCL_OUT, A24|SINGLE|D32);
      acc.write('h810000 + `ADDR_GLD_I2CR1, ~`GLD_I2CR0_SDA_OUT, A24|SINGLE|D32);
      
      $display("Read1: %x\n", d);
  */    
   end

  
endmodule // main



