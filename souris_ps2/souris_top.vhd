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
        
        bouton_gauche, bouton_milieu, bouton_droit : out  std_logic;
        sign_position_h : out std_logic;
        sign_position_v : out std_logic;
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
    
    signal sig_bouton_gauche, sig_bouton_gauche_stored : std_logic;
    signal sig_bouton_droit, sig_bouton_droit_stored : std_logic; 
    signal sig_bouton_milieu, sig_bouton_milieu_stored : std_logic;
    signal sig_sign_position_v_stored, sig_sign_position_h_stored : std_logic;


    component pilote_souris 
      
      port (
        mclk : in std_logic;  -- horloge systeme
        rst : in std_logic;  -- reset general du circuit
        
        donnee_souris  : inout std_logic;   -- bidirectionnel
        horloge_souris : inout std_logic;   -- la souris fournie l'horloge
        
        bouton_gauche  : out   std_logic;  -- indique un appui
        bouton_milieu  : out   std_logic;  -- indique un appui
        bouton_droit   : out   std_logic;  -- indique un appui
        position_h     : out   std_logic_vector(9 downto 0);  -- excursion 
        position_v     : out   std_logic_vector(9 downto 0));  -- 

    end component;


    component clkdiv

        port 
        ( 
            mclk : in  std_logic;
            rst : in  std_logic;
            
            clk3 : out  std_logic;
            clk190 : out  std_logic
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
        
    end component;
    

    component seg_display 
    
        port
        (
            x: in std_logic_vector(3 downto 0);

            a_to_g: out std_logic_vector(6 downto 0)
        );
        
    end component;



begin

    m_pilote_souris : pilote_souris 
        port map 
        (
            mclk => mclk, 
            rst => rst, 
            
            donnee_souris => data_mouse, 
            horloge_souris => clk_mouse,
            
            bouton_gauche => sig_bouton_gauche, 
            bouton_droit => sig_bouton_droit, 
            bouton_milieu => sig_bouton_milieu,
            position_h => sig_position_h, 
            position_v => sig_position_v

        );


    clock_divider : clkdiv
        port map
        (
            mclk => mclk,
            rst => rst,
            clk3 => sig_clk3,
            clk190 => sig_clk190
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
            bouton_gauche => sig_bouton_gauche,
            bouton_milieu => sig_bouton_milieu,
            bouton_droit => sig_bouton_droit,
            data_v => sig_position_v(8 downto 0),
            data_h => sig_position_h(8 downto 0),
            
            bouton_gauche_stored => sig_bouton_gauche_stored,
            bouton_milieu_stored => sig_bouton_milieu_stored,
            bouton_droit_stored => sig_bouton_droit_stored,
            sign_position_v_stored => sig_sign_position_v_stored,
            sign_position_h_stored => sig_sign_position_h_stored,
            stored_data_v => sig_position_v_stored,
            stored_data_h => sig_position_h_stored
            
        );


    sign_position_h <= sig_sign_position_h_stored;
    sign_position_v <= sig_sign_position_v_stored;
    bouton_gauche <= sig_bouton_gauche_stored;
    bouton_droit <= sig_bouton_droit_stored;
    bouton_milieu <= sig_bouton_milieu_stored;
    
end arch_souris_top;

