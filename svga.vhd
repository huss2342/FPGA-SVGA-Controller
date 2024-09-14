library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity svga is
    Port ( clk : in STD_LOGIC;
           reset_l : in STD_LOGIC;
           sw : in STD_LOGIC_VECTOR (1 downto 0);
           r : out STD_LOGIC_VECTOR (3 downto 0);
           g : out STD_LOGIC_VECTOR (3 downto 0);
           b : out STD_LOGIC_VECTOR (3 downto 0);
           hs : out STD_LOGIC;
           vs : out STD_LOGIC);
end svga;

architecture Behavioral of svga is

COMPONENT clk_wiz_0
 PORT (clk_out1 : OUT STD_LOGIC;
 clk_in1 : IN STD_LOGIC);
 END COMPONENT;
 
 --------------defining signals --------------
SIGNAL vga_clk : STD_LOGIC;

SIGNAL reset_l_tmp :  STD_LOGIC;
SIGNAL reset_l_sync :  STD_LOGIC;
SIGNAL sw_sync :  STD_LOGIC_VECTOR(1 DOWNTO 0);
           
SIGNAL R_INT:  STD_LOGIC_VECTOR (3 DOWNTO 0);
SIGNAL G_INT:  STD_LOGIC_VECTOR (3 DOWNTO 0);
SIGNAL B_INT:  STD_LOGIC_VECTOR (3 DOWNTO 0);
SIGNAL HS_INT:  STD_LOGIC;
SIGNAL VS_INT:  STD_LOGIC;
           
SIGNAL h :  STD_LOGIC_VECTOR (10 DOWNTO 0);
SIGNAL V :  STD_LOGIC_VECTOR (9 DOWNTO 0);

----------------------------**CONCURRENT AREA**----------------------------
begin

--mapping the DCM into the design
mydcm1:clk_wiz_0
PORT MAP(clk_out1 => vga_clk,
                clk_in1   => clk);
    
    
----------------------------RESET---------------------------- 
reset:PROCESS(vga_clk)
    BEGIN
    
   IF (vga_clk = '1' and vga_clk'EVENT)THEN 
      reset_l_tmp <= reset_l;
      reset_l_sync <= reset_l_tmp;
  END IF;
END PROCESS reset;

----------------------------SW_SYNC---------------------------- 
swsync :process(vga_clk)
    BEGIN
     IF (vga_clk = '1' and vga_clk'EVENT) THEN 
    sw_sync <= sw;
    END IF;
    
    END PROCESS swsync;
----------------------------HORIZONTAL COUNTER----------------------------
Hcounter: PROCESS(vga_clk)
   BEGIN 
      IF (vga_clk = '1' and vga_clk'EVENT) THEN 
         IF (reset_l_sync = '0') THEN 
            h <= (OTHERS => '0') ; 
         ELSIF(h<1055)THEN
            h <= h+1;
         ELSIF (h=1055) THEN
            h <= (OTHERS => '0');  
         END IF ; 
      END IF ;
      

END PROCESS Hcounter;

----------------------------VERTICAL COUNTER----------------------------
Vcounter:PROCESS(vga_clk)  
      BEGIN
      
        IF(vga_clk='1' and vga_clk'EVENT) THEN
            IF (reset_l_sync = '0') THEN
            v <= (OTHERS => '0');
            ELSIF (h = 1055) THEN 
                    IF (v<627) THEN
                        v <= v+1;
                    ELSIF (v=627) THEN 
                        v <= (OTHERS => '0');
                    END IF;
            END IF;
       END IF;
            
    END PROCESS Vcounter;

----------------------------SWITCHES COLORS----------------------------
Switches:Process(sw_sync,h,v)
   BEGIN 
   
 --vsync      
 IF(v >= 624 AND v <=627 ) THEN VS_INT <='1'; ELSE VS_INT <='0'; END IF;
 --hsync
 IF(h <= 127) THEN HS_INT <='1'; ELSE  HS_INT <='0';  END IF;
 
--image area
   IF(h>=216 AND h<=1015 AND v>=23 AND v<=622) THEN
            
        IF (sw_sync <= "00") THEN
        R_INT <= "1111";
        G_INT <= "0000";
        B_INT <= "1111";        
        
        
        ELSIF (sw_sync <= "01") THEN
        R_INT <= h(3 DOWNTO 0);
        G_INT <= h(7 DOWNTO 4);
        B_INT <= "0" & h(10 DOWNTO 8);        
        
        
        ELSIF (sw_sync <= "10") THEN
        R_INT <= v(9 DOWNTO 8) &  "00";
        G_INT <= v(7 DOWNTO 4);
        B_INT <= v(3 DOWNTO 0);        
        
     
        ELSIF (sw_sync <= "11") THEN
        R_INT <= v(7 DOWNTO 4) XOR h(7 DOWNTO 4);
        G_INT <= v(9) & "00" & h(10) ;
        B_INT <= NOT (v(3 DOWNTO 0) XOR h(3 DOWNTO 0));        
        
        ELSE
           R_INT <= (OTHERS => '0');
           G_INT <= (OTHERS => '0');
           B_INT <= (OTHERS => '0');
           
        END IF;   
        
  --if its none of the allowed switches combinations      
  ELSE
           R_INT <= (OTHERS => '0');
           G_INT <= (OTHERS => '0');
           B_INT <= (OTHERS => '0'); 
  END IF;
  
          END PROCESS Switches; 
    
----------------------------FINAL FLIPFLOP----------------------------
SYNCING:PROCESS(vga_clk)  

      BEGIN
        IF(vga_clk='1' and vga_clk'EVENT) THEN
             IF (reset_l_sync = '0') THEN
                R <= (OTHERS => '0');
                G <= (OTHERS => '0');
                B <= (OTHERS => '0');
                HS <= '0';
                VS <= '0';
            ELSE
                R <= R_INT;
                G <= G_INT;
                B <= B_INT;
                HS <= HS_INT;
                VS <= VS_INT;
            END IF;
        END IF;
END PROCESS SYNCING;

end Behavioral;