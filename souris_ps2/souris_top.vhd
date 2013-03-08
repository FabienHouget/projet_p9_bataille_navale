library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity souris_top is

    port 
    ( 
        mclk : in  std_logic;
        rst : in  std_logic;
        
        data_mouse  : inout std_logic;
        clk_mouse : inout std_logic;
        
        state_souris : out std_logic_vector(7 downto 0);
        an: out std_logic_vector(3 downto 0);
        a_to_g:out std_logic_vector(6 downto 0)
    );
    
end souris_top;


architecture arch_souris_top of souris_top is

    signal sig_clk190 : std_logic;
    signal sig_clk3 : std_logic;
    
    signal x:std_logic_vector(3 downto 0);

    signal sig_position_h, sig_position_v : std_logic_vector(9 downto 0);
    signal sig_position_h_stored, sig_position_v_stored : std_logic_vector(7 downto 0);

    signal sig_mclk : std_logic;    --
    signal sig_etat_souris    :  std_logic_vector(7 DOWNTO 0);


    component mouse_driver is
  
        port 
        (
            mclk : in std_logic;  -- horloge systeme
            rst : in std_logic;  -- reset general du circuit

            donnee_souris  : inout std_logic;   -- bidirectionnel
            horloge_souris : inout std_logic;   -- la souris fournie l'horloge

            position_h     : out   std_logic_vector(9 downto 0);  -- excursion -512 à +511
            position_v     : out   std_logic_vector(9 downto 0);  -- -512 +511
            etat_souris    : out   std_logic_vector(7 downto 0)
        );

    end component;


    component clkdiv

        port 
        ( 
            mclk : in  std_logic;
            rst : in  std_logic;
            
            clk3 : out  std_logic;
            clk190 : out  std_logic;
            clk25M : out std_logic
        );
               
    end component;


    component display_refresh

        port 
        ( 
            clk : in std_logic;
            rst : in std_logic;
            position_h : in std_logic_vector(7 downto 0);
            position_v : in std_logic_vector(7 downto 0);
            
            data_to_display : out std_logic_vector(3 downto 0);
            an : out std_logic_vector(3 downto 0)
        );
                  
    end component;


    component data_storage 
    
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
        
    end component;
    

    component seg_display 
    
        port
        (
            x: in std_logic_vector(3 downto 0);

            a_to_g: out std_logic_vector(6 downto 0)
        );
        
    end component;



begin

    m_mouse_driver : mouse_driver 
        port map 
        (
            mclk => sig_mclk, 
            rst => rst, 
            
            donnee_souris => data_mouse, 
            horloge_souris => clk_mouse,
            
            etat_souris => sig_etat_souris,
            position_h => sig_position_h, 
            position_v => sig_position_v

        );


    clock_divider : clkdiv
        port map
        (
            mclk => mclk,
            rst => rst,
            clk3 => sig_clk3,
            clk190 => sig_clk190,
            clk25M => sig_mclk
        );


    m_display_refresh : display_refresh

        port map
        ( 
            clk => sig_clk190,
            rst => rst,
            position_h => sig_position_h_stored(7 downto 0),
            position_v => sig_position_v_stored(7 downto 0),
            
            data_to_display => x,
            an => an
        );
        

    m_seg_display : seg_display 
        port map 
        (
            x=>x,
            
            a_to_g=>a_to_g
        );
    
    
    m_data_storage : data_storage 
        port map 
        (
            clk => sig_clk3,
            rst => rst,
            etat_souris => sig_etat_souris,
            data_v => sig_position_v(8 downto 0),
            data_h => sig_position_h(8 downto 0),
            
           
            stored_etat_souris => state_souris,
            stored_data_v => sig_position_v_stored,
            stored_data_h => sig_position_h_stored
            
        );

    
end arch_souris_top;

