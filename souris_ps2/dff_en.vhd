library ieee;
use ieee.std_logic_1164.all;


entity data_storage is

    port 
    (         
        clk : in std_logic;
        rst : in std_logic;
        etat_souris : in std_logic_vector(7 downto 0);
        data_v : in std_logic_vector(8 downto 0);
        data_h : in std_logic_vector(8 downto 0);
            
        stored_etat_souris : out std_logic_vector(7 downto 0);
        stored_data_v : out std_logic_vector(7 downto 0);
        stored_data_h : out std_logic_vector(7 downto 0)
    );
    
end data_storage;


architecture arch_data_storage of data_storage is
begin

    process (rst, clk)
    begin
            if rst ='1' then 
            
                stored_data_v <= (others => '0');
                stored_data_h <= (others => '0');
                stored_etat_souris <= (others => '0');
                
            elsif rising_edge(clk) then
            
                stored_data_v <= data_v(7 downto 0);
                stored_data_h <= data_h(7 downto 0);
                stored_etat_souris <= etat_souris;
                
            end if;
            
    end process;
    
end arch_data_storage;


