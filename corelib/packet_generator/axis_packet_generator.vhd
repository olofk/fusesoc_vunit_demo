library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library libstorage_1;
use libstorage_1.libstorage_pkg.all;

library libaxis_1;

entity packet_generator is
  port (
    clk      : in  std_ulogic;
    rst      : in  std_ulogic;
    s_tdata  : in  std_ulogic_vector;
    s_tvalid : in  std_ulogic;
    s_tlast  : in  std_ulogic;
    s_tready : out std_ulogic;
    m_tdata  : out std_ulogic_vector;
    m_tvalid : out std_ulogic;
    m_tlast  : out std_ulogic;
    m_tready : in  std_ulogic);
  
end entity packet_generator;

architecture str of packet_generator is
  constant WIDTH : positive := 32;
  constant HEADER_LEN : positive := 2;
  subtype t_header is t_mem(0 to HEADER_LEN-1)(WIDTH-1 downto 0);

  signal header   : t_header;
  signal seq_number : std_ulogic_vector(WIDTH-1 downto 0);
begin

  p_seq_number : process(clk)
  begin
    if rising_edge(clk) then
      if m_tvalid and m_tready and m_tlast then
        seq_number <= seq_number + 1;
      end if;
      if rst then
        seq_number <= (others => '0');
      end if;
    end if;
  end process;
                                
  header <= (x"badc0ffe",
             seq_number);

  framer : entity libaxis_1.axis_framer
    port map (
      clk      => clk,
      rst      => rst,
      header   => header,
      s_tdata  => s_tdata,
      s_tvalid => s_tvalid,
      s_tlast  => s_tlast,
      s_tready => s_tready,
      m_tdata  => m_tdata,
      m_tvalid => m_tvalid,
      m_tlast  => m_tlast,
      m_tready => m_tready);
end architecture str;
