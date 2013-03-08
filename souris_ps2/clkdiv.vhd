library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity clkdiv is

    port 
    ( 
        mclk : in  std_logic;
        rst : in  std_logic;
        
        clk3 : out  std_logic;
        clk190 : out  std_logic
    );
           
end clkdiv;


architecture arch_clkdiv of clkdiv is
begin

    process (rst, mclk)
    
        variable count : std_logic_vector(23 downto 0);
        
	begin
    
        if rst = '1' then
        
            count := (others => '0');
            
        elsif rising_edge(mclk) then 
        
            count := count + 1;
            clk3 <= count(23);  -- 50MHz/2^(23+1) = 3Hz
            clk190 <= count(17);    -- 50MHz/2^(17+1) = 190Hz
            
    end if;
     
    end process;

end arch_clkdiv;


