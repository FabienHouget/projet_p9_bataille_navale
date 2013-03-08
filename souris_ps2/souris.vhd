library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


ENTITY pilote_souris IS
  
  PORT (
    mclk : in std_logic;  -- horloge systeme
    rst : in std_logic;  -- reset general du circuit
    donnee_souris  : inout std_logic;   -- bidirectionnel
    horloge_souris : inout std_logic;   -- la souris fournie l'horloge
    bouton_gauche  : out   std_logic;  -- indique un appui
    bouton_milieu  : out   std_logic;  -- indique un appui
    bouton_droit   : out   std_logic;  -- indique un appui
    position_h     : out   std_logic_vector(9 DOWNTO 0);  -- excursion -512 à +511
    position_v     : out   std_logic_vector(9 DOWNTO 0));  -- -512 +511

END pilote_souris;

ARCHITECTURE enseirb OF pilote_souris IS
  SIGNAL registre_emission : std_logic_vector(11 DOWNTO 0);
  SIGNAL recevoir, emettre, calculer : boolean;
  SIGNAL init_tempo, direction_donnee: boolean;
  SIGNAL  direction_horloge : boolean; 
  SIGNAL mouvement_h : signed(8 DOWNTO 0);
  SIGNAL mouvement_v : signed(8 DOWNTO 0);
  SIGNAL droit : std_logic;
  SIGNAL gauche : std_logic;
  SIGNAL milieu : std_logic;
  
  TYPE t_etat IS (debut, tempo, rts, emission,
                  reception1, debut_trame, reception3,calcul);
  SIGNAL etat : t_etat;
  SIGNAL fin_tempo : std_logic;
  SIGNAL fin_octet : std_logic;
  SIGNAL fin_emission : std_logic;
  SIGNAL fin_trame : std_logic;
  SIGNAL data_in : std_logic;
  SIGNAL data_out : std_logic;
  SIGNAL clk_in : std_logic;
  SIGNAL hs_filtree : std_logic;       -- horloge souris filtree
  
BEGin  -- enseirb
  
-- separation des donnes en entree et sortie
  data_in <= donnee_souris;
  donnee_souris <= data_out WHEN direction_donnee ELSE 'Z';

  -- separation des horloges en entree et sortie
  horloge_souris <= '0' WHEN direction_horloge ELSE 'Z';
  clk_in <= horloge_souris ;

  -- par securite, on introduit un filtre anti-parasite sur
  -- l'horloge souris qui consiste à valider un 1 ou un 0 par 8 echantillons
  filtre: PROCESS 
    VARIABLE registre : std_logic_vector(7 DOWNTO 0);
  BEGin  -- PROCESS filtre
    WAIT UNTIL rising_edge(mclk);
    registre := registre(6 DOWNTO 0) & clk_in ;
    IF registre = "11111111" THEN
      hs_filtree <= '1';                -- filtre de 320 ns car période min horloge souris = 30us
    END IF;
    IF registre = "00000000" THEN
      hs_filtree <= '0'; 
    END IF;
  END PROCESS filtre;

-- la temporisation sert à maintenir l'horloge souris
  -- pendant 100 us environ lorsque le systeme veut commander
  -- la souris
  temporisation: PROCESS 
    CONSTANT duree : natural := 2400;    -- 100 us
    VARIABLE decompteur : natural RANGE 0 TO duree;
  BEGin  -- PROCESS temporisation
    WAIT UNTIL falling_edge(mclk);  -- synchrone
    IF init_tempo THEN
      decompteur := duree;
      fin_tempo <= '0';
    ELSIF decompteur /=  0 THEN       
      decompteur := decompteur -1;
    ELSE
      fin_tempo <= '1';
    END IF;
  END PROCESS temporisation;

  -- le registre emission ne sert qu'a emettre la commande "stream mode"
  emiss: PROCESS(emettre, hs_filtree)
    VARIABLE nb_bits : natural RANGE 0 TO 11;
    VARIABLE registre_emission : std_logic_vector(11 DOWNTO 0);
    CONSTANT mot_f4 : std_logic_vector(11 DOWNTO 0) := "010111101000";
  BEGin  -- PROCESS emission
    IF emettre = false THEN                    -- asynchrone
      registre_emission := mot_f4;
      nb_bits := 0;
    ELSIF falling_edge(hs_filtree) THEN  -- synchrone
      registre_emission := '0' & registre_emission(11 DOWNTO 1); 
      nb_bits := nb_bits + 1;
    END IF;
    IF nb_bits = 11 THEN
      fin_emission <= '1';
    ELSE
      fin_emission <= '0';
    END IF;
    data_out <= registre_emission(0);
  END PROCESS emiss;

  -- le registre de reception sert soit à recevoir l'acquittement
  -- du mot de commande precedent
  -- soit de recevoir une trame complete
  reception : PROCESS(recevoir, hs_filtree)
    VARIABLE nb_bits : natural RANGE 0 TO 33;
    VARIABLE registre_reception : std_logic_vector(32 DOWNTO 0);
  BEGin  -- PROCESS emission
    IF recevoir = false  THEN -- asynchrone
      nb_bits := 0;
------    ELSIF falling_edge(hs_filtree) THEN  -- synchrone
          ELSIF rising_edge(hs_filtree) THEN  -- synchrone
      registre_reception := data_in & registre_reception(32 DOWNTO 1) ;
      nb_bits := nb_bits + 1;
    END IF;
    IF nb_bits = 11 THEN
      fin_octet <= '1';
      -- traitement ignoré pour l'instant
    ELSE
      fin_octet <= '0';
    END IF;
    IF nb_bits = 33 THEN
      fin_trame <= '1';
    ELSE
      fin_trame <= '0';
    END IF;
    mouvement_v <= signed(registre_reception(6) &   -- Signe de la position en Y
                          registre_reception(30 DOWNTO 23));    -- Octet 3: position en Y
    mouvement_h <= signed(registre_reception(5) &   -- Signe de la position en X
                          registre_reception(19 DOWNTO 12));    -- Octet 2: position en X
    gauche <= registre_reception(1);
    milieu <= registre_reception(3);
    droit <= registre_reception(2);
  END PROCESS reception;

-- pour le calcul de position, on considere que la sortie
  -- est un écran de 640 (horizontal)par 480 (vertical) pixels .
  -- Au départ on se situe au milieu de l'ecran (0,0)
  -- on doit limiter les excursions à +319 -320 et +239 et -240 
  calc: PROCESS
    VARIABLE registre_h  : signed(10 DOWNTO 0); 
    VARIABLE registre_v  : signed(10 DOWNTO 0);
    CONSTANT limite_gh : integer := -320;
    CONSTANT limite_dh : integer := +319;
    CONSTANT limite_bv : integer := -240;
    CONSTANT limite_hv : integer := +239;
    
  BEGin  -- PROCESS
    WAIT UNTIL rising_edge(mclk);  -- synchrone
    IF init_tempo THEN                   -- initialisation au depart
      registre_h := (OTHERS => '0');
      registre_v := (OTHERS => '0');
      bouton_gauche <= '0';
      bouton_droit <= '0';
      bouton_milieu <= '0';
    ELSIF calculer THEN                  -- accumulation
      registre_h := registre_h + mouvement_h;
      registre_v := registre_v + mouvement_v;
      IF registre_h > limite_dh THEN     -- saturation de la sortie
        registre_h := to_signed(limite_dh,11);
      ELSIF registre_h < limite_gh THEN
        registre_h := to_signed(limite_gh,11);
      END IF;
      IF registre_v > limite_hv THEN
        registre_v := to_signed(limite_hv,11);
      ELSIF registre_v < limite_bv THEN
        registre_v := to_signed(limite_bv,11); 
      END IF;
      position_v <= std_logic_vector (registre_v(9 DOWNTO 0));         -- les sorties 
      position_h <= std_logic_vector (registre_h(9 DOWNTO 0));
      bouton_gauche <= gauche;
      bouton_droit <= droit;
      bouton_milieu <= milieu;
    END IF;
  END PROCESS;

  -- le sequenceur enchaine les differentes etapes et boucle
  -- sur la reception des trames et leur traitement
  sequenceur: PROCESS
  BEGin  -- PROCESS sequenceur
    WAIT UNTIL rising_edge(mclk);  -- synchrone
    IF rst = '1' THEN
      etat <= debut;
    ELSE
      CASE etat IS
        WHEN debut => etat <= tempo;
        WHEN tempo => IF fin_tempo = '1' THEN
                        etat <= rts;
                      END IF;
        WHEN rts => etat <= emission;
        WHEN emission => IF fin_emission = '1' THEN
                           etat <= reception1;
                         END IF;
        WHEN reception1 => IF fin_octet = '1'  THEN
                             etat <= debut_trame ;
                           END IF;
        WHEN debut_trame =>  etat <= reception3;
        WHEN reception3 => IF fin_trame = '1' THEN
                             etat <= calcul;
                           END IF;
        WHEN calcul =>  etat <= reception3;
      END CASE;
    END IF;
  END PROCESS sequenceur;

  init_tempo <= (etat = debut);

  direction_horloge <= (etat = tempo);

  emettre <= (etat = emission);

  direction_donnee <= (etat = emission) OR (etat = rts) ;

  recevoir <= (etat = reception1) OR (etat = reception3);

  calculer <= (etat = calcul);

END enseirb; 
