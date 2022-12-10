LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY Security_Barrier_Gate IS
    PORT (
        --Input 
        Clock, Reset : IN STD_LOGIC; -- Clock dan Reset
        Front_Sensor, Back_Sensor : IN STD_LOGIC; -- Sensor depan dan belakang
        Password_1 : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- Input Password
        -- Output
        GREEN_LED, RED_LED : OUT STD_LOGIC; -- LED sebagai signal fisik
        HEX_1, HEX_2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-Segment Display
    );
END ENTITY Security_Barrier_Gate;

ARCHITECTURE Behavioral OF Security_Barrier_Gate IS
    -- Deklarasi State
    TYPE FSM_States IS (IDLE, WAIT_PASSWORD, WRONG_PASS, RIGHT_PASS, STOP);
    -- Deklarasi Signal
    SIGNAL Current_State, Next_State : FSM_States;
    SIGNAL Counter_Wait : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    -- Sequential Process
    PROCESS (Clock, Reset)
    BEGIN
        IF (Reset = '0') THEN
            Current_State <= IDLE;
        ELSIF (rising_edge(Clock)) THEN
            Current_State <= Next_State;
        END IF;
    END PROCESS;

    -- Combinational Process
    PROCESS (Current_State, Front_Sensor, Password_1, Back_Sensor, Counter_Wait)
    BEGIN
        CASE Current_State IS

                -- State IDLE 
            WHEN IDLE =>
                -- Ketika Front_Sensor mendeteksi mobil, maka state akan berubah menjadi WAIT_PASSWORD
                IF (Front_Sensor = '1') THEN
                    Next_State <= WAIT_PASSWORD;
                ELSE
                    -- Ketika Front_Sensor tidak mendeteksi mobil, maka state akan tetap IDLE
                    Next_State <= IDLE;
                END IF;

                -- State WAIT_PASSWORD
            WHEN WAIT_PASSWORD =>
                -- Counter_Wait akan bertambah 1 setiap 1 clock cycle
                IF (Counter_Wait <= x"00000003")
                    THEN
                    -- Apabila Counter_Wait belum mencapai 4, maka state akan tetap WAIT_PASSWORD
                    Next_State <= WAIT_PASSWORD;
                ELSE
                    -- Setiap 4 clock cycle, Counter_Wait akan memeriksa password dan kemudian direset
                    -- Password_1 = 101010
                    IF ((Password_1 = "010110"))
                        THEN
                        -- Apabila password benar, maka state akan berubah menjadi RIGHT_PASS
                        Next_State <= RIGHT_PASS;
                    ELSE
                        -- Apabila password salah, maka state akan berubah menjadi WRONG_PASS dan meminta input password lagi
                        Next_State <= WRONG_PASS;
                    END IF;
                END IF;

                -- State WRONG_PASS
            WHEN WRONG_PASS =>
                -- Password_1 = 101010
                IF ((Password_1 = "010110")) THEN
                    -- Apabila password benar, maka state akan berubah menjadi RIGHT_PASS
                    Next_State <= RIGHT_PASS;
                ELSE
                    -- Apabila password salah, maka state akan berubah menjadi WRONG_PASS dan meminta input password lagi sehingga menciptakan looping apabila password terus-menerus salah
                    Next_State <= WRONG_PASS;
                END IF;

                -- State RIGHT_PASS
            WHEN RIGHT_PASS =>
                -- Ketika mobil berhasil melewati barrier, maka state akan berubah menjadi STOP
                IF (Front_Sensor = '1' AND Back_Sensor = '1') THEN
                    -- Apabila mobil yang sebelumnya sudah melewati barrier dan ada mobil lagi dibelakang mobil yang sekarang, maka state akan berubah menjadi STOP
                    Next_State <= STOP;
                ELSIF (Back_Sensor = '1') THEN
                    -- Apabila mobil yang sebelumnya sudah melewati barrier dan tidak ada mobil lagi dibelakang mobil yang sekarang, maka state akan berubah menjadi IDLE
                    Next_State <= IDLE;
                ELSE
                    -- Apabila Back_Sensor tidak mendeteksi mobil, maka state akan tetap RIGHT_PASS agar gerbang terbuka
                    Next_State <= RIGHT_PASS;
                END IF;

                -- State STOP
            WHEN STOP =>
                -- Password_1 = 101010
                IF ((Password_1 = "010110")) THEN
                    -- Apabila password benar, maka state akan berubah menjadi RIGHT_PASS
                    Next_State <= RIGHT_PASS;
                ELSE
                    --  Apabila password salah, maka state akan berubah menjadi STOP dan meminta input password lagi sehingga menciptakan looping apabila password terus-menerus salah
                    Next_State <= STOP;
                END IF;

                -- Default State
                -- Apabila tidak terdapat kondisi yang terpenuhi
            WHEN OTHERS => Next_State <= IDLE;
        END CASE;
    END PROCESS;

END ARCHITECTURE Behavioral;