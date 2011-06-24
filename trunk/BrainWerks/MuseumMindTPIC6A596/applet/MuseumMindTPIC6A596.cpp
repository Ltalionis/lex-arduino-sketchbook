

/*
	The Museum of Unnatural Selection's brain!
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

#include <string.h> //Use the string library
#include <ctype.h>
#include <EEPROM.h>

#include <FatReader.h>
#include <SdReader.h>
#include <avr/pgmspace.h>
#include "WaveUtil.h" //Use the WaveHC library
#include "WaveHC.h"

#include <MemoryFree.h> //for debugging


#define TX 0
#define RX 1
#define MUXS0 18		//16:1 analog multiplexer address pins (CD74HC4067)
#define MUXS1 7
#define MUXS2 8
#define MUXS3 19
#define MUXSIG 14		//16:1 analog multiplexer signal pin
#define SHIFTDATA 14	// 8 port shift register pins (TPIC6A596NE)
#define SHIFTLATCH 16
#define SHIFTCLOCK 15
#define SD0 11			//The Wav Sheild
#define SD1 12
#define SD2 13
#define LCS 2
#define CLK 3
#define DI 4
#define LAT 5
#define CCS 10			//whooooohooooo! thats 8 pins!



#include "WProgram.h"
void setup();
void loop();
void readserial();
void runcommand();
void shiftOut(byte myDataOut);
void printaddr(char x);
void clearcmd();
void sdErrorCheck(void);
void playfile(char *name);
char Rxbuf[20];		
char adrbuf[3], cmdbuf[3], valbuf[13];
int param;

int Unitaddress = 0;	//from EEPROM
//int Unitbaud;
int analogin[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};	//Used by the 16:1 Multiplexer
const int relaycount = 8;			//Used by the shift register
byte relaystate = 0x00;
byte array[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};		// For custom array
SdReader card;    // This object holds the information for the card
FatVolume vol;    // This holds the information for the partition on the card
FatReader root;   // This holds the information for the filesystem on the card
uint8_t dirLevel; // indent level for file/dir names    (for prettyprinting)
dir_t dirBuf;     // buffer for directory reads
WaveHC wave;      // This is the only wave (audio) object, since we will only play one at a time

void printaddr(char x);
//void setbaud(char Mybaud);
void readserial();
void runcommand();
void shiftOut(byte myDataOut);

void lsR(FatReader &d);			//for wav sheild
void play(FatReader &dir);
void playall(FatReader &dir);

void setup()
{
    Serial.begin(9600);
	delay(1);
	putstring_nl("Welcome to My Brain");
	putstring("Free RAM: ");       //running out of RAM is bad
	Serial.println(freeMemory());

	pinMode(SHIFTDATA, OUTPUT);			//Setup the Shift Reg
	pinMode(SHIFTLATCH, OUTPUT);
	pinMode(SHIFTCLOCK, OUTPUT);
	digitalWrite(SHIFTCLOCK, LOW);		//SRCK and RCK Idle low
	digitalWrite(SHIFTLATCH, LOW); 
	shiftOut(0x00); 					//turn all relays off, for safety!

	pinMode(MUXS0, OUTPUT);				//Setup the MUX
	pinMode(MUXS1, OUTPUT);
	pinMode(MUXS2, OUTPUT);
	pinMode(MUXS3, OUTPUT);
	pinMode(MUXSIG, INPUT);

	Unitaddress = EEPROM.read(0);
	putstring("Address: ");
	printaddr(1);
//	Unitbaud = EEPROM.read(1);
//	setbaud(Unitbaud);

	pinMode(LCS, OUTPUT);			//*********************** Wav sheild setup *************************//
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
										//**************************Wav sheild setup is done ************************//
	
//	putstring ("$>");					// What are your orders?
}

void loop() 
{
	readserial();
	runcommand();
	clearcmd();
}

/* ********************Function defs*************** */

void readserial()		//reads the incoming command on the serial port and writes it to rxbuf
{
	char Rxbuf[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};			//format: @AA CC parametr.wav
	int Rxptr = 0;
	while (Serial.available() > 0)							//fill up Rxbuf
	{
        	delay(10);
		Rxbuf[Rxptr] = Serial.read();
		if ((Rxbuf[Rxptr] != 32) && (Rxbuf[Rxptr] != '@')) 	//don't save the spaces or @ symbol
		{
			Rxptr++;
		}
	}
	if (strlen(Rxbuf) > 0)
	{
//		Rxbuf[Rxptr+1] = 0;									//nullterm
		Serial.println(Rxbuf);									// could you read that back please?
//		Serial.print("Rxbuf: ");
//		Serial.print(Rxbuf);
//		Serial.print(" Length: ");
//		Serial.print(strlen(Rxbuf));
//		Serial.print(" Ptr: ");
//		Serial.println(Rxptr);
		
		adrbuf[0] = Rxbuf[0];
		adrbuf[1] = Rxbuf[1];
		adrbuf[2] = 0; //null terminate
//		Serial.print("rxaddress: ");
//		Serial.println(rxaddress, DEC);
		cmdbuf[0] = toupper(Rxbuf[2]); //copy and convert to upper case
		cmdbuf[1] = toupper(Rxbuf[3]);
		cmdbuf[2] = 0;
//		Serial.print("cmdbuf: ");
//		Serial.println(cmdbuf);
//		valbuf[0] = Rxbuf[4];
		for (int i = 4 ; i <= Rxptr ; i++)
		{
			valbuf[i-4] = toupper(Rxbuf[i]);
//			Serial.println(valbuf[i-4], DEC);
		}
		valbuf[Rxptr-3] = 0;
		param = atoi(valbuf);
//		putstring("valbuf:");
//		Serial.println(valbuf);
//		Serial.print("parameter: ");
//		Serial.println(param, DEC); //
	}
}//we now have the address in rxaddress, the two letter command code in cmdbuf and the parameter value in param, We are ready to execute

void runcommand()		//execute the command in rxbuf
{
	if ((atoi(adrbuf) == Unitaddress) || ((Rxbuf[0] == '*') && (Rxbuf[1] == '*')) ) //** is wildcard address, all units respond
	{
		if (strcmp(cmdbuf,"ON")==0)                        			//turn relay param ON
		{
			//'Print "command was ON"
			if ((param <= relaycount) && (param >= 0)) 
			{
				if (valbuf[0] =='*')							//wildcard
				{
					relaystate = 0xFF;
					//digitalWrite(SHIFTLATCH, HIGH);
					shiftOut(0xFF);		//All relays on
					//digitalWrite(SHIFTLATCH, LOW);
					//Serial.print("relaystate: ");
					//Serial.println(relaystate,BIN);
				}
				else
				{
					relaystate = ((1<<(param-1)) | relaystate);  // turn bit param-1 on
					//digitalWrite(SHIFTLATCH, HIGH);
					shiftOut(relaystate);
					//digitalWrite(SHIFTLATCH, LOW);
					//Serial.print("relaystate: ");
					//Serial.println(relaystate,BIN);
				}
				printaddr(2);
				Serial.println(relaystate,BIN);
			}
			else
			{
				//'Print "out of range"
			}
		}

		if (strcmp(cmdbuf,"OF")==0)                          		//turn relay param OFF
		{
			//'Print "command was OFF"
			if ((param <= relaycount) && (param >= 0)) 
			{
				if (valbuf[0] =='*')
				{
					relaystate = 0x00;
					//digitalWrite(SHIFTLATCH, LOW);
					shiftOut(0x00);				//All relays off
					//digitalWrite(SHIFTLATCH, HIGH);
				}
				else
				{		
					relaystate = (~(1<<(param-1)) & relaystate);		//turn bit param-1 off
					//digitalWrite(SHIFTLATCH, LOW);
					shiftOut(relaystate);
					//digitalWrite(SHIFTLATCH, HIGH);
				}
			}
			else
			{
				//'Print "out of range"
			}
			printaddr(2);
			Serial.println(relaystate,BIN);
		}    
             
		if (strcmp(cmdbuf,"RW")==0)                       			//Write param to the relay state
		{
//			putstring("valbuf: ");
//			Serial.print(valbuf);
			if (valbuf[0] == '*')
			{
				relaystate = 0xFF;
				shiftOut(relaystate);
			}
			else if ((param <= 255) && (param >= 0)) 
			{
//				putstring("param: ");
//				Serial.print(param);
				relaystate = param;
				shiftOut(relaystate);
			} else {
				//Serial.print(param);
				//Serial.println(": param out of range");
			}
			printaddr(2);
			Serial.println(relaystate,BIN);
		}
		
		if (strcmp(cmdbuf,"RS")==0)                           		// Relay Status
		{
			//'Print "command was RELAY STATUS"
			//digitalWrite(SHIFTLATCH, LOW);					//write the status to make sure you are giving current data
			shiftOut(relaystate);
			//digitalWrite(SHIFTLATCH, HIGH);
			printaddr(2);
			if ((param > 0) && (param <= relaycount))
			{				
				Serial.println((1<<param-1) == ((1<<param-1) & relaystate));
			}
			else 								//wildcard
			{
				Serial.println(relaystate, BIN);
			}
		}

		if (strcmp(cmdbuf,"RT")==0)									//	Relay Test routine
		{
		printaddr(2);
			do
			{
				for (int i=0; i<8; i++)
				{
					Serial.print(i+1);
					shiftOut(1<<i);
					delay(1000);
				}
				putstring_nl("");
				readserial();
//				Serial.print(cmdbuf);
			} while ((strcmp(cmdbuf,"RT")==0) &&(valbuf[0]=='*'));
		//putstring_nl(" Test Complete");
		shiftOut(relaystate);          //it should actually run the command right now, because there is a new command in the Rxbuf
		}
			
		if (strcmp(cmdbuf,"IS")==0)                            		// Input Status
		{
			printaddr(2);
			if (valbuf[0] =='*')
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
			else if (param <= 16 && param > 0)
			{
/*				Serial.print("param: ");
				Serial.print(param);
				int mux0 = (1 == (B0001 & (param-1)));
				int mux1 = (2 == (B0010 & (param-1)));
				int mux2 = (4 == (B0100 & (param-1)));
				int mux3 = (8 == (B1000 & (param-1)));
				Serial.print(" mux addy: ");
				Serial.print(mux0, DEC);
				Serial.print(mux1, DEC);
				Serial.print(mux2, DEC);
				Serial.print(mux3, DEC);
				Serial.print(" ");							*/
				digitalWrite(MUXS0, (1 == (1 & param-1)));
				digitalWrite(MUXS1, (2 == (2 & param-1)));
				digitalWrite(MUXS2, (4 == (4 & param-1)));
				digitalWrite(MUXS3, (8 == (8 & param-1)));
				analogin[param-1] = analogRead(MUXSIG);
				Serial.println(analogin[param-1]);
			}
			else
			{
			//Serial.println("param out of range");
			}
		}

		if (strcmp(cmdbuf,"SA")==0)                            		// Set Address and save to EEP
		{
			putstring_nl("command was Set Address");
			if ((param >= 0) && (param <= 99))
			{
				Unitaddress = param;   //make it the address
				EEPROM.write(0, Unitaddress);//save to eep                       
			}
			else
			{
				//putstring_nl("out of range");
			}
		printaddr(1);
		}

/*		if (strcmp(cmdbuf,"SB")==0)                              	// Set Baud and save to EEP              {
		{      
			//'Print "command was Set Baud"
			if ((param > 0) && (param <= 10))
			{
				Unitbaud = param;   
				EEPROM.write(1, Unitbaud);//save to eep
				setbaud(Unitbaud);// start serial port
				printaddr(2);
				Serial.println(Unitbaud);
			}
			else
			{
				//'Print "out of range"
			}
		}*/

		if (strcmp(cmdbuf,"PS")==0)									//Play a Sound, (string) valbuf is a filename in 8.3
		{															//param is garbage
//			Serial.print(valbuf);
			if (valbuf[0] =='*')
			{
//				putstring_nl("Play All");
				playall(root);
				root.rewind();
			}
			else
			{
//				putstring("Play: ");
//				Serial.println(valbuf);
				playfile(valbuf);
				root.rewind();
			}
		printaddr(2);
//		putstring_nl("Done playing");
		}
		
		if (strcmp(cmdbuf,"LS")==0)									//Lists All files recursively
		{
			printaddr(2);
			putstring_nl("Files Found:");
			lsR(root);
//			root.rewind();
		}

		if (cmdbuf[0]=='A')											//enters param as the Array state at row cmdbuf[1]
		{
			putstring("Command is A");
			array[cmdbuf[1]-48] = param;
			Serial.println(cmdbuf[1]-48);
			for (int i = 0; i < 10; i++ )
			{
				Serial.println(array[i],BIN);
				shiftOut(array[i]);
				delay(500);
			}
			relaystate = array[9];
		}
//	putstring ("$>");
	}//end address				
//	clearcmd();
}

/*void setbaud(char Mybaud)
{
   switch (Mybaud)
   {
    case 1 : Serial.begin(1200);
      break;
    case 2 : Serial.begin(2400);
      break;     
    case 3 : Serial.begin(4800);
      break;
    case 4 : Serial.begin(9600);
      break;
    case 5 : Serial.begin(14400);
      break;
    case 6 : Serial.begin(19200);
      break;
    case 7 : Serial.begin(28800);
      break;
    case 8 : Serial.begin(38400);
      break;
    case 9 : Serial.begin(57600);
      break;
    case 10 : Serial.begin(115200);
      break;
    default:  Serial.begin(9600);
      break;
   }
}*/

void shiftOut(byte myDataOut) //Writes data to the shift register
{
	// This shifts 8 bits out MSB first, 
	//on the rising edge of the clock,
	//clock idles low
	pinMode(SHIFTCLOCK, OUTPUT);
	pinMode(SHIFTDATA, OUTPUT);
	pinMode(SHIFTLATCH, OUTPUT);

	//clear everything out just in case to
	//prepare shift register for bit shifting
	digitalWrite(SHIFTDATA, 0);
	digitalWrite(SHIFTCLOCK, 0);
	digitalWrite(SHIFTLATCH, 0); // Data is written to the outputs when latch goes high
	
	//for each bit in the byte myDataOut
	//NOTICE THAT WE ARE COUNTING DOWN in our for loop
	//This means that %00000001 or "1" will go through such
	//that it will be pin Q0 that lights. 
	for (int i=7; i>=0; i--)
	{
		digitalWrite(SHIFTCLOCK, 0);

		//if the value passed to myDataOut and a bitmask result 
		// true then... so if we are at i=6 and our value is
		// %11010100 it would the code compares it to %01000000 
		digitalWrite(SHIFTDATA, myDataOut & (1<<i));			//write our data to our datapin
		delayMicroseconds(50);
		digitalWrite(SHIFTCLOCK, 1);							//shifts bits on upstroke of clock pin  
        delayMicroseconds(50);      
		digitalWrite(SHIFTDATA, 0);								//zero the data pin after shift to prevent bleed through
	}

	//stop shifting
	digitalWrite(SHIFTCLOCK, 0);
	digitalWrite(SHIFTLATCH, HIGH);					//data is written when latch goes high
	delayMicroseconds(50);	
	digitalWrite(SHIFTLATCH, LOW);					//latch idles low
}

void printaddr(char x) //if x=1 then it prints an enter, if x=2 then it prints a space after the address
{
	if (Unitaddress < 10)
	{
		putstring("#0");
		Serial.print(Unitaddress, DEC);
	}
	else
	{
		putstring("#"); 
		Serial.print(Unitaddress, DEC);
	}
	switch(x)
	{
		case 1:
			putstring_nl(""); //print enter
			break;
		case 2:
			putstring(" "); //print space
			break;  
	}
}

void clearcmd()
{
	cmdbuf[0]=0;
	cmdbuf[1]=0;
	adrbuf[0]=0;
	adrbuf[1]=0;
	param=0;
//	Serial.print("rxaddress: ");
//	Serial.println(rxaddress, DEC);
//	Serial.print("cmdbuf: ");
//	Serial.println(cmdbuf);
//	Serial.print("parameter: ");
//	Serial.println(param, DEC); //   'Print "parameter: " ; param
}


/* ***************************** Wav Sheild Functions ***************************** */

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

void playall(FatReader &dir)  //play recursively - possible stack overflow if subdirectories too nested
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
			playall(file);                         // recursive!
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

void playfile(char *name) {		//play the file, "name"
  FatReader file;
//  putstring("In playfile, name:");
//  Serial.println(name);
  if (wave.isplaying) {// already playing something, so stop it!
    wave.stop(); // stop it
  }
  if (!file.open(root, name)) {
    putstring("Couldn't open file "); Serial.print(name); return;
  }
//  putstring("file is open? "); Serial.print(file.isOpen(), DEC);
  if (!wave.create(file)) {
    putstring_nl("Not a valid WAV"); return;
  }
  // ok time to play!
  wave.play();
  while (wave.isplaying){};
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

