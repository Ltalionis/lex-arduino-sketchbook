/*	Copyright Lex Talionis, 2010
	
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

#include <TimerOne.h>

// digital pin assignments
#define TX 0			//the serial terminal
#define RX 1

				//Switch Opto
#define PRIMARY_PROPANE 2	//control panel switches
#define ALCOHOL 3
#define IGN 4
#define POWDER_FEED 5              

				//Motor Opto
#define MOTOR_ENABLE 7		//may not be needed
#define MOTOR1 8		//motor PWM outputs
#define MOTOR2 9
#define MOTOR3 10


#define SHIFTLATCH 11		// RelayShield LATCH
#define SHIFTCLOCK 12		// RelayShield CLOCK
#define SHIFTIN 13		// RelayShield IN

// analog pin assignments
#define POTM 0			// Master pot
#define POT1 1			// pot for motorN
#define POT2 2
#define POT3 3

#define MAX_CHANGE 10		//max change in PWM output per loop in uSec
#define MAX_SPEED 1675		//max ontime of PWM output in uSec
#define MAX_TWEAK 64

// Pin Arrays
byte switches[] = {PRIMARY_PROPANE,IGN,ALCOHOL,POWDER_FEED};	// pins attached to the multipin

int masterPot = 0;
int pot[] = {POTM,POT1,POT2,POT3};				// control panel pots on analog pins 1,2,3
int oldPot[] = {POTM, POT1,POT2,POT3};
int potBuffer = 0;
int motor[] = {MOTOR1, MOTOR2, MOTOR3};
int dutyCycle[] = {1000,1000,1000};			//duty cycle for each motor in uSec
int __motor[] = {MOTOR1, MOTOR2, MOTOR3};		//shadow copy for the intrupt to read
int __dutyCycle[] = {1000,1000,1000};

//Shift reg junk
byte shieldCount = 1;		
byte relayState[] = {0};
void shiftOut(byte * myDataOut, byte count);
void setupShift();

/*********************** BODY ****************************/
void setup()
{
	setupShift();
    
	Serial.begin(9600);	
	for(byte i = 0;  i != 3; i++)	//control panel inputs
	{
		pinMode(switches[i], INPUT);
		digitalWrite(switches[i], HIGH); //sets internal pullup resistor
	}

	for(byte i = 0;  i != 2; i++)	//Motor PWM Pins
	{
		pinMode(motor[i], OUTPUT);
		digitalWrite(motor[i], LOW);
		
	}
		
	Timer1.initialize(20000);
	Timer1.attachInterrupt(manualpwm);
	delay(1);
	Serial.println("Welcome to My Brain");
	Serial.print("Free RAM at boot: ");       		//running out of RAM is bad
	Serial.println(freeMemory());
}

void loop()
{
	potsToMotor();
	readPanel();
}

/********************* FUNCTIONS ***********************/

void readPanel()
{
  //byte switches[] = {PRIMARY_PROPANE,IGN,ALCOHOL,POWDER_FEED};
  //byte relayState[0] = {Propane 1, Propane 2, Propane 3, Alch, Powder feed, ign1, ign2, ign 3};
  // A 0 on the digital read represents a pressed switch, a 1 or TRUE is a non-pressed switch
  if (digitalRead(PRIMARY_PROPANE))
  {
  relayState[0] &= 0x1F; // {0,0,0,1,1,1,1,1} turns off the first three, leaving the rest   
  } else {
  relayState[0] |= 0xE0; // {1,1,1,0,0,0,0,0} turns on the first three, leaving the rest  

  }
  
   if (digitalRead(ALCOHOL))
  {
   relayState[0] &= 0xE7; // {1,1,1,0,0,1,1,1} turns off the 4th one
  } else {
   relayState[0] |= 0x18; // {0,0,0,1,1,0,0,0} turns on the 4th one, leaving the rest
  }
  
  if (digitalRead(IGN))
  {
   relayState[0] &= 0xF8; // {1,1,1,1,1,0,0,0} turns off the last three
  } else {

   relayState[0] |= 0x07; // {0,0,0,0,0,1,1,1} turns on the last three, leaving the rest
  }
    
 /* if (digitalRead(POWDER_FEED))
  {
    relayState[0] &= 0xF7; // {1,1,1,1,0,1,1,1} turns off the 5th one
  } else {
   relayState[0] |= 0x08; // {0,0,0,0,1,0,0,0} turns on the 5th one, leaving the rest
  }*/ 


// input check
	Serial.print("P");
	Serial.print(digitalRead(PRIMARY_PROPANE));
	Serial.print("A");
	Serial.print(digitalRead(ALCOHOL)); 
 	Serial.print("I");
	Serial.print(digitalRead(IGN));
/*	Serial.print("F");
	Serial.print(digitalRead(POWDER_FEED));
 */

// output check
      Serial.print("\t State:");
      paddedPrint(relayState[0]);
        Serial.println();

        shiftOut(relayState, 1);
}

void potsToMotor()		//Writes the current state of the pots to the motor
{
	for (byte j = 0; j != 3; j++)		//For each pot
	{
		oldPot[j] = pot[j];
		for (byte i = 0; i != 15; i++)	//Read each one 16 times
		{
			potBuffer += analogRead(j);
		}
		pot[j] = potBuffer >> 4;	//and devide by 16 for an average

		if ( (pot[j] - oldPot[j]) > MAX_CHANGE )	//smooth the acceleration curve
		{
			pot[j] = oldPot[j] + MAX_CHANGE;
		}
		else if ( (oldPot[j] - pot[j]) > MAX_CHANGE )
		{
			pot[j] = oldPot[j] - MAX_CHANGE;
		}
	}

	if (pot[0] > MAX_SPEED) // hard limit
	{
		pot[0] = MAX_SPEED;
	}


//input check

	Serial.print("MPOT:\t");
	Serial.print(pot[0]);
	Serial.print("\tM1:\t");
	Serial.print(pot[1]);
        Serial.print("\tM2:\t");
	Serial.print(pot[2]);
	Serial.print("\tM3:\t");
	Serial.print(pot[3 ]);

	for (byte i = 0; i != 2; i++)	//calc duty cycles
	{
		dutyCycle[i] = pot[0] + map(pot[i+1], 0, 1023, -(MAX_TWEAK), MAX_TWEAK);
	}				  // 963 = 2000uS - 1023uS (pot range) - 13.5uS digitalWrite overhead

	noInterrupts();				//disable Interrupts while copying new motor data
	for (int j = 0; j != 2; j++)
	{
		__dutyCycle[j] = dutyCycle[j];	//copy the data
	}
	interrupts();
}

/********************* TIMERONE *****************************/

void manualpwm()                            //Worst case runtime: 6.25mS
{                                           //Best case: 3.25mS
    digitalWrite(MOTOR1, HIGH);			//each write takes 4.5uSec
	delayMicroseconds(__dutyCycle[0]);	//write from the shadow copy
	digitalWrite(MOTOR1, LOW);

	digitalWrite(MOTOR2, HIGH);
	delayMicroseconds(__dutyCycle[1]);
	digitalWrite(MOTOR2, LOW);

	digitalWrite(MOTOR3, HIGH);
	delayMicroseconds(__dutyCycle[2]);
	digitalWrite(MOTOR3, LOW);
}

/********************* SHIFTSHIELD **************************/

void setupShift()
{
	pinMode(SHIFTIN, OUTPUT);			//Setup the Shift Reg
	pinMode(SHIFTLATCH, OUTPUT);
	pinMode(SHIFTCLOCK, OUTPUT);
	digitalWrite(SHIFTCLOCK, LOW);		//SRCK and RCK Idle low
	digitalWrite(SHIFTLATCH, LOW); 
	digitalWrite(SHIFTIN, LOW);
	
/*	putstring_nl("How many relay shields are attached?");
	char countString[4] = {0,0,0,0};									//shouldn't need more than 3 digits.
	int ptr = 0;														//2048 relays?  well code it yourself :P
	putstring_nl("entering wait");
	while (Serial.available() == 0)										//wait for input
        {
		delay(1);
	}
        putstring_nl("exited wait");
	while (Serial.available() > 0)										//fill up the countString
	{
		putstring_nl("reading char");
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
		putstring("Malloc Failed! Free RAM: ");       //running out of RAM is bad
		Serial.println(freeMemory());
//		while(1) {}									//do nothing, new code is needed
		shieldCount = 1;
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
	}*/
	relayState[0] = 0x00;
	shiftOut(relayState, shieldCount); 					//turn all relays off, for safety!
//	putstring("leaving relaysetup");
}

void shiftOut(byte * myDataOut, byte count) //Writes data to the shift shield
{											//count is the number of shields, myDataOut is an array of count bytes
//	putstring_nl("In shiftOut:");

	pinMode(SHIFTCLOCK, OUTPUT);
	pinMode(SHIFTIN, OUTPUT);
	pinMode(SHIFTLATCH, OUTPUT);

	digitalWrite(SHIFTIN, 0); // next relay state (High == on)
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
			digitalWrite(SHIFTIN, (myDataOut[j] & (1<<i)) && (1<<i));			//write our data to our datapin
			delayMicroseconds(50);
			digitalWrite(SHIFTCLOCK, 1);							//shifts bits on upstroke of clock pin  
			delayMicroseconds(50);      
			digitalWrite(SHIFTIN, 0);								//zero the data pin after shift to prevent bleed through
		}
//		putstring_nl("");
	}
	//stop shifting
	digitalWrite(SHIFTCLOCK, 0);
	digitalWrite(SHIFTLATCH, HIGH);					//data is written when latch goes high
	delayMicroseconds(50);	
	digitalWrite(SHIFTLATCH, LOW);					//latch idles low
}

void paddedPrint(byte out)					//print a byte w leading zeros
{
//	putstring_nl("State:");
	for (byte j = 7; (0 == out>>j) && ( j != 0 ); j--)	//print leading zeros
	{
		Serial.print("0");
	}
	Serial.print(out,BIN);
}
