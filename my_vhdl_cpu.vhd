LIBRARY ieee;  
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY my_vhdl_cpu IS
	PORT (DIN						:IN STD_LOGIC_VECTOR( 15 DOWNTO 0);
			Resetn, Clock, Run 	:IN STD_LOGIC;
			Done 						:BUFFER STD_LOGIC;
			BusWires 				:BUFFER STD_LOGIC_VECTOR( 15 DOWNTO 0));
END my_vhdl_cpu;


ARCHITECTURE Behavior OF my_vhdl_cpu IS
	--declare components
	
	-- regn
COMPONENT regn
	PORT (R	 	      :IN 		STD_LOGIC_VECTOR(15 DOWNTO 0);
			Rin, Clock 	:IN      STD_LOGIC;
			Q				:BUFFER	STD_LOGIC_VECTOR(15 DOWNTO 0));
END COMPONENT;

COMPONENT Ireg
	PORT( R		      :IN 		STD_LOGIC_VECTOR(1 TO 9);
			Rin, Clock 	:IN      STD_LOGIC;
			Q				:BUFFER	STD_LOGIC_VECTOR(1 TO 9));
END COMPONENT;


-- Multiplexer
COMPONENT  my_mux
PORT( R0, R1, R2, R3, 
		R4, R5,	R6, R7, 
		G, D 					:IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
		RSEL 					:IN   STD_LOGIC_VECTOR(0 TO 7);
		GSEL, DSEL 			:IN 	STD_LOGIC;
		MUX_OUT				:OUT	STD_LOGIC_VECTOR(15 DOWNTO 0));
END COMPONENT;


-- upcounter
COMPONENT  upcount
	PORT( Clear		: IN STD_LOGIC; 
			Clock 	: IN STD_LOGIC;
			Q 			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END COMPONENT;


-- Adder

COMPONENT  adder_sub
	PORT( A,B	      :IN 		STD_LOGIC_VECTOR(15 DOWNTO 0);
			Add_Sub		:IN      STD_LOGIC;
			Result		:OUT		STD_LOGIC_VECTOR(15 DOWNTO 0));
END COMPONENT;



COMPONENT control_unit 
	PORT( IR						:IN  STD_LOGIC_VECTOR(1 TO 9);
			RUN					:IN  STD_LOGIC;
			RESET					:IN  STD_LOGIC;
			Tstep_Q				:IN  STD_LOGIC_VECTOR(0 TO 1);
			IRin					:OUT  STD_LOGIC;
			Ain, Gin		 		:OUT  STD_LOGIC;
			Xreg 					:OUT  STD_LOGIC_VECTOR(0 TO 7);
			Gout, Dout 			:OUT  STD_LOGIC;
			Yreg 					:OUT  STD_LOGIC_VECTOR(0 TO 7);
			Clear					:OUT  STD_LOGIC;
			Add_Sub				:OUT  STD_LOGIC;
			Done					:OUT  STD_LOGIC);

END COMPONENT;
	
		
	--declare signals
	
	signal R0,R1,R2,R3,R4,R5,R6,R7, Adata, Gdata, ADDERdata: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal IR: STD_LOGIC_VECTOR (1 TO 9);
	signal Tstep_Q : STD_LOGIC_VECTOR(1 DOWNTO 0);
	signal Clear: STD_LOGIC;
	signal AddSub: STD_LOGIC;
	signal IRin, Ain,  Gin:STD_LOGIC;
	signal Rin,  Rout: STD_LOGIC_VECTOR(0 TO 7);
	signal Gout, Dout :STD_LOGIC;
	
	
	


	
BEGIN
	
	
	Tstep: 		  upcount PORT MAP (Clear, Clock, Tstep_Q);
	IRegister:    IReg 	 PORT MAP (DIN(15 DOWNTO 7) , IRin, Clock, IR);
	
	cntrUnt:	control_unit PORT MAP( IR, Run,	Resetn, Tstep_Q,
												IRin,	
												Ain, Gin,
												Rin,
												Gout, Dout, 
												Rout, 
												Clear,					
												AddSub,
												Done);

	
	
	mux0: my_mux PORT MAP  (R0, R1, R2, R3, R4, R5, R6, R7, 
									Gdata, DIN, 				
									Rout,					
									Gout, Dout,
									BusWires);
									
	my_add_sub: adder_sub PORT MAP (Adata, BusWires, AddSub, ADDERdata);								
	
	
	reg_0: regn PORT MAP (BusWires, Rin(0), Clock, R0); 
	reg_1: regn PORT MAP (BusWires, Rin(1), Clock, R1);
	reg_2: regn PORT MAP (BusWires, Rin(2), Clock, R2);
	reg_3: regn PORT MAP (BusWires, Rin(3), Clock, R3);
	reg_4: regn PORT MAP (BusWires, Rin(4), Clock, R4);
	reg_5: regn PORT MAP (BusWires, Rin(5), Clock, R5);
	reg_6: regn PORT MAP (BusWires, Rin(6), Clock, R6);
	reg_7: regn PORT MAP (BusWires, Rin(7), Clock, R7);
	
	reg_A: regn PORT MAP (BusWires,  Ain, Clock, Adata);
	reg_G: regn PORT MAP (ADDERdata, Gin, Clock, Gdata);
	
	--instansiate other registers and the adder/subtracter unit
	--de1inetI1e bus
END Behavior;
	
	
-- Define entity up counter	
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY upcount IS
	PORT( Clear				:IN STD_LOGIC; 
			Clock 			:IN STD_LOGIC;
			Q 					:OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END upcount;


ARCHITECTURE Behavior OF upcount IS
	SIGNAL Count : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN
	PROCESS (Clock)
	BEGIN
		IF (Clock'EVENT AND Clock = '1') THEN
			IF (Clear = '1') THEN
					Count <= "00";
			ELSE
				Count <= Count + 1;
			END IF;
		END IF;
	END PROCESS;
	Q <= Count;
END Behavior;	


	
-- Define entity  register	
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY regn IS
	GENERIC(n: INTEGER := 16);
	PORT( R  	      :IN 		STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			Rin, Clock 	:IN      STD_LOGIC;
			Q				:OUT	STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regn;

ARCHITECTURE Behavior OF regn IS
BEGIN
	PROCESS (Clock)
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Rin = '1' THEN  
				Q <= R;
			END IF;
		END IF;	
	END PROCESS;
END Behavior;		



-- Define entity  Instruction Register	
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Ireg IS
	PORT( R	 	      :IN 		STD_LOGIC_VECTOR(1 TO 9);
			Rin, Clock 	:IN      STD_LOGIC;
			Q				:OUT		STD_LOGIC_VECTOR(1 TO 9));
END Ireg;

ARCHITECTURE Behavior OF Ireg IS
BEGIN
	PROCESS (Clock)
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Rin = '1' THEN  
				Q <= R;
			END IF;
		END IF;	
	END PROCESS;
END Behavior;	


-- Define entity  multiplexer
LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY my_mux IS
	PORT( R0, R1, R2, R3, 
			R4, R5,R6, R7,
			G, D 				:IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
			RSEL 					:IN   STD_LOGIC_VECTOR(0 TO 7);
			GSEL, DSEL  		:IN 	STD_LOGIC;
			MUX_OUT				:OUT	STD_LOGIC_VECTOR(15 DOWNTO 0));
END my_mux;

ARCHITECTURE Behavior OF my_mux IS
BEGIN
	PROCESS (RSEL, GSEL, DSEL)
	BEGIN
		IF DSEL = '1' THEN 
			MUX_OUT <= D;
		ELSIF GSEL = '1' THEN
			MUX_OUT <= G;
		ELSE
			CASE RSEL IS
				WHEN "10000000" => MUX_OUT <= R0;
				WHEN "01000000" => MUX_OUT <= R1;
				WHEN "00100000" => MUX_OUT <= R2;
				WHEN "00010000" => MUX_OUT <= R3;
				WHEN "00001000" => MUX_OUT <= R4;
				WHEN "00000100" => MUX_OUT <= R5;
				WHEN "00000010" => MUX_OUT <= R6;
				WHEN "00000001" => MUX_OUT <= R7;
				WHEN others => MUX_OUT <="0000000000000000";
			END CASE;
		END IF;	
	END PROCESS;
END Behavior;	


-- Define entity  adder_subtractor	
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY adder_sub IS
	GENERIC(n: INTEGER := 16);
	PORT( A,B	      :IN 		STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			Add_Sub		:IN      STD_LOGIC;
			Result		:OUT		STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END adder_sub;

ARCHITECTURE Behavior OF adder_sub IS
BEGIN
	PROCESS(A,B, Add_Sub)
	BEGIN
		IF (Add_Sub = '1') THEN
			Result <= A;
		ELSE
			Result <= B;
		END IF;
	END PROCESS;	
	
END Behavior;	


-- Define entity 3to8 decoder	
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY control_unit IS
	PORT( IR						:IN  STD_LOGIC_VECTOR(1 TO 9);
			RUN					:IN  STD_LOGIC;
			RESET					:IN  STD_LOGIC;
			Tstep_Q				:IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			IRin					:OUT  STD_LOGIC; 
			Ain, Gin		 		:OUT  STD_LOGIC;
			Xreg 					:OUT  STD_LOGIC_VECTOR(0 TO 7);
			Gout, Dout 			:OUT  STD_LOGIC;
			Yreg 					:OUT  STD_LOGIC_VECTOR(0 TO 7);
			Clear					:OUT  STD_LOGIC;
			Add_Sub				:OUT  STD_LOGIC;
			Done					:OUT  STD_LOGIC);
END control_unit;

ARCHITECTURE Behavior OF control_unit IS
	
COMPONENT dec3to8
		PORT( W  	:IN 	STD_LOGIC_VECTOR(2 DOWNTO 0);
				En 	:IN   STD_LOGIC;
				Y		:OUT	STD_LOGIC_VECTOR(0  TO 7));
END COMPONENT;



signal I: STD_LOGIC_VECTOR(0 TO 2);


	
BEGIN	
	
	Xdec : dec3to8 PORT MAP( IR(4 tO 6), '1', Xreg);
	Ydec : dec3to8 PORT MAP( IR(7 tO 9), '1', Yreg);
	
	
	I <= IR (1 TO 3);
		
	controlsignals: PROCESS (Tstep_Q, I)
	BEGIN
		--specify initial  values
		
		IF (RESET = '0') THEN 
			Dout <='0';
			Gout <= '0';
			IRin <= '0';	
			Clear <= '0';
			Add_Sub <= '0';
			Ain <= '0';
			Gin <= '0';
			Done <= '0';
		END IF;
		
		
		
		CASE Tstep_Q IS
			WHEN "00" => -- store DIN In IR as long as Tsep_Q = O
					IRin <= '1';
					Ain  <= '0';
					Gin  <= '0';
					Done <= '0';
					Gout <= '0';
					Dout <='0';
					Add_Sub <= '0';	
			WHEN "01" =>  --define signals in time step TI
				CASE I IS
					WHEN "000" =>  --mv Rx,Ry
						Done <= '1';
						IRin <= '0';
					WHEN "001" =>  --mvi Rx,DIN
						Dout <= '1';
						Done <= '1';
						IRin <= '0';
					WHEN "010" =>   --add Rx, Ry 
						Ain  <= '1';
						IRin <= '0';
					WHEN "011" =>   --sub Rx, Ry
						Ain <= '1';
						IRin <= '0';
					WHEN others => 
						Done <='1';
				END CASE;
			WHEN "10" =>  -- define signals in time step T2
				CASE I IS
					WHEN "000" =>  --mv Rx,Ry
						Done <= '0';
					WHEN "001" =>  --mvi Rx,DIN
						Done <= '0';
						Dout <= '0';
					WHEN "010" =>   --add Rx, Ry 
						Gin  <= '1';
						Ain <= '0';
					WHEN "011" =>   --sub Rx, Ry
						Gin <= '1';
						Ain <= '0';
						Add_Sub <= '1';
					WHEN others => 
						Done <='1';
				END CASE;
			WHEN "11" =>  -- define signals in time step T3
				CASE I IS
					WHEN "000" =>  --mv Rx,Ry
						Done <= '0';
					WHEN "001" =>  --mvi Rx,DIN
						Done <= '0';
						Dout <= '0';
					WHEN "010" =>   --add Rx, Ry 
						Gout  <= '1';
						Gin <= '0';
						Done <= '1';
					WHEN "011" =>   --sub Rx, Ry
						Gin <= '0';
						Gout  <= '1';
						Ain <= '0';
						Add_Sub <= '0';
						Done <= '1';
					WHEN others => 
						Done <='1';
				END CASE;
			WHEN others =>
				Done <= '1';
		END CASE;
	END PROCESS;
END Behavior;



-- Define entity 3to8 decoder	
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dec3to8 IS
	PORT( W  	:IN 	STD_LOGIC_VECTOR(2 DOWNTO 0);
			En 	:IN   STD_LOGIC;
			Y		:OUT	STD_LOGIC_VECTOR(0  TO 7));
END dec3to8;

ARCHITECTURE Behavior OF dec3to8 IS
BEGIN
	PROCESS (W, En)
	BEGIN
		IF (En = '1') THEN
			CASE W IS 
				WHEN "000" => Y <= "10000000";
				WHEN "001" => Y <= "01000000";
				WHEN "010" => Y <= "00100000";
				WHEN "011" => Y <= "00010000";
				WHEN "100" => Y <= "00001000";
				WHEN "101" => Y <= "00000100";
				WHEN "110" => Y <= "00000010";
				WHEN "111" => Y <= "00000001";
			END CASE;	
		ELSE
			Y <= "00000000";
		END IF;
	END PROCESS;
END Behavior;		
	

