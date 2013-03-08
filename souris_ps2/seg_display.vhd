library ieee;
use ieee.std_logic_1164.all;


entity seg_display is

    port
    (
        x: in std_logic_vector(3 downto 0);
        
        a_to_g: out std_logic_vector(6 downto 0)
    );
    
end seg_display;


architecture arch_seg_display of seg_display is
begin

    process (x)
    begin
  
        case x is

            when x"0" => a_to_g <="0000001"; 
            when x"1" => a_to_g <="1001111"; 
            when x"2" => a_to_g <="0010010";  
            when x"3" => a_to_g <="0000110";  
            when x"4" => a_to_g <="1001100";  
            when x"5" => a_to_g <="0100100";  
            when x"6" => a_to_g <="0100000";  
            when x"7" => a_to_g <="0001111";  
            when x"8" => a_to_g <="0000000"; 
            when x"9" => a_to_g <="0000100";  
            when x"A" => a_to_g <="0001000";  
            when x"B" => a_to_g <="1100000";  
            when x"C" => a_to_g <="0110001";  
            when x"D" => a_to_g <="1000010";
            when x"E" => a_to_g <="0110000";
            when others => a_to_g <="0111000";

        end case;

    end process;

end arch_seg_display;


