library ieee;
use ieee.std_logic_1164.all;


entity data_storage is

    port 
    (         
        clk : in std_logic;
        rst : in std_logic;
        bouton_gauche : in std_logic;
        bouton_milieu : in std_logic;
        bouton_droit : in std_logic;
        data_v : in std_logic_vector(8 downto 0);
        data_h : in std_logic_vector(8 downto 0);
        
        bouton_gauche_stored : out std_logic;
        bouton_milieu_stored : out std_logic;
        bouton_droit_stored : out std_logic;
        sign_position_v_stored : out std_logic;
        sign_position_h_stored : out std_logic;
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
                
                bouton_gauche_stored <= '0';
                bouton_milieu_stored <= '0';
                bouton_droit_stored <= '0';
                
                sign_position_v_stored <= '0';
                sign_position_h_stored <= '0';
                
            elsif rising_edge(clk) then
            
                stored_data_v <= data_v(7 downto 0);
                stored_data_h <= data_h(7 downto 0);
               
                bouton_gauche_stored <= bouton_gauche;
                bouton_milieu_stored <= bouton_milieu;
                bouton_droit_stored <= bouton_droit;
                
                sign_position_v_stored <= data_v(8);
                sign_position_h_stored <= data_h(8);
                
            end if;
            
    end process;
    
end arch_data_storage;


