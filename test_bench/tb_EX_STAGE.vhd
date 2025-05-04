----------------------------------------------------------------------------------
-- Author      : Noridel Herron
-- Date        : 5/4/2025
-- Description : Test bench for EX_STAGE.vhd
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tb_EX_STAGE is
end tb_EX_STAGE;

architecture sim of tb_EX_STAGE is

    component EX_STAGE
         Port (
            clk           : in  std_logic;
            rst           : in  std_logic;
            instr_in      : in  std_logic_vector(31 downto 0);
            reg_data1_in  : in  std_logic_vector(31 downto 0);
            reg_data2_in  : in  std_logic_vector(31 downto 0);
            f3_in         : in  std_logic_vector(2 downto 0);
            f7_in         : in  std_logic_vector(6 downto 0);
            reg_write_in  : in  std_logic;
            mem_read_in   : in  std_logic;
            mem_write_in  : in  std_logic;
            rd_in         : in  std_logic_vector(4 downto 0);
            instr_out     : out std_logic_vector(31 downto 0);
            result_out    : out std_logic_vector(31 downto 0);
            Z_flag_out    : out std_logic;
            V_flag_out    : out std_logic;
            C_flag_out    : out std_logic;
            N_flag_out    : out std_logic;
            reg_write_out : out std_logic;
            mem_read_out  : out std_logic;
            mem_write_out : out std_logic;
            rd_out        : out std_logic_vector(4 downto 0)
        );
    end component;

    signal clk, rst : std_logic := '0';
    constant clk_period : time := 10 ns;

    signal instr : std_logic_vector(31 downto 0);
    signal reg_data1_in, reg_data2_in : std_logic_vector(31 downto 0);
    signal f3_in : std_logic_vector(2 downto 0);
    signal f7_in : std_logic_vector(6 downto 0);
    signal reg_write_in, mem_read_in, mem_write_in : std_logic := '0';
    signal rd_in  : std_logic_vector(4 downto 0);
    signal rd_out : std_logic_vector(4 downto 0);
    signal instr_out, result_out : std_logic_vector(31 downto 0);
    signal Z_flag_out, V_flag_out, C_flag_out, N_flag_out : std_logic;
    signal reg_write_out, mem_read_out, mem_write_out : std_logic;

begin

    uut: EX_STAGE port map (
        clk, rst,
        instr, reg_data1_in, reg_data2_in, f3_in, f7_in,
        reg_write_in, mem_read_in, mem_write_in, rd_in,
        instr_out, result_out,
        Z_flag_out, V_flag_out, C_flag_out, N_flag_out,
        reg_write_out, mem_read_out, mem_write_out, rd_out
    );

    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
    end process;

     stim_proc : process
        variable total_tests      : integer := 1000;
        variable seed1, seed2     : positive := 42;
        variable rand_real        : real;
        variable rand_A, rand_B   : integer;
        variable rand_f3, rand_f7 : integer;
        variable expected_result  : std_logic_vector(31 downto 0);
        variable i : integer := 0;
        variable pass_count, fail_count : integer := 0;
        variable fail_add, fail_sub, fail_sll, fail_slt, fail_sltu : integer := 0;
        variable fail_xor, fail_srl, fail_sra, fail_or, fail_and : integer := 0;
        variable fail_instr_out, fail_reg_write_out, fail_mem_read_out, fail_mem_write_out : integer := 0;
    begin
        rst <= '1'; wait for 2*clk_period; rst <= '0';

        for i in 0 to total_tests-1 loop
            uniform(seed1, seed2, rand_real);
            rand_A := integer(rand_real * 2000000000.0) - 1000000000;

            uniform(seed1, seed2, rand_real);
            rand_B := integer(rand_real * 2000000000.0) - 1000000000;

            uniform(seed1, seed2, rand_real);
            rand_f3 := integer(rand_real * 8.0);
            if rand_f3 > 7 then rand_f3 := 0; end if;

            f3_in <= std_logic_vector(to_unsigned(rand_f3, 3));

            if rand_f3 = 0 or rand_f3 = 5 then
                uniform(seed1, seed2, rand_real);
                if rand_real > 0.5 then
                    f7_in <= "0000000";
                else
                    f7_in <= "0100000";
                end if;
            else
                f7_in <= "0000000";
            end if;

            reg_data1_in <= std_logic_vector(to_signed(rand_A, 32));
            reg_data2_in <= std_logic_vector(to_signed(rand_B, 32));
            instr        <= std_logic_vector(to_unsigned(i, 32));
            rd_in <= std_logic_vector(to_unsigned(i mod 32, 5));
            reg_write_in <= '1';
            mem_read_in  <= '0';
            mem_write_in <= '0';

            wait for clk_period;

            case f3_in is
                when "000" =>
                    if f7_in = "0000000" then
                        expected_result := std_logic_vector(signed(reg_data1_in) + signed(reg_data2_in));
                    else
                        expected_result := std_logic_vector(signed(reg_data1_in) - signed(reg_data2_in));
                    end if;
                when "001" =>
                    expected_result := std_logic_vector(shift_left(unsigned(reg_data1_in), to_integer(unsigned(reg_data2_in(4 downto 0)))));
                when "010" =>
                    if signed(reg_data1_in) < signed(reg_data2_in) then
                        expected_result := (31 downto 1 => '0') & '1';
                    else
                        expected_result := (others => '0');
                    end if;
                when "011" =>
                    if unsigned(reg_data1_in) < unsigned(reg_data2_in) then
                        expected_result := (31 downto 1 => '0') & '1';
                    else
                        expected_result := (others => '0');
                    end if;
                when "100" =>
                    expected_result := std_logic_vector(unsigned(reg_data1_in) xor unsigned(reg_data2_in));
                when "101" =>
                    if f7_in = "0000000" then
                        expected_result := std_logic_vector(shift_right(unsigned(reg_data1_in), to_integer(unsigned(reg_data2_in(4 downto 0)))));
                    else
                        expected_result := std_logic_vector(shift_right(signed(reg_data1_in), to_integer(unsigned(reg_data2_in(4 downto 0)))));
                    end if;
                when "110" =>
                    expected_result := std_logic_vector(unsigned(reg_data1_in) or unsigned(reg_data2_in));
                when "111" =>
                    expected_result := std_logic_vector(unsigned(reg_data1_in) and unsigned(reg_data2_in));
                when others =>
                    expected_result := (others => '0');
            end case;


            wait for clk_period;

            if result_out = expected_result and instr_out = instr and 
               reg_write_out = reg_write_in and mem_read_out = mem_read_in and mem_write_out = mem_write_in then
                pass_count := pass_count + 1;
            else
                fail_count := fail_count + 1;
                report "TEST FAIL!" severity warning;
                report "    F3             : " & integer'image(to_integer(unsigned(f3_in)));
                report "    F7             : " & integer'image(to_integer(unsigned(f7_in)));
                report "    Input A        : " & integer'image(to_integer(signed(reg_data1_in)));
                report "    Input B        : " & integer'image(to_integer(signed(reg_data2_in)));
                report "    Expected Output: " & integer'image(to_integer(unsigned(expected_result)));
                report "    Actual Output  : " & integer'image(to_integer(unsigned(result_out)));

                 if instr_out /= instr then
                    report "    MISMATCH: instr_out /= instr_in" severity warning;
                    fail_instr_out := fail_instr_out + 1;
                end if;             
                if rd_out /= rd_in then
                    report "    MISMATCH: rd_out /= rd_in" severity warning;
                end if;
                if reg_write_out /= reg_write_in then
                    report "    MISMATCH: reg_write_out /= reg_write_in" severity warning;
                    fail_reg_write_out := fail_reg_write_out + 1;
                end if;
                if mem_read_out /= mem_read_in then
                    report "    MISMATCH: mem_read_out /= mem_read_in" severity warning;
                    fail_mem_read_out := fail_mem_read_out + 1;
                end if;
                if mem_write_out /= mem_write_in then
                    report "    MISMATCH: mem_write_out /= mem_write_in" severity warning;
                    fail_mem_write_out := fail_mem_write_out + 1;
                end if;
                
                case f3_in is
                    when "000" => 
                        if f7_in = "0000000" then 
                            fail_add := fail_add + 1; 
                        else 
                            fail_sub := fail_sub + 1; 
                        end if;
                    when "001" => fail_sll := fail_sll + 1;
                    when "010" => fail_slt := fail_slt + 1;
                    when "011" => fail_sltu := fail_sltu + 1;
                    when "100" => fail_xor := fail_xor + 1;
                    when "101" => 
                        if f7_in = "0000000" then 
                            fail_srl := fail_srl + 1; 
                        else 
                            fail_sra := fail_sra + 1; 
                        end if;
                    when "110" => fail_or := fail_or + 1;
                    when "111" => fail_and := fail_and + 1;
                    when others => null;
                end case;
            end if;

        end loop;

        report "----------------------------------------------------";
        report "ALU Randomized Test Summary:";
        report "Total Tests      : " & integer'image(i);
        report "Total Passes     : " & integer'image(pass_count);
        report "Total Failures   : " & integer'image(fail_count);
        report "Fails per Operation:";
        report "ADD  fails: " & integer'image(fail_add);
        report "SUB  fails: " & integer'image(fail_sub);
        report "SLL  fails: " & integer'image(fail_sll);
        report "SLT  fails: " & integer'image(fail_slt);
        report "SLTU fails: " & integer'image(fail_sltu);
        report "XOR  fails: " & integer'image(fail_xor);
        report "SRL  fails: " & integer'image(fail_srl);
        report "SRA  fails: " & integer'image(fail_sra);
        report "OR   fails: " & integer'image(fail_or);
        report "AND  fails: " & integer'image(fail_and);
        report "instr_out mismatches     : " & integer'image(fail_instr_out);
        report "reg_write_out mismatches : " & integer'image(fail_reg_write_out);
        report "mem_read_out mismatches  : " & integer'image(fail_mem_read_out);
        report "mem_write_out mismatches : " & integer'image(fail_mem_write_out);
        report "----------------------------------------------------";

        wait;
    end process;

end sim;
