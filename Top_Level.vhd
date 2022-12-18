LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Top_Level IS
    PORT (
        -- Input 
        Clock, Reset : IN STD_LOGIC; -- Clock dan Reset
        Front_Sensor, Back_Sensor : IN STD_LOGIC; -- Sensor depan dan belakang
        Password_1 : IN INTEGER; -- Input Password
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
            Password_1 : IN INTEGER; -- Input Password
            -- Output
            GREEN_LED, RED_LED : OUT STD_LOGIC; -- LED sebagai signal fisik
            HEX_1, HEX_2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-Segment Display
        );
    END COMPONENT Security_Barrier_Gate;

BEGIN

    -- Melakukan Port Mapping
    GateComponent : Security_Barrier_Gate PORT MAP(
        Clock, Reset, Front_Sensor, Back_Sensor, Password_1, GREEN_LED, RED_LED, HEX_1, HEX_2
    );

END ARCHITECTURE rtl;