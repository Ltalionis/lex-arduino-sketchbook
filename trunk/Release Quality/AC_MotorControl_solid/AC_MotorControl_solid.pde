/*

The hardware consists of an SSR (Im using the Omron G3MC-202PL DC5) 
to act as an A/C switch and an opto-isolataed AC zero crossing dectector
(the H11AA1) to give us a zero-crossing reference.

The software uses a single interrupt to control how much of the AC wave 
the load recives.  The interrupt detects the output of the Zero Cross
dectector on pin 2 and delays until the approate time to to turn the load on, mid-wave.


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


Based on:
AC Light Control by Ryan McLaughlin <ryanjmclaughlin@gmail.com>


Thanks to http://www.andrewkilpatrick.org/blog/?page_id=445 
and http://www.hoelscher-hi.de/hendrik/english/dimmer.htm

*/

#include <TimerOne.h>							// Avaiable from http://www.arduino.cc/playground/Code/Timer1
#define FREQ 60 								//60Hrz power in these parts
#define AC_PIN 9								// Output to Opto Triac
#define LED 13									// builtin LED for testing
#define VERBOSE 1							// can has talk back?

//#ifdef VERBOSE
#define DEBUG_PIN 5								//scope this pin to measure the total time for the intrupt to run
int inc=1;
//#endif

char cmd[4] = {0,0,0,0};						//Buffer for serial port commands
unsigned long int time = 0;						// for checking the peroid
unsigned long int period = 1000000 / (2 * FREQ);//The Timerone PWM period in uS, 60Hz = 8333 uS
unsigned long int lastPeriod = period;			// the time since the last zero cross
int hexValue = 0;								// the value from labview (0-0xFFF)
unsigned int onTime = 0;						// the calculated time the triac is conducting
unsigned int offTime = period-onTime;			//the time to idle low on the AC_PIN
int hexInput(int len);							//interperates a hex packet ":XXX" - len hex digits

void setup() {										// Begin setup
	Serial.begin(115200);							//start the serial port at 115200 baud
	Serial.println("AC Motor Control v1");			//we want the max speed here so our debugging output wont slow down our time sensitive intrupt
	#ifdef VERBOSE
	pinMode(DEBUG_PIN, OUTPUT);
	digitalWrite(DEBUG_PIN, LOW);
	Serial.println("----- VERBOSE -----");			// feeling talkative?
	#endif
	pinMode(AC_PIN, OUTPUT);						// Set the Triac pin as output
	pinMode(LED, OUTPUT);
	attachInterrupt(0, zero_cross_detect, RISING); 	// Attach an Interupt to Pin 2 (interupt 0) for Zero Cross Detection
} 													// End setup

void zero_cross_detect()				// function to be fired at the zero crossing this function stalls 
{										// with the line low until we are ready to turn on.  Could be a problem
	#ifdef VERBOSE						// with the large delays needed for very low settings.	
	digitalWrite(DEBUG_PIN, HIGH);
	//Serial.print("Zero crossed\toffTime:\t");		//only uncomment these if you really need em		
	//Serial.print(offTime);						//this intrupt needs to be fast or it could be 
	//Serial.print("\tTime:\t");					//intrupted while its still in the interupt, 
	//Serial.print(time);							//looping forever out of control.
	//Serial.print("\t");
	#endif
	if (offTime<=2200)	{				//if off time is very small
		digitalWrite(AC_PIN, HIGH);		//stay on all the time
		#ifdef VERBOSE
		//Serial.print("Full on\t");
		#endif
	}
	else if (offTime>=7900) {			//if offTime is large
		digitalWrite(AC_PIN, LOW);		//just stay off all the time
		#ifdef VERBOSE
		//Serial.print("Full off\t");
		#endif
	}
	else								//otherwise we want the motor at some middle setting
	{
		delayMicroseconds(offTime);	//if you need very accurate control time the function overhead and use that number here
		digitalWrite(AC_PIN, HIGH);		//Fire the Triac and give it a uSec or two to pull
		delayMicroseconds(15);			// the gate high. Then turn off the Triac gate.
		digitalWrite(AC_PIN, LOW);		// Triac will not turn off until next zero cross
	
	}
#ifdef VERBOSE
//Serial.println("\t end zerocross");
//Serial.print('-');
digitalWrite(DEBUG_PIN, LOW);
#endif
}											// End zero_cross_detect

void loop() {							// Non time sensitive tasks - read the serial port
/*	offTime = offTime + inc;        //walk up and down debug routine
	if (offTime>=7900)
	{
		inc = -4;
	}
	else if (offTime<=2200)
	{
		inc = 4;
	}*/	
	hexValue = hexInput(3);				// Read a 3 digit hex number off the serial
	if (hexValue < 0) {
		//no input, so do nothing
	} else {       
		onTime = map(hexValue, 0, 4095, 0, period);	// re scale the value from hex to uSec 
		offTime = period - onTime;					// off is the inverse of on, yay!
		#ifdef VERBOSE
		//Serial.print("In loop:\t");
		//Serial.print("Input Val \t");
		//Serial.print(hexValue);
		//Serial.print("\tperiod:");
		//Serial.print(period);
		//Serial.print("\tonTime:");
		//Serial.print(onTime);
		Serial.print("\toffTime:");
		Serial.println(offTime);
		#endif
	}
}

int hexInput(int len) {		//labview sends ":XXX" - three hex digits, repeating for ever
	int val = -1;
	if (Serial.available() > len)   {
		#ifdef VERBOSE
		//Serial.println("");
		//Serial.print("Input:");
		#endif
		
		cli();			//disable interrupts to read the information on the serial port, otherwise packets may be courrupted
		while (Serial.read() != ':')  //ignore anything until we find the edge of the frame
		{
			#ifdef VERBOSE
			Serial.print("!");
			#endif
		}
		val = 0;
		for (int i = 0; i<len; i++)		
		{
			cmd[i] = Serial.read();
			#ifdef VERBOSE
			Serial.print(cmd[i]);
			#endif
		}
		sei();			// start interrupts again
		
		for (int i = 0; i<len; i++)
		{
			switch (       ( ('0'<=cmd[i]) && (cmd[i]<='9') ) 		//1 if cmd is a ascii numeral
					+ (2 * ( ('A'<=cmd[i]) && (cmd[i]<='F') ) ) )	//2 if cmd is A-F  - returns 0 for all other chars
			{
				case 1:		//cmd[i] is a numeral
				{
					//Serial.print("N");
					cmd[i] -= '0';
					break;
				}	
				case 2:		//cmd[i] is a letter
				{
					//Serial.print("S");
					cmd[i] = (cmd[i] - 'A') + 10;	
					break;
				}
				case 0: 	//anything else
				{
					//Serial.print(i, DEC);
					val = -1;		//Set the error condition
					goto bailout;	//if cmd[i] isnt anything we want, dump the whole packet
				}
			}
			val += cmd[i]<<( (len-i-1)*4 );	//Now we want to multiply it by the right power of 16 to get it's place value.
											// each hex digit is four digits in bin so if we find its place value in hex, (len-i-1),
		}									// we can multply by 4 to get the total shift: (i,shift) (0,8) (1,4) (2,0)

		//cmd[len+1] = 0;
		#ifdef VERBOSE
		Serial.print("\tinput val:");
		Serial.println(val);
		#endif
	}
	bailout:
	return val;
}
