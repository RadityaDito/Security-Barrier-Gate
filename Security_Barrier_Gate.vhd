LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY Security_Barrier_Gate IS
    PORT (
        --Input 
        Clock, Reset : IN STD_LOGIC; -- Clock dan Reset
        Front_Sensor, Back_Sensor : IN STD_LOGIC; -- Sensor depan dan belakang
        Password_1 : IN INTEGER; -- Input Password
        -- Output
        GREEN_LED, RED_LED : OUT STD_LOGIC; -- LED sebagai signal fisik
        HEX_1, HEX_2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-Segment Display
    );
END ENTITY Security_Barrier_Gate;

ARCHITECTURE Behavioral OF Security_Barrier_Gate IS

    COMPONENT md5_hash IS
        PORT (
            data_in : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
            hash_done : OUT STD_LOGIC := '0';
            hash_start : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC);
    END COMPONENT md5_hash;

    -- Deklarasi State
    TYPE FSM_States IS (IDLE, WAIT_PASSWORD, WRONG_PASS, RIGHT_PASS, STOP);
    -- Deklarasi Signal
    SIGNAL Current_State, Next_State : FSM_States;
    SIGNAL Counter_Wait : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL RED_TEMP, GREEN_TEMP : STD_LOGIC;
    SIGNAL hash_out : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL hash_out_temp : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL start, done : STD_LOGIC := '0';
    SIGNAL hash_reset : STD_LOGIC := '1';
    SIGNAL password_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- CONSTANT password : STD_LOGIC_VECTOR(127 DOWNTO 0) := x"70AFE0E2DEA65F690BB5D321FCF86BF8";
    CONSTANT password : STD_LOGIC_VECTOR(127 DOWNTO 0) := x"0BEC9DCF8DDC060274087BEB58724B3F";
BEGIN
    -- password_in <= STD_LOGIC_VECTOR(to_unsigned(Password_1, password_in'length));

    hash : md5_hash PORT MAP(
        data_in => password_in,
        data_out => hash_out,
        hash_done => done,
        hash_start => start,
        clk => clock,
        reset => hash_reset
    );

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
                hash_reset <= '1';
                -- Ketika Front_Sensor mendeteksi mobil, maka state akan berubah menjadi WAIT_PASSWORD
                IF (Front_Sensor = '1') THEN
                    Next_State <= WAIT_PASSWORD;
                    password_in <= STD_LOGIC_VECTOR(to_unsigned(Password_1, password_in'length));
                    -- hash_in <= Password_1 & "00000000000000000000000000";
                    start <= '1';
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
                    hash_out_temp <= hash_out;
                    IF (done = '1') THEN
                        IF ((hash_out_temp = password)) THEN
                            -- Apabila password benar, maka state akan berubah menjadi RIGHT_PASS
                            Next_State <= RIGHT_PASS;
                            start <= '0';
                            hash_reset <= '0';
                        ELSE
                            -- Apabila password salah, maka state akan berubah menjadi WRONG_PASS dan meminta input password lagi
                            Next_State <= WRONG_PASS;
                        END IF;
                    END IF;

                END IF;

                -- State WRONG_PASS
            WHEN WRONG_PASS =>
                -- Password_1 = 101010
                IF ((hash_out_temp = password)) THEN
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
                IF ((hash_out_temp = password)) THEN
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

    -- Process Wait For Password
    PROCESS (Clock, Reset)
    BEGIN
        IF (Reset = '0') THEN
            Counter_Wait <= (OTHERS => '0');
        ELSIF (rising_edge(Clock)) THEN
            IF (Current_State = WAIT_PASSWORD) THEN
                Counter_Wait <= Counter_Wait + x"00000001";
            ELSE
                Counter_Wait <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;

    -- Process Displaying Output
    PROCESS (Clock, Current_State)
    BEGIN
        IF (rising_edge(Clock)) THEN
            CASE (Current_State) IS
                WHEN IDLE =>
                    -- GREEN LED dan RED LED akan mati dan 7-segment display OFF
                    GREEN_TEMP <= '0'; -- GREEN LED mati
                    RED_TEMP <= '0'; -- RED LED mati
                    HEX_1 <= "1111111"; -- OFF
                    HEX_2 <= "1111111"; -- OFF   
                WHEN WAIT_PASSWORD =>
                    -- RED LED akan menyala dan 7-segment display akan menampilkan 'En' untuk memberitahu pengguna untuk menginput password kembali
                    GREEN_TEMP <= '0'; -- GREEN LED mati
                    RED_TEMP <= '1'; -- RED LED menyala
                    HEX_1 <= "0000110"; -- Menampilkan "E" pada 7-segment display
                    HEX_2 <= "0101011"; -- Menaampilkan "n" pada 7-segment display
                WHEN WRONG_PASS =>
                    -- Ketika password salah maka RED LED akan berkedip dan 7-segment display akan menampilkan 'EE' untuk memberitahu pengguna bahwa password yang dimasukkan salah
                    GREEN_TEMP <= '0'; -- GREEN LED mati
                    RED_TEMP <= NOT RED_TEMP; -- RED LED berkedip
                    HEX_1 <= "0000110"; -- Menampilkan "E" pada 7-segment display
                    HEX_2 <= "0000110"; -- Menampilkan "E" pada 7-segment display
                WHEN RIGHT_PASS =>
                    -- Ketika password benar maka GREEN LED akan berkedip dan 7-segment display akan menampilkan '60' untuk memberitahu pengguna bahwa password yang dimasukkan benar
                    GREEN_TEMP <= NOT GREEN_TEMP; -- GREEN LED berkedip
                    RED_TEMP <= '0'; --RED LED mati
                    HEX_1 <= "0000010"; -- Menampilkan "6" pada 7-segment display
                    HEX_2 <= "1000000"; -- Menampilkan "0" pada 7-segment display
                WHEN STOP =>
                    -- Ketika mobil sudah melewati barrier dan ada mobil lagi dibelakangnya maka RED LED akan berkedip dan 7-segment display akan menampilkan "SP" untuk memberitahu pengguna bahwa mobil yang sekarang harus berhenti dan menginput password
                    GREEN_TEMP <= '0'; -- GREEN LED mati
                    RED_TEMP <= NOT RED_TEMP; -- RED LED berkedip
                    HEX_1 <= "0010010"; -- Menampilkan "S" pada 7-segment display
                    HEX_2 <= "0001100"; -- Menampilkan "P" pada 7-segment display
                WHEN OTHERS =>
                    GREEN_TEMP <= '0'; -- GREEN LED mati
                    RED_TEMP <= '0'; -- RED LED mati
                    HEX_1 <= "1111111"; -- 7-segment display OFF
                    HEX_2 <= "1111111"; -- 7-segment display OFF
            END CASE;
        END IF;
    END PROCESS;
    RED_LED <= RED_TEMP;
    GREEN_LED <= GREEN_TEMP;
END ARCHITECTURE Behavioral;