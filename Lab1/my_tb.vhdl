library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

-- entity declaration
entity my_tb is
end entity;

-- architecture start
architecture my_tb_arch of my_tb is

  -- component declarations, for example
  component wrapper is
    generic (WL : positive);
    port(
      clk  : in  std_logic;
      a    : in  std_logic_vector(WL-1 downto 0);
      b    : in  std_logic_vector(WL-1 downto 0);
      cin  : in  std_logic;
      cout : out std_logic;
      sum  : out std_logic_vector(WL-1 downto 0));
  end component;

  -- constant and type declarations, for example
  constant WL         : positive := 32;
    -- adder wordlength
  constant CYCLES     : positive := 1000;
    -- number of test vectors to load
  type word_array is array (0 to CYCLES-1) of std_logic_vector(WL-1 downto 0);
    -- type used to store WL-bit test vectors for CYCLES cycles
  file LOG : text open write_mode is "mylog.log";
    -- file to which you can write information
	
  constant a_file	: string := "A.tv";
  constant b_file	: string := "B.tv";
  constant exp_file	: string := "ExpectedOutput.tv";
  
  -- functions
  function to_std_logic (char : character) return std_logic is
    variable result : std_logic;
  begin
    case char is
      when '0'    => result := '0';
      when '1'    => result := '1';
      when 'x'    => result := '0';
      when others => assert (false) report "no valid binary character read" severity failure;
    end case;
    return result;
  end to_std_logic;

  function load_words (file_name : string) return word_array is
    file object_file : text open read_mode is file_name;
    variable memory  : word_array;
    variable L       : line;
    variable index   : natural := 0;
    variable char    : character;
  begin
    while not endfile(object_file) loop
      readline(object_file, L);
      for i in WL-1 downto 0 loop
        read(L, char);
        memory(index)(i) := to_std_logic(char);
      end loop;
      index := index + 1;
    end loop;
    return memory;
  end load_words;
  
   -- testbench code
  
  --What is a reasonable period??? Is 10 ns reasonable? I'm not sure
  constant PERIOD	: positive := 10 ns;
  
  signal clk	: std_logic := '0'; --Clk starts at zero
  signal a		: std_logic_vector(WL-1 downto 0);
  signal b		: std_logic_vector(WL-1 downto 0);
  --signal cin	: std_logic;
  signal cout	: std_logic;
  signal sum	: std_logic_vector(WL-1 downto 0);
  
  signal a_array 	: word_array := load_words(a_file);
  signal b_array 	: word_array := load_words(b_file);
  signal exp_array 	: word_array := load_words(exp_file);
  
  begin
  
  clk <= not clk after PERIOD / 2;
  
  adder : component wrapper
	generic map	(	WL => WL)
	port map	(	clk => clk,
					a => a,
					b => b,
					cin => '0',
					cout => cout,
					sum => sum);

  verification_process : process
    --variable index 		: natural := 0;
    variable L     		: line;
	begin
	
	write(L, string'("Populating a from: ") & a_file);
	writeline(LOG,L);
	write(L, string'("Populating b from: ") & b_file);
	writeline(LOG,L);
	write(L, string'("Comparing the output with: ") & exp_file);
	writeline(LOG,L);
	
	--The loop goes one more than CYCLES since the sum is delayed two rising clock edges from a change in a and b
	for index in 0 to CYCLES loop
		--if rising_edge(clk) then
			if index /= CYCLES then
				a <= a_array(index);
				b <= b_array(index);
			end if;
			wait until rising_edge(clk); --Will this trigger immediately? If not it should work
			--Skip checking the first time since the sum is delayed by two rising clock edges
			if index /= 0 and sum /= exp_array(index-1) then
				write(L, string'"----------");
				writeLine(LOG, L);
				write(L, string'"Wrong result with test vector index: " & index-1);
				writeLine(LOG, L);
				write(L, string'"a: " & a_array(index-1));
				write(L, string'" b: " & b_array(index-1));
				writeLine(LOG, L);
				write(L, string'"Expected: " & exp_array(index-1) & string'" Recieved: " & sum);
				writeLine(LOG, L);
			end if;
		--end if;
	end loop;
	write(L, string'("----------"));
	writeLine(LOG,L);
	write(L, string'("Testbench run complete"));
	writeLine(LOG, L);
	end loop;
	
    -- ...
		--write(L, string'("index = "));
		--write(L, index);
		--writeline(LOG, L);  	-- example on how you can write a mix of string text and variables
								-- from your testbench to file LOG, which was opened above
						
end architecture;