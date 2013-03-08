library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity mouse_driver is
  
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

end mouse_driver;

architecture arch_mouse_driver of mouse_driver is

  signal fin_tempo : std_logic;
  signal fin_octet : std_logic;
  signal fin_emission : std_logic;
  signal fin_trame : std_logic;
  signal data_in : std_logic;
  signal data_out : std_logic;
  signal clk_in : std_logic;
  signal hs_filtree : std_logic;    -- horloge souris filtree
  
  signal recevoir, emettre, calculer : boolean;
  signal init_tempo, direction_donnee: boolean;
  signal direction_horloge : boolean; 
  signal mouvement_h : signed(8 downto 0);
  signal mouvement_v : signed(8 downto 0);
  signal sig_etat_souris : std_logic_vector(7 downto 0);
  
  type communication_mef is (debut, tempo, rts, emission, reception1, debut_trame, reception3,calcul);
  signal state_mef : communication_mef;
  
  
begin
  
    -- separation des donnes en entree et sortie
    data_in <= donnee_souris;
    donnee_souris <= data_out when direction_donnee else 'Z';


    -- separation des horloges en entree et sortie
    horloge_souris <= '0' when direction_horloge else 'Z';
    clk_in <= horloge_souris ;


    -- par securite, on introduit un filtre anti-parasite sur
    -- l'horloge souris qui consiste à valider un 1 ou un 0 par 8 echantillons
    filtre : process 
  
        variable registre : std_logic_vector(7 downto 0);
    
    begin
  
        wait until rising_edge(mclk);
        
            registre := registre(6 downto 0) & clk_in ;
            
            if registre = "11111111" then
            
              hs_filtree <= '1';    -- filtre de 320 ns car période min horloge souris = 30us
              
            elsif registre = "00000000" then
            
              hs_filtree <= '0'; 
              
            end if;
    
    end process filtre;


-- la temporisation sert à maintenir l'horloge souris
  -- pendant 100 us environ lorsque le systeme veut commander
  -- la souris
    temporisation : process 

        constant duree : natural := 2500;    -- 100 us
        
        variable decompteur : natural range 0 to duree;

    begin
  
        wait until falling_edge(mclk);  -- synchrone
        
            if init_tempo then
            
                decompteur := duree;
                fin_tempo <= '0';
                
            elsif decompteur /=  0 then
            
                decompteur := decompteur -1;
                
            else
            
                fin_tempo <= '1';
                
            end if;
            
    end process temporisation;


    -- le registre emission ne sert qu'a emettre la commande "stream mode"
    emiss : process(emettre, hs_filtree)

        constant mot_f4 : std_logic_vector(11 downto 0) := "010111101000";

        variable nb_bits : natural range 0 to 11;
        variable registre_emission : std_logic_vector(11 downto 0);
    
    begin

        if emettre = false then -- asynchrone
        
            registre_emission := mot_f4;
            nb_bits := 0;
            
        elsif falling_edge(hs_filtree) then  -- synchrone
        
            registre_emission := '0' & registre_emission(11 downto 1); 
            nb_bits := nb_bits + 1;
            
        end if;
        
        if nb_bits = 11 then
        
            fin_emission <= '1';
            
        else
        
            fin_emission <= '0';
            
        end if;
        
        data_out <= registre_emission(0);

    end process emiss;


    -- le registre de reception sert soit à recevoir l'acquittement
    -- du mot de commande precedent
    -- soit de recevoir une trame complete
    reception : process(recevoir, hs_filtree)
    
        variable nb_bits : integer range 0 to 33;
        variable registre_reception : std_logic_vector(32 downto 0);
        
    begin
    
        if recevoir = false  then -- asynchrone
        
            nb_bits := 0;
            ------    elsif falling_edge(hs_filtree) then  -- synchrone
            
        elsif rising_edge(hs_filtree) then  -- synchrone
        
            registre_reception := data_in & registre_reception(32 downto 1) ;
            nb_bits := nb_bits + 1;
            
        end if;
        
        if nb_bits = 11 then
            fin_octet <= '1';
            -- traitement ignoré pour l'instant
        else
            fin_octet <= '0';
        end if;
        
        if nb_bits = 33 then
            fin_trame <= '1';
        else
            fin_trame <= '0';
        end if;
        
        mouvement_v <= signed(registre_reception(6) &   -- Signe de la position en Y
        registre_reception(30 downto 23));    -- Octet 3: position en Y
        mouvement_h <= signed(registre_reception(5) &   -- Signe de la position en X
        registre_reception(19 downto 12));    -- Octet 2: position en X
        sig_etat_souris <= registre_reception(8 downto 1);
        
    end process reception;

-- pour le calcul de position, on considere que la sortie
  -- est un écran de 640 (horizontal)par 480 (vertical) pixels .
  -- Au départ on se situe au milieu de l'ecran (0,0)
  -- on doit limiter les excursions à +319 -320 et +239 et -240 
  calc: process
    variable registre_h  : signed(10 downto 0); 
    variable registre_v  : signed(10 downto 0);
    constant limite_gh : integer := -320;
    constant limite_dh : integer := +319;
    constant limite_bv : integer := -240;
    constant limite_hv : integer := +239;
    
  begin  -- process
    wait until rising_edge(mclk);  -- synchrone
    if init_tempo then                   -- initialisation au depart
      registre_h := (others => '0');
      registre_v := (others => '0');
      etat_souris <= (others => '0');
    elsif calculer then                  -- accumulation
      registre_h := registre_h + mouvement_h;
      registre_v := registre_v + mouvement_v;
      if registre_h > limite_dh then     -- saturation de la sortie
        registre_h := to_signed(limite_dh,11);
      elsif registre_h < limite_gh then
        registre_h := to_signed(limite_gh,11);
      end if;
      if registre_v > limite_hv then
        registre_v := to_signed(limite_hv,11);
      elsif registre_v < limite_bv then
        registre_v := to_signed(limite_bv,11); 
      end if;
      position_v <= std_logic_vector (registre_v(9 downto 0));         -- les sorties 
      position_h <= std_logic_vector (registre_h(9 downto 0));
      etat_souris <= sig_etat_souris;
    end if;
  end process;

  -- le sequenceur enchaine les differentes etapes et boucle
  -- sur la reception des trames et leur traitement
  sequenceur: process
  begin  -- process sequenceur
    wait until rising_edge(mclk);  -- synchrone
    if rst = '1' then
      state_mef <= debut;
    else
      case state_mef is
      
        when debut =>
            state_mef <= tempo;
            
        when tempo => 
            if fin_tempo = '1' then
                state_mef <= rts;
            end if;
            
        when rts => 
            state_mef <= emission;
            
        when emission => 
            if fin_emission = '1' then
                state_mef <= reception1;
            end if;
            
        when reception1 => 
            if fin_octet = '1'  then
                state_mef <= debut_trame ;
            end if;
        when debut_trame 
        =>  
            state_mef <= reception3;
            
        when reception3 => 
            if fin_trame = '1' then
                state_mef <= calcul;
            end if;
            
        when calcul =>  
            state_mef <= reception3;
            
      end case;
    end if;
  end process sequenceur;

  init_tempo <= (state_mef = debut);

  direction_horloge <= (state_mef = tempo);

  emettre <= (state_mef = emission);

  direction_donnee <= (state_mef = emission) or (state_mef = rts) ;

  recevoir <= (state_mef = reception1) or (state_mef = reception3);

  calculer <= (state_mef = calcul);

end arch_mouse_driver; 
