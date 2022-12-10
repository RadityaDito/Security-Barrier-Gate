LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Simple_Hash IS
    PORT (
        PassIN : IN STD_LOGIC_VECTOR(5 DOWNTO 0); --Password Input
        PassOUT : OUT STD_LOGIC_VECTOR(5 DOWNTO 0) --Password Output
    );
END Simple_Hash;

ARCHITECTURE Behavioral OF Simple_Hash IS
    SIGNAL MSB_in, LSB_in, MSB_out, LSB_out : STD_LOGIC_VECTOR(2 DOWNTO 0); --Temporary Signal 

BEGIN
    -- Input dipisahkan menjadi dua dan di hashing masing-masing
    MSB_in <= PassIN(5 DOWNTO 3);
    LSB_in <= PassIN(2 DOWNTO 0);

    --Hashing Mechanism
    Hash_1 : PROCESS (MSB_in) BEGIN
        CASE(MSB_in) IS
            WHEN "000" => MSB_OUT <= "111";
            WHEN "001" => MSB_OUT <= "101";
            WHEN "010" => MSB_OUT <= "110";
            WHEN "100" => MSB_OUT <= "011";
            WHEN "101" => MSB_OUT <= "010";
            WHEN "110" => MSB_OUT <= "001";
            WHEN "111" => MSB_OUT <= "000";
            WHEN OTHERS => MSB_out <= "000";

        END CASE;
    END PROCESS;

    --Hashing Mechanism
    Hash_2 : PROCESS (LSB_in) BEGIN
        CASE(LSB_in) IS
            WHEN "000" => LSB_OUT <= "111";
            WHEN "001" => LSB_OUT <= "101";
            WHEN "010" => LSB_OUT <= "110";
            WHEN "100" => LSB_OUT <= "011";
            WHEN "101" => LSB_OUT <= "010";
            WHEN "110" => LSB_OUT <= "001";
            WHEN "111" => LSB_OUT <= "000";
            WHEN OTHERS => LSB_out <= "000";

        END CASE;
    END PROCESS;

    PassOUT <= MSB_out & LSB_out; -- Output di gabungkan kembali
END Behavioral;