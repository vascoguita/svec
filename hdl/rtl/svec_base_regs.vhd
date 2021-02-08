-- Do not edit.  Generated on Fri Jan 29 13:36:51 2021 by tgingold
-- With Cheby 1.4.dev0 and these options:
--  --gen-hdl=svec_base_regs.vhd -i svec_base_regs.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity svec_base_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(13 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- SRAM bus metadata
    metadata_addr_o      : out   std_logic_vector(5 downto 2);
    metadata_data_i      : in    std_logic_vector(31 downto 0);
    metadata_data_o      : out   std_logic_vector(31 downto 0);
    metadata_wr_o        : out   std_logic;

    -- offset to the application metadata
    csr_app_offset_i     : in    std_logic_vector(31 downto 0);

    -- global and application resets
    csr_resets_global_o  : out   std_logic;
    csr_resets_appl_o    : out   std_logic;

    -- presence lines for the fmcs
    csr_fmc_presence_i   : in    std_logic_vector(31 downto 0);

    -- status of the ddr controllers
    -- Set when ddr4 calibration is done.
    csr_ddr_status_ddr4_calib_done_i : in    std_logic;
    -- Set when ddr5 calibration is done.
    csr_ddr_status_ddr5_calib_done_i : in    std_logic;

    -- pcb revision
    csr_pcb_rev_rev_i    : in    std_logic_vector(4 downto 0);

    -- address of data to read or to write
    csr_ddr4_addr_i      : in    std_logic_vector(31 downto 0);
    csr_ddr4_addr_o      : out   std_logic_vector(31 downto 0);
    csr_ddr4_addr_wr_o   : out   std_logic;

    -- address of data to read or to write
    csr_ddr5_addr_i      : in    std_logic_vector(31 downto 0);
    csr_ddr5_addr_o      : out   std_logic_vector(31 downto 0);
    csr_ddr5_addr_wr_o   : out   std_logic;

    -- Thermometer and unique id
    therm_id_i           : in    t_wishbone_master_in;
    therm_id_o           : out   t_wishbone_master_out;

    -- i2c controllers to the fmcs
    fmc_i2c_i            : in    t_wishbone_master_in;
    fmc_i2c_o            : out   t_wishbone_master_out;

    -- spi controller to the flash
    flash_spi_i          : in    t_wishbone_master_in;
    flash_spi_o          : out   t_wishbone_master_out;

    -- vector interrupt controller
    vic_i                : in    t_wishbone_master_in;
    vic_o                : out   t_wishbone_master_out;

    -- SRAM bus buildinfo
    buildinfo_addr_o     : out   std_logic_vector(7 downto 2);
    buildinfo_data_i     : in    std_logic_vector(31 downto 0);
    buildinfo_data_o     : out   std_logic_vector(31 downto 0);
    buildinfo_wr_o       : out   std_logic;

    -- In particular, the vuart is at 0x1500
    wrc_regs_i           : in    t_wishbone_master_in;
    wrc_regs_o           : out   t_wishbone_master_out;

    -- DMA page for ddr4
    ddr4_data_i          : in    t_wishbone_master_in;
    ddr4_data_o          : out   t_wishbone_master_out;

    -- DMA page for ddr5
    ddr5_data_i          : in    t_wishbone_master_in;
    ddr5_data_o          : out   t_wishbone_master_out
  );
end svec_base_regs;

architecture syn of svec_base_regs is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal metadata_rack                  : std_logic;
  signal metadata_re                    : std_logic;
  signal csr_resets_global_reg          : std_logic;
  signal csr_resets_appl_reg            : std_logic;
  signal csr_resets_wreq                : std_logic;
  signal csr_resets_wack                : std_logic;
  signal csr_ddr4_addr_wreq             : std_logic;
  signal csr_ddr5_addr_wreq             : std_logic;
  signal therm_id_re                    : std_logic;
  signal therm_id_we                    : std_logic;
  signal therm_id_wt                    : std_logic;
  signal therm_id_rt                    : std_logic;
  signal therm_id_tr                    : std_logic;
  signal therm_id_wack                  : std_logic;
  signal therm_id_rack                  : std_logic;
  signal fmc_i2c_re                     : std_logic;
  signal fmc_i2c_we                     : std_logic;
  signal fmc_i2c_wt                     : std_logic;
  signal fmc_i2c_rt                     : std_logic;
  signal fmc_i2c_tr                     : std_logic;
  signal fmc_i2c_wack                   : std_logic;
  signal fmc_i2c_rack                   : std_logic;
  signal flash_spi_re                   : std_logic;
  signal flash_spi_we                   : std_logic;
  signal flash_spi_wt                   : std_logic;
  signal flash_spi_rt                   : std_logic;
  signal flash_spi_tr                   : std_logic;
  signal flash_spi_wack                 : std_logic;
  signal flash_spi_rack                 : std_logic;
  signal vic_re                         : std_logic;
  signal vic_we                         : std_logic;
  signal vic_wt                         : std_logic;
  signal vic_rt                         : std_logic;
  signal vic_tr                         : std_logic;
  signal vic_wack                       : std_logic;
  signal vic_rack                       : std_logic;
  signal buildinfo_rack                 : std_logic;
  signal buildinfo_re                   : std_logic;
  signal wrc_regs_re                    : std_logic;
  signal wrc_regs_we                    : std_logic;
  signal wrc_regs_wt                    : std_logic;
  signal wrc_regs_rt                    : std_logic;
  signal wrc_regs_tr                    : std_logic;
  signal wrc_regs_wack                  : std_logic;
  signal wrc_regs_rack                  : std_logic;
  signal ddr4_data_re                   : std_logic;
  signal ddr4_data_we                   : std_logic;
  signal ddr4_data_wt                   : std_logic;
  signal ddr4_data_rt                   : std_logic;
  signal ddr4_data_tr                   : std_logic;
  signal ddr4_data_wack                 : std_logic;
  signal ddr4_data_rack                 : std_logic;
  signal ddr5_data_re                   : std_logic;
  signal ddr5_data_we                   : std_logic;
  signal ddr5_data_wt                   : std_logic;
  signal ddr5_data_rt                   : std_logic;
  signal ddr5_data_tr                   : std_logic;
  signal ddr5_data_wack                 : std_logic;
  signal ddr5_data_rack                 : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(13 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal metadata_wp                    : std_logic;
  signal metadata_we                    : std_logic;
  signal buildinfo_wp                   : std_logic;
  signal buildinfo_we                   : std_logic;
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wb_sel_i;
      end if;
    end if;
  end process;

  -- Interface metadata
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        metadata_rack <= '0';
      else
        metadata_rack <= metadata_re and not metadata_rack;
      end if;
    end if;
  end process;
  metadata_data_o <= wr_dat_d0;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        metadata_wp <= '0';
      else
        metadata_wp <= (wr_req_d0 or metadata_wp) and rd_req_int;
      end if;
    end if;
  end process;
  metadata_we <= (wr_req_d0 or metadata_wp) and not rd_req_int;
  process (wb_adr_i, wr_adr_d0, metadata_re) begin
    if metadata_re = '1' then
      metadata_addr_o <= wb_adr_i(5 downto 2);
    else
      metadata_addr_o <= wr_adr_d0(5 downto 2);
    end if;
  end process;

  -- Register csr_app_offset

  -- Register csr_resets
  csr_resets_global_o <= csr_resets_global_reg;
  csr_resets_appl_o <= csr_resets_appl_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        csr_resets_global_reg <= '0';
        csr_resets_appl_reg <= '0';
        csr_resets_wack <= '0';
      else
        if csr_resets_wreq = '1' then
          csr_resets_global_reg <= wr_dat_d0(0);
          csr_resets_appl_reg <= wr_dat_d0(1);
        end if;
        csr_resets_wack <= csr_resets_wreq;
      end if;
    end if;
  end process;

  -- Register csr_fmc_presence

  -- Register csr_unused0

  -- Register csr_ddr_status

  -- Register csr_pcb_rev

  -- Register csr_ddr4_addr
  csr_ddr4_addr_o <= wr_dat_d0;
  csr_ddr4_addr_wr_o <= csr_ddr4_addr_wreq;

  -- Register csr_ddr5_addr
  csr_ddr5_addr_o <= wr_dat_d0;
  csr_ddr5_addr_wr_o <= csr_ddr5_addr_wreq;

  -- Interface therm_id
  therm_id_tr <= therm_id_wt or therm_id_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        therm_id_rt <= '0';
        therm_id_wt <= '0';
      else
        therm_id_rt <= (therm_id_rt or therm_id_re) and not therm_id_rack;
        therm_id_wt <= (therm_id_wt or therm_id_we) and not therm_id_wack;
      end if;
    end if;
  end process;
  therm_id_o.cyc <= therm_id_tr;
  therm_id_o.stb <= therm_id_tr;
  therm_id_wack <= therm_id_i.ack and therm_id_wt;
  therm_id_rack <= therm_id_i.ack and therm_id_rt;
  therm_id_o.adr <= ((27 downto 0 => '0') & wb_adr_i(3 downto 2)) & (1 downto 0 => '0');
  therm_id_o.sel <= wr_sel_d0;
  therm_id_o.we <= therm_id_wt;
  therm_id_o.dat <= wr_dat_d0;

  -- Interface fmc_i2c
  fmc_i2c_tr <= fmc_i2c_wt or fmc_i2c_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fmc_i2c_rt <= '0';
        fmc_i2c_wt <= '0';
      else
        fmc_i2c_rt <= (fmc_i2c_rt or fmc_i2c_re) and not fmc_i2c_rack;
        fmc_i2c_wt <= (fmc_i2c_wt or fmc_i2c_we) and not fmc_i2c_wack;
      end if;
    end if;
  end process;
  fmc_i2c_o.cyc <= fmc_i2c_tr;
  fmc_i2c_o.stb <= fmc_i2c_tr;
  fmc_i2c_wack <= fmc_i2c_i.ack and fmc_i2c_wt;
  fmc_i2c_rack <= fmc_i2c_i.ack and fmc_i2c_rt;
  fmc_i2c_o.adr <= ((26 downto 0 => '0') & wb_adr_i(4 downto 2)) & (1 downto 0 => '0');
  fmc_i2c_o.sel <= wr_sel_d0;
  fmc_i2c_o.we <= fmc_i2c_wt;
  fmc_i2c_o.dat <= wr_dat_d0;

  -- Interface flash_spi
  flash_spi_tr <= flash_spi_wt or flash_spi_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        flash_spi_rt <= '0';
        flash_spi_wt <= '0';
      else
        flash_spi_rt <= (flash_spi_rt or flash_spi_re) and not flash_spi_rack;
        flash_spi_wt <= (flash_spi_wt or flash_spi_we) and not flash_spi_wack;
      end if;
    end if;
  end process;
  flash_spi_o.cyc <= flash_spi_tr;
  flash_spi_o.stb <= flash_spi_tr;
  flash_spi_wack <= flash_spi_i.ack and flash_spi_wt;
  flash_spi_rack <= flash_spi_i.ack and flash_spi_rt;
  flash_spi_o.adr <= ((26 downto 0 => '0') & wb_adr_i(4 downto 2)) & (1 downto 0 => '0');
  flash_spi_o.sel <= wr_sel_d0;
  flash_spi_o.we <= flash_spi_wt;
  flash_spi_o.dat <= wr_dat_d0;

  -- Interface vic
  vic_tr <= vic_wt or vic_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        vic_rt <= '0';
        vic_wt <= '0';
      else
        vic_rt <= (vic_rt or vic_re) and not vic_rack;
        vic_wt <= (vic_wt or vic_we) and not vic_wack;
      end if;
    end if;
  end process;
  vic_o.cyc <= vic_tr;
  vic_o.stb <= vic_tr;
  vic_wack <= vic_i.ack and vic_wt;
  vic_rack <= vic_i.ack and vic_rt;
  vic_o.adr <= ((23 downto 0 => '0') & wb_adr_i(7 downto 2)) & (1 downto 0 => '0');
  vic_o.sel <= wr_sel_d0;
  vic_o.we <= vic_wt;
  vic_o.dat <= wr_dat_d0;

  -- Interface buildinfo
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        buildinfo_rack <= '0';
      else
        buildinfo_rack <= buildinfo_re and not buildinfo_rack;
      end if;
    end if;
  end process;
  buildinfo_data_o <= wr_dat_d0;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        buildinfo_wp <= '0';
      else
        buildinfo_wp <= (wr_req_d0 or buildinfo_wp) and rd_req_int;
      end if;
    end if;
  end process;
  buildinfo_we <= (wr_req_d0 or buildinfo_wp) and not rd_req_int;
  process (wb_adr_i, wr_adr_d0, buildinfo_re) begin
    if buildinfo_re = '1' then
      buildinfo_addr_o <= wb_adr_i(7 downto 2);
    else
      buildinfo_addr_o <= wr_adr_d0(7 downto 2);
    end if;
  end process;

  -- Interface wrc_regs
  wrc_regs_tr <= wrc_regs_wt or wrc_regs_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wrc_regs_rt <= '0';
        wrc_regs_wt <= '0';
      else
        wrc_regs_rt <= (wrc_regs_rt or wrc_regs_re) and not wrc_regs_rack;
        wrc_regs_wt <= (wrc_regs_wt or wrc_regs_we) and not wrc_regs_wack;
      end if;
    end if;
  end process;
  wrc_regs_o.cyc <= wrc_regs_tr;
  wrc_regs_o.stb <= wrc_regs_tr;
  wrc_regs_wack <= wrc_regs_i.ack and wrc_regs_wt;
  wrc_regs_rack <= wrc_regs_i.ack and wrc_regs_rt;
  wrc_regs_o.adr <= ((20 downto 0 => '0') & wb_adr_i(10 downto 2)) & (1 downto 0 => '0');
  wrc_regs_o.sel <= wr_sel_d0;
  wrc_regs_o.we <= wrc_regs_wt;
  wrc_regs_o.dat <= wr_dat_d0;

  -- Interface ddr4_data
  ddr4_data_tr <= ddr4_data_wt or ddr4_data_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ddr4_data_rt <= '0';
        ddr4_data_wt <= '0';
      else
        ddr4_data_rt <= (ddr4_data_rt or ddr4_data_re) and not ddr4_data_rack;
        ddr4_data_wt <= (ddr4_data_wt or ddr4_data_we) and not ddr4_data_wack;
      end if;
    end if;
  end process;
  ddr4_data_o.cyc <= ddr4_data_tr;
  ddr4_data_o.stb <= ddr4_data_tr;
  ddr4_data_wack <= ddr4_data_i.ack and ddr4_data_wt;
  ddr4_data_rack <= ddr4_data_i.ack and ddr4_data_rt;
  ddr4_data_o.adr <= ((19 downto 0 => '0') & wb_adr_i(11 downto 2)) & (1 downto 0 => '0');
  ddr4_data_o.sel <= wr_sel_d0;
  ddr4_data_o.we <= ddr4_data_wt;
  ddr4_data_o.dat <= wr_dat_d0;

  -- Interface ddr5_data
  ddr5_data_tr <= ddr5_data_wt or ddr5_data_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ddr5_data_rt <= '0';
        ddr5_data_wt <= '0';
      else
        ddr5_data_rt <= (ddr5_data_rt or ddr5_data_re) and not ddr5_data_rack;
        ddr5_data_wt <= (ddr5_data_wt or ddr5_data_we) and not ddr5_data_wack;
      end if;
    end if;
  end process;
  ddr5_data_o.cyc <= ddr5_data_tr;
  ddr5_data_o.stb <= ddr5_data_tr;
  ddr5_data_wack <= ddr5_data_i.ack and ddr5_data_wt;
  ddr5_data_rack <= ddr5_data_i.ack and ddr5_data_rt;
  ddr5_data_o.adr <= ((19 downto 0 => '0') & wb_adr_i(11 downto 2)) & (1 downto 0 => '0');
  ddr5_data_o.sel <= wr_sel_d0;
  ddr5_data_o.we <= ddr5_data_wt;
  ddr5_data_o.dat <= wr_dat_d0;

  -- Process for write requests.
  process (wr_adr_d0, metadata_we, wr_req_d0, csr_resets_wack, therm_id_wack, fmc_i2c_wack, flash_spi_wack, vic_wack, buildinfo_we, wrc_regs_wack, ddr4_data_wack, ddr5_data_wack) begin
    metadata_wr_o <= '0';
    csr_resets_wreq <= '0';
    csr_ddr4_addr_wreq <= '0';
    csr_ddr5_addr_wreq <= '0';
    therm_id_we <= '0';
    fmc_i2c_we <= '0';
    flash_spi_we <= '0';
    vic_we <= '0';
    buildinfo_wr_o <= '0';
    wrc_regs_we <= '0';
    ddr4_data_we <= '0';
    ddr5_data_we <= '0';
    case wr_adr_d0(13 downto 12) is
    when "00" =>
      case wr_adr_d0(11 downto 8) is
      when "0000" =>
        case wr_adr_d0(7 downto 6) is
        when "00" =>
          -- Submap metadata
          metadata_wr_o <= metadata_we;
          wr_ack_int <= metadata_we;
        when "01" =>
          case wr_adr_d0(5 downto 2) is
          when "0000" =>
            -- Reg csr_app_offset
            wr_ack_int <= wr_req_d0;
          when "0001" =>
            -- Reg csr_resets
            csr_resets_wreq <= wr_req_d0;
            wr_ack_int <= csr_resets_wack;
          when "0010" =>
            -- Reg csr_fmc_presence
            wr_ack_int <= wr_req_d0;
          when "0011" =>
            -- Reg csr_unused0
            wr_ack_int <= wr_req_d0;
          when "0100" =>
            -- Reg csr_ddr_status
            wr_ack_int <= wr_req_d0;
          when "0101" =>
            -- Reg csr_pcb_rev
            wr_ack_int <= wr_req_d0;
          when "0110" =>
            -- Reg csr_ddr4_addr
            csr_ddr4_addr_wreq <= wr_req_d0;
            wr_ack_int <= wr_req_d0;
          when "0111" =>
            -- Reg csr_ddr5_addr
            csr_ddr5_addr_wreq <= wr_req_d0;
            wr_ack_int <= wr_req_d0;
          when others =>
            wr_ack_int <= wr_req_d0;
          end case;
        when "10" =>
          case wr_adr_d0(5 downto 5) is
          when "0" =>
            -- Submap therm_id
            therm_id_we <= wr_req_d0;
            wr_ack_int <= therm_id_wack;
          when "1" =>
            -- Submap fmc_i2c
            fmc_i2c_we <= wr_req_d0;
            wr_ack_int <= fmc_i2c_wack;
          when others =>
            wr_ack_int <= wr_req_d0;
          end case;
        when "11" =>
          -- Submap flash_spi
          flash_spi_we <= wr_req_d0;
          wr_ack_int <= flash_spi_wack;
        when others =>
          wr_ack_int <= wr_req_d0;
        end case;
      when "0001" =>
        -- Submap vic
        vic_we <= wr_req_d0;
        wr_ack_int <= vic_wack;
      when "0010" =>
        -- Submap buildinfo
        buildinfo_wr_o <= buildinfo_we;
        wr_ack_int <= buildinfo_we;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01" =>
      -- Submap wrc_regs
      wrc_regs_we <= wr_req_d0;
      wr_ack_int <= wrc_regs_wack;
    when "10" =>
      -- Submap ddr4_data
      ddr4_data_we <= wr_req_d0;
      wr_ack_int <= ddr4_data_wack;
    when "11" =>
      -- Submap ddr5_data
      ddr5_data_we <= wr_req_d0;
      wr_ack_int <= ddr5_data_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, metadata_data_i, metadata_rack, rd_req_int, csr_app_offset_i, csr_resets_global_reg, csr_resets_appl_reg, csr_fmc_presence_i, csr_ddr_status_ddr4_calib_done_i, csr_ddr_status_ddr5_calib_done_i, csr_pcb_rev_rev_i, csr_ddr4_addr_i, csr_ddr5_addr_i, therm_id_i.dat, therm_id_rack, fmc_i2c_i.dat, fmc_i2c_rack, flash_spi_i.dat, flash_spi_rack, vic_i.dat, vic_rack, buildinfo_data_i, buildinfo_rack, wrc_regs_i.dat, wrc_regs_rack, ddr4_data_i.dat, ddr4_data_rack, ddr5_data_i.dat, ddr5_data_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    metadata_re <= '0';
    therm_id_re <= '0';
    fmc_i2c_re <= '0';
    flash_spi_re <= '0';
    vic_re <= '0';
    buildinfo_re <= '0';
    wrc_regs_re <= '0';
    ddr4_data_re <= '0';
    ddr5_data_re <= '0';
    case wb_adr_i(13 downto 12) is
    when "00" =>
      case wb_adr_i(11 downto 8) is
      when "0000" =>
        case wb_adr_i(7 downto 6) is
        when "00" =>
          -- Submap metadata
          rd_dat_d0 <= metadata_data_i;
          rd_ack_d0 <= metadata_rack;
          metadata_re <= rd_req_int;
        when "01" =>
          case wb_adr_i(5 downto 2) is
          when "0000" =>
            -- Reg csr_app_offset
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= csr_app_offset_i;
          when "0001" =>
            -- Reg csr_resets
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0(0) <= csr_resets_global_reg;
            rd_dat_d0(1) <= csr_resets_appl_reg;
            rd_dat_d0(31 downto 2) <= (others => '0');
          when "0010" =>
            -- Reg csr_fmc_presence
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= csr_fmc_presence_i;
          when "0011" =>
            -- Reg csr_unused0
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= "00000000000000000000000000000000";
          when "0100" =>
            -- Reg csr_ddr_status
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0(0) <= csr_ddr_status_ddr4_calib_done_i;
            rd_dat_d0(1) <= csr_ddr_status_ddr5_calib_done_i;
            rd_dat_d0(31 downto 2) <= (others => '0');
          when "0101" =>
            -- Reg csr_pcb_rev
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0(4 downto 0) <= csr_pcb_rev_rev_i;
            rd_dat_d0(31 downto 5) <= (others => '0');
          when "0110" =>
            -- Reg csr_ddr4_addr
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= csr_ddr4_addr_i;
          when "0111" =>
            -- Reg csr_ddr5_addr
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= csr_ddr5_addr_i;
          when others =>
            rd_ack_d0 <= rd_req_int;
          end case;
        when "10" =>
          case wb_adr_i(5 downto 5) is
          when "0" =>
            -- Submap therm_id
            therm_id_re <= rd_req_int;
            rd_dat_d0 <= therm_id_i.dat;
            rd_ack_d0 <= therm_id_rack;
          when "1" =>
            -- Submap fmc_i2c
            fmc_i2c_re <= rd_req_int;
            rd_dat_d0 <= fmc_i2c_i.dat;
            rd_ack_d0 <= fmc_i2c_rack;
          when others =>
            rd_ack_d0 <= rd_req_int;
          end case;
        when "11" =>
          -- Submap flash_spi
          flash_spi_re <= rd_req_int;
          rd_dat_d0 <= flash_spi_i.dat;
          rd_ack_d0 <= flash_spi_rack;
        when others =>
          rd_ack_d0 <= rd_req_int;
        end case;
      when "0001" =>
        -- Submap vic
        vic_re <= rd_req_int;
        rd_dat_d0 <= vic_i.dat;
        rd_ack_d0 <= vic_rack;
      when "0010" =>
        -- Submap buildinfo
        rd_dat_d0 <= buildinfo_data_i;
        rd_ack_d0 <= buildinfo_rack;
        buildinfo_re <= rd_req_int;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01" =>
      -- Submap wrc_regs
      wrc_regs_re <= rd_req_int;
      rd_dat_d0 <= wrc_regs_i.dat;
      rd_ack_d0 <= wrc_regs_rack;
    when "10" =>
      -- Submap ddr4_data
      ddr4_data_re <= rd_req_int;
      rd_dat_d0 <= ddr4_data_i.dat;
      rd_ack_d0 <= ddr4_data_rack;
    when "11" =>
      -- Submap ddr5_data
      ddr5_data_re <= rd_req_int;
      rd_dat_d0 <= ddr5_data_i.dat;
      rd_ack_d0 <= ddr5_data_rack;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
