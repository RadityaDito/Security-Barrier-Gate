LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY md5_hash IS
    PORT (
        data_in : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
        hash_done : OUT STD_LOGIC := '0';
        hash_start : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC);
END md5_hash;

ARCHITECTURE Behavioral OF md5_hash IS
    SUBTYPE uint512_t IS unsigned(0 TO 511);
    SUBTYPE uint32_t IS unsigned(31 DOWNTO 0);
    SUBTYPE uint8_t IS unsigned(7 DOWNTO 0);

    TYPE const_s IS ARRAY (0 TO 63) OF uint8_t;
    TYPE const_k IS ARRAY (0 TO 63) OF uint32_t;
    TYPE message IS ARRAY (0 TO 15) OF uint32_t;

    CONSTANT S : const_s := (
        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
        X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,

        X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
        X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
        X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
        X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,

        X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
        X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
        X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
        X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,

        X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
        X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
        X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
        X"06", X"0A", X"0F", X"15"
    ); -- 6, 10, 15, 21);

    CONSTANT K : const_k := (
        X"d76aa478", X"e8c7b756", X"242070db", X"c1bdceee",
        X"f57c0faf", X"4787c62a", X"a8304613", X"fd469501",
        X"698098d8", X"8b44f7af", X"ffff5bb1", X"895cd7be",
        X"6b901122", X"fd987193", X"a679438e", X"49b40821",
        X"f61e2562", X"c040b340", X"265e5a51", X"e9b6c7aa",
        X"d62f105d", X"02441453", X"d8a1e681", X"e7d3fbc8",
        X"21e1cde6", X"c33707d6", X"f4d50d87", X"455a14ed",
        X"a9e3e905", X"fcefa3f8", X"676f02d9", X"8d2a4c8a",
        X"fffa3942", X"8771f681", X"6d9d6122", X"fde5380c",
        X"a4beea44", X"4bdecfa9", X"f6bb4b60", X"bebfbc70",
        X"289b7ec6", X"eaa127fa", X"d4ef3085", X"04881d05",
        X"d9d4d039", X"e6db99e5", X"1fa27cf8", X"c4ac5665",
        X"f4292244", X"432aff97", X"ab9423a7", X"fc93a039",
        X"655b59c3", X"8f0ccc92", X"ffeff47d", X"85845dd1",
        X"6fa87e4f", X"fe2ce6e0", X"a3014314", X"4e0811a1",
        X"f7537e82", X"bd3af235", X"2ad7d2bb", X"eb86d391"
    );

    SIGNAL M : uint512_t := (OTHERS => '0');
    SIGNAL message_length : uint32_t := (OTHERS => '0');
    SIGNAL data_counter : NATURAL := 0;
    SIGNAL loop_counter, loop_counter_n : NATURAL := 0;

    CONSTANT a0 : uint32_t := X"67452301";
    CONSTANT b0 : uint32_t := X"efcdab89";
    CONSTANT c0 : uint32_t := X"98badcfe";
    CONSTANT d0 : uint32_t := X"10325476";

    SIGNAL A, A_n : uint32_t := a0;
    SIGNAL B, B_n : uint32_t := b0;
    SIGNAL C, C_n : uint32_t := c0;
    SIGNAL D, D_n : uint32_t := d0;
    SIGNAL F : uint32_t := to_unsigned(0, A'length);
    SIGNAL g : INTEGER := 0;

    TYPE state_t IS (
        idle,
        load_length,
        load_data,
        pad,
        rotate,
        stage1_F, stage1_B,
        stage2_F, stage2_B,
        stage3_F, stage3_B,
        stage4_F, stage4_B,
        stage5, -- add a0 to A, b0 to B etc.
        stage6, -- swap endianness
        finished,
        store_data
    );
    SIGNAL state, state_n : state_t;

    --Rotate
    FUNCTION leftrotate(x : IN uint32_t; c : IN uint8_t) RETURN uint32_t IS
    BEGIN
        RETURN SHIFT_LEFT(x, to_integer(c)) OR SHIFT_RIGHT(x, to_integer(32 - c));
    END FUNCTION leftrotate;

    -- Melakukan swap endianness
    FUNCTION swap_endianness(x : IN uint32_t) RETURN uint32_t IS
    BEGIN
        RETURN x(7 DOWNTO 0) &
        x(15 DOWNTO 8) &
        x(23 DOWNTO 16) &
        x(31 DOWNTO 24);
    END FUNCTION swap_endianness;

BEGIN
    main : PROCESS (reset, clk)
    BEGIN
        IF (reset = '0') THEN
            state <= idle;
            loop_counter <= 0;
        ELSIF (rising_edge(clk)) THEN
            state <= state_n;
            loop_counter <= loop_counter_n;
            A <= A_n;
            B <= B_n;
            C <= C_n;
            D <= D_n;
        END IF;
    END PROCESS main;

    fsm : PROCESS (state, hash_start, loop_counter, data_counter, message_length)
    BEGIN

        CASE state IS
            WHEN idle =>
                IF (hash_start = '1') THEN
                    state_n <= load_length;
                END IF;

            WHEN load_length =>
                state_n <= load_data;

            WHEN load_data =>
                IF (data_counter >= message_length) THEN
                    state_n <= pad;
                END IF;

            WHEN pad =>
                state_n <= rotate;

            WHEN rotate =>
                state_n <= stage1_F;

            WHEN stage1_F =>
                state_n <= stage1_B;

            WHEN stage1_B =>
                IF (loop_counter = 15) THEN
                    state_n <= stage2_F;
                ELSE
                    state_n <= stage1_F;
                END IF;

            WHEN stage2_F =>
                state_n <= stage2_B;

            WHEN stage2_B =>
                IF (loop_counter = 31) THEN
                    state_n <= stage3_F;
                ELSE
                    state_n <= stage2_F;
                END IF;

            WHEN stage3_F =>
                state_n <= stage3_B;

            WHEN stage3_B =>
                IF (loop_counter = 47) THEN
                    state_n <= stage4_F;
                ELSE
                    state_n <= stage3_F;
                END IF;

            WHEN stage4_F =>
                state_n <= stage4_B;

            WHEN stage4_B =>
                IF (loop_counter = 63) THEN
                    state_n <= stage5;
                ELSE
                    state_n <= stage4_F;
                END IF;

            WHEN stage5 =>
                state_n <= stage6;

            WHEN stage6 =>
                state_n <= store_data;

            WHEN store_data =>
                state_n <= idle;

            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS fsm;

    calc : PROCESS (reset, clk, state, data_counter, loop_counter)
    BEGIN
        IF (reset = '1' AND rising_edge(clk)) THEN

            CASE state IS
                WHEN idle =>
                    g <= 0;
                    loop_counter_n <= 0;
                    data_counter <= 0;
                    hash_done <= '0';
                    -- A <= a0;
                    -- A_n <= a0;
                    -- B <= b0;
                    -- B_n <= b0;
                    -- C <= c0;
                    -- C_n <= c0;
                    -- D <= d0;
                    -- D_n <= d0;
                    -- F <= to_unsigned(0, A'length);
                WHEN load_length =>
                    message_length <= to_unsigned(data_in'length, message_length'length);

                WHEN load_data =>
                    M(data_counter TO data_counter + 31) <= unsigned(data_in);
                    IF (data_counter < message_length) THEN
                        data_counter <= data_counter + 32;
                    END IF;

                WHEN pad =>
                    M(to_integer(message_length)) <= '1';
                    M(to_integer(message_length + 1) TO 447) <= (OTHERS => '0');
                    M(448 TO 511) <=
                    swap_endianness(message_length) & "00000000000000000000000000000000";

                WHEN rotate =>
                    FOR i IN 0 TO 15 LOOP
                        M(32 * i TO 32 * i + 31) <= swap_endianness(M(32 * i TO 32 * i + 31));
                    END LOOP;

                WHEN stage1_B | stage2_B | stage3_B | stage4_B =>
                    A_n <= D;
                    B_n <= B + leftrotate(A + F + K(loop_counter) + M(g TO g + 31), s(loop_counter));
                    C_n <= B;
                    D_n <= C;
                    loop_counter_n <= loop_counter + 1;

                WHEN stage1_F =>
                    F <= (B_n AND C_n) OR (NOT B_n AND D_n);
                    g <= 32 * loop_counter_n;

                WHEN stage2_F =>
                    F <= (D_n AND B_n) OR (NOT D_n AND C_n);
                    g <= 32 * ((5 * loop_counter_n + 1) MOD 16);

                WHEN stage3_F =>
                    F <= B_n XOR C_n XOR D_n;
                    g <= 32 * ((3 * loop_counter_n + 5) MOD 16);

                WHEN stage4_F =>
                    F <= C_n XOR (B_n OR NOT D_n);
                    g <= 32 * ((7 * loop_counter_n) MOD 16);

                WHEN stage5 =>
                    A_n <= A_n + a0;
                    B_n <= B_n + b0;
                    C_n <= C_n + c0;
                    D_n <= D_n + d0;

                WHEN stage6 =>
                    A_n <= swap_endianness(A_n);
                    B_n <= swap_endianness(B_n);
                    C_n <= swap_endianness(C_n);
                    D_n <= swap_endianness(D_n);

                WHEN store_data =>
                    hash_done <= '1';
                    data_out <= STD_LOGIC_VECTOR(A) & STD_LOGIC_VECTOR(B) & STD_LOGIC_VECTOR(C) & STD_LOGIC_VECTOR(D);

                WHEN OTHERS => NULL;
            END CASE;

        END IF;
    END PROCESS calc;

END Behavioral;