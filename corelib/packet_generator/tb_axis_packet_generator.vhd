--
-- Test bench for AXI Stream packet generator framer. Part of fusesoc_vunit_demo
--
-- Copyright (C) 2015  Olof Kindgren <olof.kindgren@gmail.com>
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--

library std;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library osvvm;
use osvvm.RandomPkg.RandomPType;

library vunit_lib;
context vunit_lib.vunit_context;

library libstorage_1;
use libstorage_1.libstorage_pkg.all;

library libaxis_1;

library axis_packet_generator;

entity tb_axis_packet_generator is

  generic (
    runner_cfg : runner_cfg_t;
    HEADER_LEN   : positive := 2;
    TRANSACTIONS : positive := 500);

end entity tb_axis_packet_generator;

architecture tb of tb_axis_packet_generator is

  constant WIDTH : positive := 32;
  constant MAX_PKT_LEN : positive := 10;
  subtype data_type is std_ulogic_vector(WIDTH-1 downto 0);

  package bfm is new libaxis_1.axis_bfm;

  subtype t_header is t_mem(0 to HEADER_LEN-1)(WIDTH-1 downto 0);

  signal clk : std_ulogic := '1';
  signal rst : std_ulogic := '1';

  signal header   : t_header;
  signal s_tdata  : data_type;
  signal s_tlast  : std_ulogic := '0';
  signal s_tvalid : std_ulogic := '0';
  signal s_tready : std_ulogic;
  signal m_tdata  : data_type;
  signal m_tlast  : std_ulogic;
  signal m_tvalid : std_ulogic;
  signal m_tready : std_ulogic := '0';

  type t_packet is record
    buf : t_mem(0 to MAX_PKT_LEN-1)(WIDTH-1 downto 0);--data_type_arr(0 to MAX_PKT_LEN-1);
    len : positive;
  end record t_packet;

  type t_packets is array (natural range <>) of t_packet;

  shared variable packets : t_packets(0 to TRANSACTIONS-1);
begin

  clk <= not clk after 5 ns;
  rst <= '0' after 20 ns;

  i_dut : entity axis_packet_generator.packet_generator
    port map (
      clk      => clk,
      rst      => rst,
      s_tdata  => s_tdata,
      s_tlast  => s_tlast,
      s_tvalid => s_tvalid,
      s_tready => s_tready,
      m_tdata  => m_tdata,
      m_tlast  => m_tlast,
      m_tvalid => m_tvalid,
      m_tready => m_tready);

  p_send :process 
    variable RV : RandomPType;
    variable n : positive;
  begin
    RV.InitSeed(RV'instance_name);
    for idx in 0 to TRANSACTIONS-1 loop
      n := RV.RandInt(1, MAX_PKT_LEN-HEADER_LEN);
      packets(idx).len := n;
      for widx in 0 to n-1 loop
        packets(idx).buf(widx) := RV.RandSlv(WIDTH);
      end loop;
    end loop;

    wait until falling_edge(rst);


    for idx in 0 to TRANSACTIONS-1 loop
      bfm.send_packet(clk,
                      s_tdata,
                      s_tlast,
                      s_tvalid,
                      s_tready,
                      packets(idx).buf(0 to packets(idx).len-1),
                      0.9);
    end loop;
    wait;
  end process;

  p_receive : process
    variable len : positive;
    variable rec : t_packet;
    variable exp : t_packet;
  begin
    test_runner_setup(runner, runner_cfg);
    wait until falling_edge(rst);
    for idx in 0 to TRANSACTIONS-1 loop
      bfm.recv_packet(clk,
                      m_tdata,
                      m_tlast,
                      m_tvalid,
                      m_tready,
                      rec.buf,
                      rec.len,
                      0.5);
      exp := packets(idx);
      check(exp.len = rec.len-HEADER_LEN, "Mismatch in packet length");
      assert rec.buf(0) = x"badc0ffe" report "Mismatch in packet header" severity failure;
      assert to_integer(unsigned(rec.buf(1))) = idx report "Mismatch in packet header" severity failure;
      for w in HEADER_LEN to rec.len-1 loop
        assert exp.buf(w-HEADER_LEN) = rec.buf(w) report "Data mismatch" severity failure;
      end loop;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture tb;
