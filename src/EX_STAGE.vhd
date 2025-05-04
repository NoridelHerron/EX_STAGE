----------------------------------------------------------------------------------
-- Author      : Noridel Herron
-- Date        : [Your Date]
-- Description : Execution (EX) Stage with EX/MEM pipeline register
--               - Registers all inputs for stability and forwarding
--               - Supports future hazard detection and instruction tracing
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EX_STAGE is
    Port (
        clk           : in  std_logic;
        rst           : in  std_logic;

        -- Inputs from ID/EX
        instr_in      : in  std_logic_vector(31 downto 0);
        reg_data1_in  : in  std_logic_vector(31 downto 0);
        reg_data2_in  : in  std_logic_vector(31 downto 0);
        f3_in         : in  std_logic_vector(2 downto 0);
        f7_in         : in  std_logic_vector(6 downto 0);
        reg_write_in  : in  std_logic;
        mem_read_in   : in  std_logic;
        mem_write_in  : in  std_logic;     

        -- Outputs to MEM stage
        instr_out     : out std_logic_vector(31 downto 0);
        result_out    : out std_logic_vector(31 downto 0);
        Z_flag_out    : out std_logic;
        V_flag_out    : out std_logic;
        C_flag_out    : out std_logic;
        N_flag_out    : out std_logic;
        reg_write_out : out std_logic;
        mem_read_out  : out std_logic;
        mem_write_out : out std_logic     
    );
end EX_STAGE;

architecture behavior of EX_STAGE is

    component ALU
        Port (
            A, B       : in std_logic_vector(31 downto 0);
            Ci_Bi      : in std_logic;
            f3         : in std_logic_vector(2 downto 0);
            f7         : in std_logic_vector(6 downto 0);
            result     : out std_logic_vector(31 downto 0);
            Z_flag     : out std_logic;
            V_flag     : out std_logic;
            C_flag     : out std_logic;
            N_flag     : out std_logic
        );
    end component;

    -- Internal pipeline registers (EX/MEM)
    signal instr_reg      : std_logic_vector(31 downto 0);
    signal result_reg     : std_logic_vector(31 downto 0);
    signal Z_flag_reg     : std_logic;
    signal V_flag_reg     : std_logic;
    signal C_flag_reg     : std_logic;
    signal N_flag_reg     : std_logic;
    signal reg_write_reg  : std_logic;
    signal mem_read_reg   : std_logic;
    signal mem_write_reg  : std_logic;

    -- ALU wires
    signal alu_result     : std_logic_vector(31 downto 0);
    signal Z_flag_wire    : std_logic;
    signal V_flag_wire    : std_logic;
    signal C_flag_wire    : std_logic;
    signal N_flag_wire    : std_logic;
    signal Ci_Bi          : std_logic := '0';

begin

    -- ALU instance
    alu_inst : ALU port map (reg_data1_in, reg_data2_in, Ci_Bi, f3_in, f7_in, alu_result, Z_flag_wire, V_flag_wire, C_flag_wire, N_flag_wire);

    -- Pipeline register for EX/MEM
    process(clk, rst)
    begin
        if rst = '1' then
            instr_reg      <= (others => '0');
            result_reg     <= (others => '0');
            Z_flag_reg     <= '0';
            V_flag_reg     <= '0';
            C_flag_reg     <= '0';
            N_flag_reg     <= '0';
            reg_write_reg  <= '0';
            mem_read_reg   <= '0';
            mem_write_reg  <= '0';
           
        elsif rising_edge(clk) then
            instr_reg      <= instr_in;
            result_reg     <= alu_result;
            Z_flag_reg     <= Z_flag_wire;
            V_flag_reg     <= V_flag_wire;
            C_flag_reg     <= C_flag_wire;
            N_flag_reg     <= N_flag_wire;
            reg_write_reg  <= reg_write_in;
            mem_read_reg   <= mem_read_in;
            mem_write_reg  <= mem_write_in;          
        end if;
    end process;

    -- Output assignments
    instr_out     <= instr_reg;
    result_out    <= result_reg;
    Z_flag_out    <= Z_flag_reg;
    V_flag_out    <= V_flag_reg;
    C_flag_out    <= C_flag_reg;
    N_flag_out    <= N_flag_reg;
    reg_write_out <= reg_write_reg;
    mem_read_out  <= mem_read_reg;
    mem_write_out <= mem_write_reg;

end behavior;
