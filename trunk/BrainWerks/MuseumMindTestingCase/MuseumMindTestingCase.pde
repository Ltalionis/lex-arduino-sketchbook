/*	The Museum of Unnatural Selection's brain!

	WARNING!WARNING this code is in beta.  Everything functions for nice input, but rigirous bug checking is needed.

	Much thanks to all the code that makes this possable
	ShiftOut: http://www.arduino.cc/en/Tutorial/ShiftOut
	The KTA-223 RelayDuino: http://www.sparkfun.com/commerce/product_info.php?products_id=9526
	MUX151: http://www.arduino.cc/playground/Code/MUX151
	And the WavShield HC lib: http://www.ladyada.net/make/waveshield/

	Copyright Lex Talionis, 2010
	
	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <string.h>
#include <ctype.h>

#include <avr/pgmspace.h>
#include <MemoryFree.h> //for debugging

#define TX 0			//Our serial terminal
#define RX 1


#define MUXS0 18		//16:1 analog multiplexer address pins (CD74HC4067)
#define MUXS1 7
#define MUXS2 8
#define MUXS3 19
#define MUXSIG 14		//16:1 analog multiplexer signal pins

int analogin[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};	//End Multiplexer


#define SHIFTDATA 9				// RelayShield IN/TI 18 /8 port shift register pins (TPIC6A596NE)
#define SHIFTCLOCK 8				// RelayShield CLOCK/TI 7
#define SHIFTLATCH 7				// RelayShield LATCH/TI 8

int shieldCount = 1;				//for cascading
byte * relayState;					//pointer to the first byte of the relayState
//byte array[shieldCount*10];		//For custom sequence, 10 flashes long  array bount is not an integer constant TOFIX

void shiftOut(byte * myDataOut, byte count);
void setupShift();
void printState();					//End RelayShield


#include "WaveUtil.h"				//The Wav Shield
#include "WaveHC.h"

#define SD0 11						
#define SD1 12
#define SD2 13
#define LCS 2
#define CLK 3
#define DI 4
#define LAT 5
#define CCS 10						//whooooohooooo! thats 8 pins!

SdReader card;    					// This object holds the information for the card
FatVolume vol;    					// This holds the information for the partition on the card
FatReader root;   					// This holds the information for the filesystem on the card
dir_t dirBuf;     					// buffer for directory reads
uint8_t dirLevel; 					// indent level for file/dir names    (for prettyprinting)
WaveHC wave;      					// This is the only wave (audio) object, since we will only play one at a time

void wavShieldSetup();
void lsR(FatReader &d);
void play(FatReader &dir);
void playAll(FatReader &dir);		//End WavShield


struct buffer * readSerial();					//command reader
void runCommand(struct buffer* pbuf);
void printCmd();

struct buffer									//command structure
{
	char cmdbuf[3];					//the command
	char filebuf[9];				//raw filename or shield number
	char relaybuf[4];				//raw extention or relay number
	byte shield;					//shield address, 0-255
	byte relay;						//relay address, 0-7 for ON and OF, 0-255 for RW
};

struct buffer cmd;								// the current command

void setup()
{
    Serial.begin(9600);
	delay(1);
	putstring_nl("Welcome to My Brain");
	putstring("Free RAM: ");       		//running out of RAM is bad
	Serial.println(freeMemory());

	setupShift();
	
	pinMode(MUXS0, OUTPUT);				//Setup the MUX
	pinMode(MUXS1, OUTPUT);
	pinMode(MUXS2, OUTPUT);
	pinMode(MUXS3, OUTPUT);
	pinMode(MUXSIG, INPUT);

//	wavShieldSetup();

	clearCmd();							// dont want to run some garbage!
	
//	putstring_nl("$>");					// What are your orders?
}

void loop() 
{
	runCommand(readSerial());	//reads the serial input and passes a command buffer to runcommand
	clearCmd();
}

/* ********************Function defs*************** */

struct buffer * readSerial()				//reads the incoming command on the serial port and writes it to rxbuf
{
//	putstring_nl("in readSerial");
	char Rxbuf[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};			//format: @CC parametr.wav (for sounds) or @CC shield.relay (for relay commands)
	int Rxptr = 0;
	while (Serial.available() > 0)										//fill up Rxbuf
	{
        delay(10);														//wait for slow as humans
		if (Rxptr <= 19)
		{
			Rxbuf[Rxptr] = Serial.read();
		}
		else
		{
			break;
		}
		if ((Rxbuf[Rxptr] != 32) && (Rxbuf[Rxptr] != '@'))				//don't save the spaces or @ symbol
		{
			Rxptr++;
		}
	}
	if (strlen(Rxbuf) > 0)												//if we got some input
	{
		int i = 2;														//counter for filebuf
		int j = 0;														//counter for relaybuf
//		Serial.print("Rxbuf: ");
		Serial.println(Rxbuf);											// could you read that back please?
//		Serial.print(" Length: ");
//		Serial.print(strlen(Rxbuf));
//		Serial.print(" Ptr: ");
//		Serial.println(Rxptr);
		cmd.cmdbuf[0] = toupper(Rxbuf[0]); 								//copy and convert to upper case
		cmd.cmdbuf[1] = toupper(Rxbuf[1]);
//		Serial.print("cmdbuf: ");
//		Serial.println(cmd.cmdbuf);
		while (i <= Rxptr && Rxbuf[i] != '.')					//read up to the '.' (filename or shield number)
		{
			cmd.filebuf[i-2] = toupper(Rxbuf[i]);
//			Serial.print(cmd.filebuf[i-2],DEC);
//			Serial.println(Rxbuf[i], BYTE);
			i++;
		}		
		cmd.filebuf[i-1] = 0;
		cmd.shield = atoi(cmd.filebuf);
		i++;															//skip '.'
//		putstring_nl("");
//		putstring("shield:");
//		Serial.println(cmd.shield, DEC);
//		putstring("nextchar:#");
//		Serial.print(i,DEC);
//		Serial.println(Rxbuf[i],BYTE);
//		putstring("relaybuf:");
		while (i <= Rxptr)										//read after the '.' (extention or relay number) to the end
		{
			cmd.relaybuf[j] = toupper(Rxbuf[i]);
//			Serial.print(cmd.relaybuf[j], BYTE);
			j++;
			i++;
		}
		cmd.relay = atoi(cmd.relaybuf);
//		Serial.println("");
//		putstring("relay:");
//		Serial.print(cmd.relay, DEC);
		putstring("Free RAM: ");       		//running out of RAM is bad
		Serial.println(freeMemory());
	}
	else
	{
		clearCmd();														//no new command, so make sure we arnt going to do anything
	}
	return &cmd;
}//we now have the two letter command code in cmdbuf and the parameter value in cmd.param, We are ready to execute

void runCommand(struct buffer * pbuf)		//execute the command passed in buf
{
//	printCmd();
	if (pbuf->cmdbuf[0] != 0)
	{
//		int cmdCode = (pbuf->cmdbuf[0]<<8) + pbuf->cmdbuf[1];
//		Serial.print(pbuf->cmdbuf);
//		putstring(" == ");
//		Serial.println(cmdCode);
		switch ((pbuf->cmdbuf[0]<<8) + pbuf->cmdbuf[1])
		{
			//*********** Turn "pbuf->shield"."pbuf->relay" ON
			case 20302:
			{
			//	printAddr(2);
			//	putstring_nl("command was ON");
				if ((pbuf->shield < shieldCount) &&
					(pbuf->shield >= 0) &&
					(pbuf->relay < 8) &&
					(pbuf->relay >= 0)) 	//if pbuf->shield and pbuf->relay are within limits
				{
					if (pbuf->filebuf[0] =='*')
					{
						if (pbuf->relaybuf[0] == 0 || pbuf->relaybuf[0] == '*') // is null
						{
							//putstring_nl("file* and relay*");
							for (int i = 0; i<shieldCount; i++)
							{
								relayState[i] = 0xFF;	//turn pbuf->relay on @ all of em
							}
						}
						else
						{
							//putstring_nl("file* and relay");
							for (int i = 0; i<shieldCount; i++)
							{
								relayState[i] = (1<<(pbuf->relay) | relayState[i]);	//turn pbuf->relay on @ each shield
							}
						}
					}
					else if (pbuf->relaybuf[0] =='*')
					{
						//putstring_nl("shield# and relay*");
						relayState[pbuf->shield] = 0xFF;	//turn on all relays @ pbuf->shield
					}
					else
					{
						//putstring_nl("shield# and relay#");
						relayState[pbuf->shield] = (1<<(pbuf->relay) | relayState[pbuf->shield]);// turn pbuf->relay on @ pbuf->shield
					}
					shiftOut(relayState, shieldCount);
				}
				else
				{
					//putstring_nl("out of range");
				}
				printState();
			}
			break;
			case 20294:						//******************************* Turn "pbuf->shield"."pbuf->relay" OFF
			{
				//printAddr(2);
				//putstring_nl("Command was OFF");
				if ((pbuf->shield < shieldCount) &&
					(pbuf->shield >= 0) &&
					(pbuf->relay < 8) &&
					(pbuf->relay >= 0)) 	//if pbuf->shield and pbuf->relay are within limits
				{
					if (pbuf->filebuf[0] =='*')
					{
						if (pbuf->relaybuf[0] == 0 || pbuf->relaybuf[0] == '*') // is wild or null
						{
							//putstring_nl("shield* and relay*");
							for (int i = 0; i<shieldCount; i++)
							{
								relayState[i] = 0x00;	//turn pbuf->relay on @ all of em
							}
						}
						else
						{
							//putstring_nl("shield* and relay#");
							for (int i = 0; i<shieldCount; i++)
							{
								relayState[i] = (~(1<<(pbuf->relay)) & relayState[i]);	//turn pbuf->relay off @ each shield
							}
						}
					}
					else if (pbuf->relaybuf[0] =='*')
					{
						//putstring_nl("shield# and relay*");
						relayState[pbuf->shield] = 0x00;	//turn on all relays of @ pbuf->shield
					}
					else
					{
						//putstring_nl("shield# and relay#");
						relayState[pbuf->shield] = (~(1<<(pbuf->relay)) & relayState[pbuf->shield]);// turn pbuf->relay off @ pbuf->shield
					}
					shiftOut(relayState, shieldCount);
				}
				else
				{
					//putstring_nl("out of range");
				}
				printState();
			}    
			break;
			case 21079:						//******************************* Binary write pbuf->relay to the relay state at pbuf->shield
			{																//(only supports first 8 shields because both are interpertaded as binary numbers)
				//printAddr(2);
//				putstring("cmdbuf: ");
//				Serial.print(pbuf->cmdbuf);
				if (pbuf->filebuf[0] == '*' && 
					(pbuf->relay <= 255) &&
					(pbuf->relay >= 0))										//all shields
				{
					for (byte i = 0; i<shieldCount; i++)
					{
						relayState[i] = pbuf->relay;
					}
				}
				else if ((pbuf->shield <= 255) &&
						(pbuf->shield >= 0) &&
						(pbuf->relay <= 255) &&
						(pbuf->relay >= 0))
				{															//inside our limits?
//					putstring("shield: ");
//					Serial.print(pbuf->shield);
//					putstring("relay: ");
//					Serial.print(pbuf->relay);
					for (byte i = 0; i < 8 ; i++)							//for each of the eight shields
					{
						if (pbuf->shield & 1<<i)							//which shield?
						{
							relayState[i] = pbuf->relay;
						}
					}
				}
				else
				{
//					Serial.print(pbuf->shield);
//					putstring("."
//					Serial.print(pbuf->relay);
//					Serial.println(": not valid");
				}
				shiftOut(relayState, shieldCount);								
				printState();
			}
			break;
			case 21075:						//******************************* Relay Status
			{
//				printAddr(2);
//				putstring_nl("command was RELAY STATUS");
//				putstring_nl("buffer:");
//				putstring("shield: ");
//				Serial.println(pbuf->shield, DEC);
//				putstring("relay: ");
//				Serial.println(pbuf->relay, DEC);
				shiftOut(relayState, shieldCount);									//write the status to make sure you are giving current data			
				if ((pbuf->shield <= shieldCount) &&
					(pbuf->shield >= 0) &&
					(pbuf->relay < 8) &&
					(pbuf->relay >= 0 ))	//if we want a specific relay and shield
				{
					Serial.print(pbuf->shield, DEC);
					putstring(".");
					Serial.print(pbuf->relay, DEC);
					putstring(":");
					Serial.println((1<<pbuf->relay) == ((1<<pbuf->relay) & relayState[pbuf->shield]));
				}
				else
				{
					printState();
				}
			}
			break;
			case 21076:						//*******************************	Relay Test routine
			{
				//printAddr(2);
				if (pbuf->filebuf[0] == '*' || pbuf->filebuf[0] == 0)									//test all shields
				{
					for (byte shield = 0; shield < shieldCount; shield++)		//for every shield
					{
//					putstring("Shield: ");
					Serial.print(shield,DEC);
					putstring(".");
						for (byte i=0; i<8; i++)								//for each relay
						{
							Serial.print(i,DEC);
							relayState[shield] = 1<<i;
							shiftOut(relayState, shieldCount);
							delay(1000);
						}
					relayState[shield] = 0x00;
					putstring_nl("");
//					Serial.print(pbuf->cmdbuf);
					}
				}
				else if ((pbuf->shield >= 0) && (pbuf->shield < shieldCount))		//bpuf->shield is a specific shield
				{
//					putstring("Shield: ");
					Serial.print(pbuf->shield,DEC);
					putstring(".");
					for (byte i=0; i<8; i++)
					{
						Serial.print(i, DEC);
						relayState[pbuf->shield] = 1<<i;
						shiftOut(relayState, shieldCount);
						delay(1000);
					}
					relayState[pbuf->shield] = 0x00;
					putstring_nl("");
//					Serial.print(pbuf->cmdbuf);
				}
				else
				{
//					putsting_nl("Shield out of range");
				}
//			putstring_nl(" Test Complete");
			printState();
			shiftOut(relayState, shieldCount);
			}
			break;
			case 18771:						//******************************* Input Status
			{
				//printAddr(2);
				if (pbuf->filebuf[0] =='*')
				{
					for (int i=0; i<16; i++)
					{
						digitalWrite(MUXS0, (1 == (1 & i)));
						digitalWrite(MUXS1, (2 == (2 & i)));
						digitalWrite(MUXS2, (4 == (4 & i)));
						digitalWrite(MUXS3, (8 == (8 & i)));
						analogin[i] = analogRead(MUXSIG);
						Serial.print(analogin[i]);
						putstring(" ");
					}
					putstring_nl("");
				}
				else if (pbuf->shield <= 16 && pbuf->shield > 0)
				{
	/*				Serial.print("param: ");
					Serial.print(pbuf->param);
					int mux0 = (1 == (B0001 & (pbuf->param-1)));
					int mux1 = (2 == (B0010 & (pbuf->param-1)));
					int mux2 = (4 == (B0100 & (pbuf->param-1)));
					int mux3 = (8 == (B1000 & (pbuf->param-1)));
					Serial.print(" mux addy: ");
					Serial.print(mux0, DEC);
					Serial.print(mux1, DEC);
					Serial.print(mux2, DEC);
					Serial.print(mux3, DEC);
					Serial.print(" ");							*/
					digitalWrite(MUXS0, (1 == (1 & pbuf->shield-1)));
					digitalWrite(MUXS1, (2 == (2 & pbuf->shield-1)));
					digitalWrite(MUXS2, (4 == (4 & pbuf->shield-1)));
					digitalWrite(MUXS3, (8 == (8 & pbuf->shield-1)));
					analogin[pbuf->shield-1] = analogRead(MUXSIG);
					Serial.println(analogin[pbuf->shield-1]);
				}
				else
				{
				//Serial.println("input out of range");
				}
			}
			break;
			case 20563:						//******************************* Play a Sound, (string) pbuf->valbuf is a filename in 8.3
			{
	//			putstring("valbuf: ");
	//			Serial.print(pbuf->valbuf);
				if (pbuf->filebuf[0] =='*')
				{
	//				putstring_nl("Play All");
					playAll(root);
					root.rewind();
				}
				else
				{
	//				putstring("Play: ");
	//				Serial.println(pbuf->filebuf);
					playFile(pbuf->filebuf);
					root.rewind();
				}
				//printAddr(2);
	//			putstring_nl("Done playing");
			}
			break;
			case 19539:						//******************************* Lists All files recursively
			{
				//printAddr(2);
				putstring_nl("Files Found:");
				lsR(root);
	//			root.rewind();
			}
			break;
	//		putstring ("$>");			
			clearCmd();				//don't want to run the same thing twice
			}
	}
}

/* ************************RelayShield********************* */
void shiftOut(byte * myDataOut, byte count) //Writes data to the shift register
{											//count is the number of shields, myDataOut is an array of count bytes
//	putstring_nl("In shiftOut:");

	pinMode(SHIFTCLOCK, OUTPUT);
	pinMode(SHIFTDATA, OUTPUT);
	pinMode(SHIFTLATCH, OUTPUT);

	digitalWrite(SHIFTDATA, 0); // next relay state (High == on)
	digitalWrite(SHIFTCLOCK, 0); // clock for relay states (TPIC6A596NE reads on upstroke of clock pin)
	digitalWrite(SHIFTLATCH, 0); // pushes state to the outputs	

//	putstring("count: ");
//	Serial.println(count, DEC);

	for (int j = count-1; j >=0; j--) 	//for each shield
	{
//		Serial.print(j,DEC);
//		putstring("ram:");
//		Serial.println(myDataOut[j],BIN);
//		Serial.print(j,DEC);
//		putstring("ser:");
		for (int i=7; i >= 0; i--)				//MSB first
		{
			digitalWrite(SHIFTCLOCK, 0);							//sero the clock
//			Serial.print((myDataOut[j] & (1<<i)) && (1<<i),BIN);	//write the bit we are shifting out to the term
			digitalWrite(SHIFTDATA, (myDataOut[j] & (1<<i)) && (1<<i));			//write our data to our datapin
			delayMicroseconds(50);
			digitalWrite(SHIFTCLOCK, 1);							//shifts bits on upstroke of clock pin  
			delayMicroseconds(50);      
			digitalWrite(SHIFTDATA, 0);								//zero the data pin after shift to prevent bleed through
		}
//		putstring_nl("");
	}
	//stop shifting
	digitalWrite(SHIFTCLOCK, 0);
	digitalWrite(SHIFTLATCH, HIGH);					//data is written when latch goes high
	delayMicroseconds(50);	
	digitalWrite(SHIFTLATCH, LOW);					//latch idles low
}

void setupShift()					//initilizes the shift register
{
	pinMode(SHIFTDATA, OUTPUT);			//Setup the Shift Reg
	pinMode(SHIFTLATCH, OUTPUT);
	pinMode(SHIFTCLOCK, OUTPUT);
	digitalWrite(SHIFTCLOCK, LOW);		//SRCK and RCK Idle low
	digitalWrite(SHIFTLATCH, LOW); 
	digitalWrite(SHIFTDATA, LOW);
	
	putstring_nl("How many relay shields are attached?");
	char countString[4] = {0,0,0,0};									//shouldn't need more than 3 digits.
	int ptr = 0;														//2048 relays?  well code it yourself :P
//	putstring_nl("entering wait");
	while (Serial.available() == 0)										//wait for input
	{
		delay(1);
	}
//	putstring_nl("exited wait");
	while (Serial.available() > 0)										//fill up the countString
	{
//		putstring_nl("reading char");
        delay(10);														//wait for slow as humans
		countString[ptr] = Serial.read();
		ptr++;
	}
	putstring("Shields: ");
	shieldCount = atoi(countString);
	Serial.println(shieldCount);
	relayState = (byte *) malloc(shieldCount * sizeof(byte));		//allocate shieldCount bytes for the relayState
	if (relayState == NULL)
	{
		/* Memory could not be allocated, the program should handle the error here as appropriate. */
		putstring("Malloc Failed! Free RAM: ");       //running out of RAM is bad
		Serial.println(freeMemory());
		while(1) {}									//do nothing, new code is needed
	}
	else
	{
//		putstring_nl("malloc ok");
		for (int i = 0; i<shieldCount; i++)
		{
//			putstring("relayState: ");
//			Serial.print(relayState[i],BIN);
			relayState[i] = 0x00;
		}
	}
	shiftOut(relayState, shieldCount); 					//turn all relays off, for safety!
//	putstring("leaving relaysetup");
}

/* **********************End RelayShield****************** */

void clearCmd()
{
	cmd.cmdbuf[0] = 0;
	cmd.cmdbuf[1] = 0;
	cmd.cmdbuf[2] = 0;
	cmd.filebuf[0] = 0;
	cmd.filebuf[1] = 0;
	cmd.filebuf[2] = 0;
	cmd.filebuf[3] = 0;
	cmd.filebuf[4] = 0;
	cmd.filebuf[5] = 0;
	cmd.filebuf[6] = 0;
	cmd.filebuf[7] = 0;
	cmd.filebuf[8] = 0;
	cmd.relaybuf[0] = 0;
	cmd.relaybuf[1] = 0;
	cmd.relaybuf[2] = 0;
	cmd.relaybuf[3] = 0;
	cmd.shield=0;
	cmd.relay=0;
//	printCmd();
}

void printCmd()
{
	Serial.println("Current Command");
	Serial.print("cmd.cmdbuf: ");
	Serial.println(cmd.cmdbuf);
	Serial.print("cmd.filebuf: ");
	Serial.println(cmd.filebuf);
	Serial.print("cmd.relaybuf: ");
	Serial.println(cmd.relaybuf);
	Serial.print("cmd.relay: ");
	Serial.println(cmd.relay, BIN);
	Serial.print("cmd.shield: ");
	Serial.println(cmd.shield, DEC);
}

void printState()
{
	putstring_nl("State:");
	for (int i = 0; i<shieldCount; i++)
	{
		Serial.print(i);
		putstring(":");
		for (byte j = 7; (0 == relayState[i]>>j) && ( 0 != j); j--)	//print leading zeros
		{
			putstring("0");
		}
		Serial.print(relayState[i],BIN);
		putstring_nl("");
	}
}

/* ***************************** Wav Shield Functions ***************************** */

void wavShieldSetup(void)
{
	pinMode(LCS, OUTPUT);			//*********************** Wav shield setup *************************//
	pinMode(CLK, OUTPUT);
	pinMode(DI, OUTPUT);
	pinMode(LAT, OUTPUT);

//	if (!card.init(true))		//play with 4 MHz spi if 8MHz isn't working for you
	if (!card.init())			//play with 8 MHz spi (default faster!)
	{  
		putstring_nl("Card init. failed!");  // Something went wrong, lets print out why
		sdErrorCheck();
		while(1);                            // then 'halt' - do nothing!
	}
  
//	enable optimize read - some cards may timeout. Disable if you're having problems
	card.partialBlockRead(true);
  
	// Now we will look for a FAT partition!
	uint8_t part;
	for (part = 0; part < 5; part++)     // we have up to 5 slots to look in
	{
		if (vol.init(card, part)) 
		break;                             // we found one, lets bail
	}
	if (part == 5)                        // if we ended up not finding one  :(
	{
		putstring_nl("No valid FAT partition!");
		sdErrorCheck();      // Something went wrong, lets print out why
		while(1);                            // then 'halt' - do nothing!
	}
	// Lets tell the user about what we found
	putstring("Using partition ");
	Serial.print(part, DEC);
	putstring(", type is FAT");
	Serial.println(vol.fatType(),DEC);     // FAT16 or FAT32?

	// Try to open the root directory
	if (!root.openRoot(vol)) {
		putstring_nl("Can't open root dir!"); // Something went wrong,
		while(1);                             // then 'halt' - do nothing!
	}

	// Whew! We got past the tough parts.
	dirLevel = 0;
	// Print out all of the files in all the directories.
//	putstring_nl("Files found:");
//	lsR(root);

	root.rewind(); // Need to rewind after you go though the dir!
										/**************************Wav shield setup is done ************************/
}

void sdErrorCheck(void)
{
	if (!card.errorCode()) return;
	putstring("\n\rSD I/O error: ");
	Serial.print(card.errorCode(), HEX);
	putstring(", ");
	Serial.println(card.errorData(), HEX);
	while(1);
}

void printName(dir_t &dir)		//print dir_t name field. The output is 8.3 format, so like SOUND.WAV or FILENAME.DAT
{
  for (uint8_t i = 0; i < 11; i++) {     // 8.3 format has 8+3 = 11 letters in it
    if (dir.name[i] == ' ')
        continue;         // dont print any spaces in the name
    if (i == 8) 
        putstring(".");           // after the 8th letter, place a dot
    Serial.print(dir.name[i]);      // print the n'th digit
  }
  if (DIR_IS_SUBDIR(dir)) 
    putstring("/");       // directories get a / at the end
}

void lsR(FatReader &d)	 //list recursively - possible stack overflow if subdirectories too nested
{
	int8_t r;                     // indicates the level of recursion

  while ((r = d.readDir(dirBuf)) > 0) {     // read the next file in the directory 
    // skip subdirs . and ..
    if (dirBuf.name[0] == '.') 
      continue;
    
    for (uint8_t i = 0; i < dirLevel; i++) 
      putstring(" ");        // this is for prettyprinting, put spaces in front
    printName(dirBuf);          // print the name of the file we just found
    putstring_nl("");           // and a new line
    
    if (DIR_IS_SUBDIR(dirBuf)) {   // we will recurse on any direcory
      FatReader s;                 // make a new directory object to hold information
      dirLevel += 2;               // indent 2 spaces for future prints
      if (s.open(vol, dirBuf)) 
        lsR(s);                    // list all the files in this directory now!
      dirLevel -=2;                // remove the extra indentation
    }
  }
  d.rewind();
  sdErrorCheck();                  // are we doign OK?
}

void playAll(FatReader &dir)  //play recursively - possible stack overflow if subdirectories too nested
{
	FatReader file;
	while (dir.readDir(dirBuf) > 0)    // Read every file in the directory one at a time
	{
		// skip . and .. directories
		if (dirBuf.name[0] == '.') 
		continue;
    
//		printName(dirBuf);           // prints the file we are working with

//		for (uint8_t i = 0; i < dirLevel; i++) 
//			Serial.print(' ');       // this is for prettyprinting, put spaces in front

		if (!file.open(vol, dirBuf))       // open the file in the directory
		{
			putstring_nl("file.open failed");  // something went wrong :(
			while(1);                            // halt
		}
    
		if (file.isDir())                     // check if we opened a new directory
		{
//			putstring("Subdir: ");
//			printName(dirBuf);
//			dirLevel += 2;                       // add more spaces
			// play files in subdirectory
			playAll(file);                         // recursive!
//			dirLevel -= 2;    
		}
		else
		{
			// Aha! we found a file that isnt a directory
			putstring("Playing "); printName(dirBuf);  putstring_nl("");     // print it out
			if (!wave.create(file))            // Figure out, is it a WAV proper?
			{
				putstring(" Not a valid WAV");     // ok skip it
			}
			else
			{
//				Serial.println();                  // Hooray it IS a WAV proper!
				wave.play();                       // make some noise!
       
				while (wave.isplaying)           // playing occurs in interrupts, so we print dots in realtime
				{
//					putstring(".");
					delay(100);
				}
				sdErrorCheck();                    // everything OK?
//        if (wave.errors)Serial.println(wave.errors);     // wave decoding errors
			}
		}
	}
}

void playFile(char *name)				//play the file, "name"
{
	FatReader file;
//	putstring("In playFile, name:");
//	Serial.println(name);
	if (wave.isplaying)					// already playing something, so stop it!
	{
		wave.stop(); 					// stop it
	}
	if (!file.open(root, name))
	{
		putstring("Couldn't open file ");
		Serial.println(name);
		return;
	}
//  putstring("file is open? "); Serial.print(file.isOpen(), DEC);
	if (!wave.create(file))
	{
		putstring_nl("Not a valid WAV"); return;
	}
//	ok time to play!
	wave.play();
	while (wave.isplaying)
	{
	//do nothing
	}
}