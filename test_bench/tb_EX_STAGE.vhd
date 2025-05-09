----------------------------------------------------------------------------------
-- Author      : Noridel Herron
-- Date        : 5/4/2025
-- Description : Cleaned-up and complete test bench for EX_STAGE.vhd
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

--no port needed
entity tb_EX_STAGE is
end tb_EX_STAGE;

architecture sim of tb_EX_STAGE is

    component EX_STAGE
         Port ( clk           : in  std_logic;
                rst           : in  std_logic;
        
                -- Inputs from Decoder (ID)     
                reg_data1_in  : in  std_logic_vector(31 downto 0);
                reg_data2_in  : in  std_logic_vector(31 downto 0);
                op_in         : in  std_logic_vector(2 downto 0);
                f3_in         : in  std_logic_vector(2 downto 0);
                f7_in         : in  std_logic_vector(6 downto 0); 
                rd_in         : in  std_logic_vector(4 downto 0);
                store_rs2_in  : in  std_logic_vector(31 downto 0);
               
                -- Outputs to MEM stage    
                result_out    : out std_logic_vector(31 downto 0);
                Z_flag_out    : out std_logic;
                V_flag_out    : out std_logic;
                C_flag_out    : out std_logic;
                N_flag_out    : out std_logic;
               
                -- Pass reg_data2 for store instructions
                write_data_out: out std_logic_vector(31 downto 0); 
        
                -- pass through the next stage
                op_out        : out  std_logic_vector(2 downto 0);
                rd_out        : out std_logic_vector(4 downto 0) );
    end component;

    signal clk, rst : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- Internal signal
    signal reg_data1_in, reg_data2_in     : std_logic_vector(31 downto 0):= (others => '0');
    signal f3_in                          : std_logic_vector(2 downto 0) := (others => '0');
    signal f7_in                          : std_logic_vector(6 downto 0) := (others => '0');
    signal op_in                          : std_logic_vector(2 downto 0) := (others => '0');
    signal op_out                         : std_logic_vector(2 downto 0) := (others => '0');
    signal rd_in                          : std_logic_vector(4 downto 0) := (others => '0');
    signal rd_out                         : std_logic_vector(4 downto 0) := (others => '0');
    signal result_out                     : std_logic_vector(31 downto 0):= (others => '0'); 
    signal Z_flag, V_flag, C_flag, N_flag : std_logic;
    signal write_data_out, store_rs2_in   : std_logic_vector(31 downto 0);

begin

    -- Module under test
    uut: EX_STAGE port map ( clk, rst, reg_data1_in, reg_data2_in, op_in, 
                            f3_in, f7_in, rd_in, store_rs2_in, result_out, 
                            Z_flag, V_flag, C_flag, N_flag, write_data_out, op_out, rd_out);

    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
    end process;

    
    process
        -- For generating value
        variable rand_real : real;
        variable seed1 : positive := 42;
        variable seed2 : positive := 24;
        variable rand_A, rand_B : integer;
        variable rand_f3 : integer;
        
        -- Expected result
        variable expected_result : std_logic_vector(31 downto 0);
        variable expected_zf, expected_nf, expected_vf, expected_cf : std_logic := '0';
        
        -- temporary for resize
        variable sum_ext, sub_ext : unsigned(32 downto 0);
        
        -- Number of test
        variable total_tests : integer := 5000;
        
        -- Keep track of the test
        variable pass_count, fail_count : integer := 0;
        variable fail_add, fail_sub, fail_sll, fail_slt, fail_sltu, fail_xor, fail_srl, fail_sra, fail_or, fail_and : integer := 0;
        variable fail_zf, fail_nf, fail_vf, fail_cf : integer := 0;
    begin
        report "----- Simulation started -----"; -- Making sure it gets here
        wait for 100 ns;
        
        for i in 1 to total_tests loop
            -- Generate value
            -- the value plugged in can be change as long as it doesn't exceed the limit value
            uniform(seed1, seed2, rand_real);
            rand_A := integer(rand_real * 2000000000.0) - 1000000000; 
            uniform(seed1, seed2, rand_real);
            rand_B := integer(rand_real * 2000000000.0) - 1000000000;
            uniform(seed1, seed2, rand_real);
            rand_f3 := integer(rand_real * 8.0);
            if rand_f3 > 7 then rand_f3 := 0; end if;  -- make sure value doesn't exceed 7
            
            -- For case 0 and 5 since there's two options
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
            
            -- Value assignment for the unit
            reg_data1_in <= std_logic_vector(to_signed(rand_A, 32));
            reg_data2_in <= std_logic_vector(to_signed(rand_B, 32));
            f3_in <= std_logic_vector(to_unsigned(rand_f3, 3));
            
            -- Let it settle
            wait for 10 ns;

            case rand_f3 is
                when 0 =>  -- ADD/SUB
                    if f7_in = "0000000" then
                        sum_ext := resize(unsigned(to_unsigned(rand_A, 32)), 33) + 
                                   resize(unsigned(to_unsigned(rand_B, 32)), 33);
                        expected_result := std_logic_vector(sum_ext(31 downto 0));
                        
                        -- check if there's carry
                        if sum_ext(32) = '1' then expected_cf := '1'; else expected_cf := '0'; end if;
                        
                        -- check the sign of the inputs and compare it to the sign of the result,
                        -- if they are different, then, there's an overflow                   
                        if ((rand_A < 0 and rand_B < 0 and to_integer(signed(expected_result)) >= 0) or
                            (rand_A > 0 and rand_B > 0 and to_integer(signed(expected_result)) < 0)) then
                            expected_vf := '1';
                        else
                            expected_vf := '0';
                        end if;
                        
                    else
                        sub_ext := resize(unsigned(to_unsigned(rand_A, 32)), 33) - 
                                   resize(unsigned(to_unsigned(rand_B, 32)), 33);
                        expected_result := std_logic_vector(sub_ext(31 downto 0));
                        
                        -- check if there is borrow
                        if sub_ext(32) = '0' then expected_cf := '1'; else expected_cf := '0'; end if;
                        
                        -- check the sign of the inputs and compare it to the sign of the result,
                        if ((rand_A < 0 and rand_B > 0 and to_integer(signed(expected_result)) >= 0) or
                            (rand_A > 0 and rand_B < 0 and to_integer(signed(expected_result)) < 0)) then
                            expected_vf := '1';
                        else
                            expected_vf := '0';
                        end if;
                    end if;   
                    
                when 1 => -- SLL
                    expected_result := std_logic_vector(shift_left(unsigned(to_unsigned(rand_A,32)), 
                                       to_integer(unsigned(to_unsigned(rand_B,32)(4 downto 0)))));
                    expected_vf := '0';
                    expected_cf := '0';
                    
                when 2 => -- SLT
                    if signed(to_signed(rand_A,32)) < signed(to_signed(rand_B,32)) then 
                        expected_result := (31 downto 1 => '0') & '1'; 
                    else 
                        expected_result := (others => '0'); 
                    end if;
                    expected_vf := '0';
                    expected_cf := '0';
                    
                when 3 => -- SLTU
                    if unsigned(to_unsigned(rand_A,32)) < unsigned(to_unsigned(rand_B,32)) then 
                        expected_result := (31 downto 1 => '0') & '1'; 
                    else expected_result := (others => '0'); 
                    end if;
                    expected_vf := '0';
                    expected_cf := '0';
                    
                when 4 => -- XOR
                    expected_result := std_logic_vector(unsigned(to_unsigned(rand_A,32)) xor unsigned(to_unsigned(rand_B,32)));
                    expected_vf := '0';
                    expected_cf := '0';
                    
                when 5 => -- SRL/SRA
                    if f7_in = "0000000" then 
                        expected_result := std_logic_vector(shift_right(unsigned(to_unsigned(rand_A,32)), 
                                           to_integer(unsigned(to_unsigned(rand_B,32)(4 downto 0)))));
                    else 
                        expected_result := std_logic_vector(shift_right(signed(to_signed(rand_A,32)), 
                                           to_integer(unsigned(to_unsigned(rand_B,32)(4 downto 0)))));
                    end if;
                    expected_vf := '0';
                    expected_cf := '0';
                    
                when 6 =>  -- OR 
                    expected_result := std_logic_vector(unsigned(to_unsigned(rand_A,32)) or unsigned(to_unsigned(rand_B,32)));
                    expected_vf := '0';
                    expected_cf := '0';
                    
                when 7 => -- AND
                    expected_result := std_logic_vector(unsigned(to_unsigned(rand_A,32)) and unsigned(to_unsigned(rand_B,32)));
                    expected_vf := '0';
                    expected_cf := '0';
                when others => null;
            end case;
            
            -- check if the result = 0
            if expected_result = "00000000000000000000000000000000" then 
                expected_zf := '1'; 
            else 
                expected_zf := '0'; 
            end if;
            
            -- check if the result is negative
            if expected_result(31) = '1' then 
                expected_nf := '1'; 
            else 
                expected_nf := '0'; 
            end if;
            
            -- Keep track the number of pass or fail
            if result_out = expected_result and Z_flag = expected_zf and store_rs2_in = write_data_out
               and N_flag = expected_nf and V_flag = expected_vf and C_flag = expected_cf and op_in = op_out then
                pass_count := pass_count + 1;
            else
                fail_count := fail_count + 1;
                
                -- Narrow down the bugs
                if Z_flag /= expected_zf then fail_zf := fail_zf + 1; assert false report "Z flag mismatch" severity warning; end if;
                if N_flag /= expected_nf then fail_nf := fail_nf + 1; assert false report "N flag mismatch" severity warning; end if;
                if f3_in = "000" then
                    if V_flag /= expected_vf then fail_vf := fail_vf + 1; assert false report "V flag mismatch" severity warning; end if;
                    if C_flag /= expected_cf then fail_cf := fail_cf + 1; assert false report "C flag mismatch" severity warning; end if;
                end if;
                case rand_f3 is
                    when 0 => if f7_in = "0000000" then fail_add := fail_add + 1; else fail_sub := fail_sub + 1; end if;
                    when 1 => fail_sll := fail_sll + 1;
                    when 2 => fail_slt := fail_slt + 1;
                    when 3 => fail_sltu := fail_sltu + 1;
                    when 4 => fail_xor := fail_xor + 1;
                    when 5 => if f7_in = "0000000" then fail_srl := fail_srl + 1; else fail_sra := fail_sra + 1; end if;
                    when 6 => fail_or := fail_or + 1;
                    when 7 => fail_and := fail_and + 1;
                    when others => null;
                end case;
            end if;
        end loop;
        
        -- Summary report
        report "----------------------------------------------------";
        report "ALU Randomized Test Summary:";
        report "Total Tests      : " & integer'image(total_tests);
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
        report "Flag Failures:";
        report "Z flag fails : " & integer'image(fail_zf);
        report "N flag fails : " & integer'image(fail_nf);
        report "V flag fails : " & integer'image(fail_vf);
        report "C flag fails : " & integer'image(fail_cf);
        report "----------------------------------------------------";

        wait;
    end process;

end sim;
