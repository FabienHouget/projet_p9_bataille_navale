library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity display_refresh is

    port 
    ( 
        clk : in std_logic;
        rst : in std_logic;
        position_h : in std_logic_vector(7 downto 0);
        position_v : in std_logic_vector(7 downto 0);
        
        data_to_display : out std_logic_vector(3 downto 0);
        an : out std_logic_vector(3 downto 0)
    );
			  
end display_refresh;


architecture arch_display_refresh of display_refresh is
begin

    process (rst, clk)
    
        variable q_int : std_logic_vector(1 downto 0);
        
    begin

        if rst = '1' then 
        
            q_int := (others => '0');
            data_to_display <= (others => '0');
            an <= "0000";
            
        elsif rising_edge(clk) then 
            
            case q_int is
            
                when "00" =>
                    an <= "1110";
                    data_to_display <= position_h(3 downto 0);
                    
                when "01" =>
                    an <= "1101";
                    data_to_display <= position_h(7 downto 4);
                    
                when "10" =>
                    an <= "1011";
                    data_to_display <= position_v(3 downto 0);
                    
                when others =>
                    an <= "0111";
                    data_to_display <= position_v(7 downto 4);
                    
            end case;
            
            q_int := q_int + 1;          
            
        end if;
        
    end process;

end arch_display_refresh;


