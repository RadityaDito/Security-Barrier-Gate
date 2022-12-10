LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Top_Level_TB IS
END Top_Level_TB;

ARCHITECTURE behavior OF Top_Level_TB IS

    COMPONENT Top_Level IS
        PORT (
            -- Input 
            Clock, Reset : IN STD_LOGIC; -- Clock dan Reset
            Front_Sensor, Back_Sensor : IN STD_LOGIC; -- Sensor depan dan belakang
            Password_1 : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- Input Password
            -- Output
            GREEN_LED, RED_LED : OUT STD_LOGIC; -- LED sebagai signal fisik
            HEX_1, HEX_2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111111" -- 7-Segment Display
        );
    END COMPONENT Top_Level;
    -- Deklarasi signal dari input
    SIGNAL Clock : STD_LOGIC := '0';
    SIGNAL Reset : STD_LOGIC := '0';
    SIGNAL Front_Sensor : STD_LOGIC := '0';
    SIGNAL Back_Sensor : STD_LOGIC := '0';
    SIGNAL Password_1 : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');

    -- Deklarasi signal dari output
    SIGNAL GREEN_LED : STD_LOGIC;
    SIGNAL RED_LED : STD_LOGIC;
    SIGNAL HEX_1 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX_2 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    CONSTANT PERIOD : TIME := 10 ps;
BEGIN
    -- Melakukan port map
    Car_park_system : Top_Level PORT MAP(
        Clock => Clock,
        Reset => Reset,
        Front_Sensor => Front_Sensor,
        Back_Sensor => Back_Sensor,
        Password_1 => Password_1,
        GREEN_LED => GREEN_LED,
        RED_LED => RED_LED,
        HEX_1 => HEX_1,
        HEX_2 => HEX_2
    );

    clk_process : PROCESS
    BEGIN
        Clock <= '0';
        WAIT FOR PERIOD/2;
        Clock <= '1';
        WAIT FOR PERIOD/2;
    END PROCESS;

    -- Process Testbench
    stim_proc : PROCESS
    BEGIN
        Reset <= '0';
        Front_Sensor <= '0';
        Back_Sensor <= '0';
        Password_1 <= "101000";
        WAIT FOR PERIOD * 10;
        Reset <= '1';
        WAIT FOR PERIOD * 10;
        Front_Sensor <= '1';
        WAIT FOR PERIOD * 10;
        Password_1 <= "101010";
        WAIT UNTIL HEX_1 = "0000010"; -- Menampilkan "G" pada 7-segment display
        Password_1 <= "101000";
        Back_Sensor <= '1';
        WAIT UNTIL HEX_1 = "0010010"; -- Menampilkan "S" pada 7-segment display
        Password_1 <= "101010";
        front_sensor <= '0';
        WAIT UNTIL HEX_1 = "0000010"; -- Menampilkan "G" pada 7-segment display
        Password_1 <= "101000";
        Back_Sensor <= '1';
        WAIT UNTIL HEX_1 = "1111111"; -- 7-segment display OFF
        Back_Sensor <= '0';
        WAIT;

    END PROCESS;

END;