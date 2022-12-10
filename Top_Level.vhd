LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Top_Level IS
    PORT (
        -- Input 
        Clock, Reset : IN STD_LOGIC; -- Clock dan Reset
        Front_Sensor, Back_Sensor : IN STD_LOGIC; -- Sensor depan dan belakang
        Password_1 : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- Input Password
        -- Output
        GREEN_LED, RED_LED : OUT STD_LOGIC; -- LED sebagai signal fisik
        HEX_1, HEX_2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-Segment Display
    );
END ENTITY Top_Level;

ARCHITECTURE rtl OF Top_Level IS

    COMPONENT Security_Barrier_Gate IS
        PORT (
            -- Input 
            Clock, Reset : IN STD_LOGIC; -- Clock dan Reset
            Front_Sensor, Back_Sensor : IN STD_LOGIC; -- Sensor depan dan belakang
            Password_1 : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- Input Password
            -- Output
            GREEN_LED, RED_LED : OUT STD_LOGIC; -- LED sebagai signal fisik
            HEX_1, HEX_2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-Segment Display
        );
    END COMPONENT Security_Barrier_Gate;

    -- Hashing
    COMPONENT Simple_Hash IS
        PORT (
            PassIN : IN STD_LOGIC_VECTOR(5 DOWNTO 0); --Password Input
            PassOUT : OUT STD_LOGIC_VECTOR(5 DOWNTO 0) --Password Output
        );
    END COMPONENT Simple_Hash;
    -- Deklarasi signal
    SIGNAL hashedPass : STD_LOGIC_VECTOR(5 DOWNTO 0);
BEGIN

    -- Melakukan Port Mapping
    HashComponent : Simple_Hash PORT MAP(
        Password_1, hashedPass
    );
    GateComponent : Security_Barrier_Gate PORT MAP(
        Clock, Reset, Front_Sensor, Back_Sensor, hashedPass, GREEN_LED, RED_LED, HEX_1, HEX_2
    );

END ARCHITECTURE rtl;