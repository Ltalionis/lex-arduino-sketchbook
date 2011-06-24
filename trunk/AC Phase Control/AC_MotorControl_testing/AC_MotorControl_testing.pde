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
#include <avr/interrupt.h>
#define FREQ 60 								//60Hrz power in these parts
#define AC_PIN 9								// Output to Opto Triac
#define LED 13									// builtin LED for testing
#define VERBOSE 1							// can has talk back?
#define DEBUG_PIN 5								//scope this pin to measure the total time for the intrupt to run
int inc=1;

char cmd[4] = {0,0,0,0};						//Buffer for serial port commands
unsigned long int time = 0;						// for checking the peroid
unsigned long int period = 1000000 / (2 * FREQ);//The Timerone PWM period in uS, 60Hz = 8333 uS
unsigned long int lastPeriod = period;			// the time since the last zero cross
int hexValue = 0;								// the value from labview (0-0xFFF)
unsigned int onTime = 0;						// the calculated time the triac is conducting
unsigned int offTime = period-onTime;			//the time to idle low on the AC_PIN
int hexInput(int len);							//interperates a hex packet ":XXX" - len hex digits

void setup() 
{										// Begin setup
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
	
	
	TCCR2B = 0; //disable and clear the relivant control regs
	TCCR2A = 0; //Timer2 control registers A & B have lots of jobs
		//each bit in these byte-sized registers has a diffrent job
	TCNT2 = 0;  //the actual count of the timer
				//see http://web.alfredstate.edu/weimandn/miscellaneous/atmega168_subsystem/atmega168_subsystem_index.html
				// and pg 159 on the datasheet
	T2setMode();
	T2setPeriod(period/2);
	
} 													// End setup

void T2setMode()
{
	ASSR &= ~_BV(AS2);    // clear bit AS2 in register ASSR 
			// this synroizes timer2 with the system clock
	TCCR2A = (TCCR2A & ~_BV(WGM20)); //sets WGM20 in Timer2 Control A to 0
	TCCR2A = (TCCR2A |  _BV(WGM21)); //sets WGM21 in Timer2 Control A to 1
	TCCR2B = (TCCR2B & ~_BV(WGM22)); //sets WGM22 in Timer2 Control B to 0
			// the three WGM bits define the Wave Generation Mode (010B=2)
			// we select mode 2, CTC, clear counter on compare with OCR2A
	TCCR2A = (TCCR2A & ~_BV(COM2A0)); //sets COM2A0 in Timer2 Control A to 0
	TCCR2A = (TCCR2A & ~_BV(COM2A1)); //sets COM2A1 in Timer2 Control A to 0
			//For CTC mode, these two bits control how 
			//OC2A (aka digital pin 11) responds when the timer
			//reaches OCR2A (aka top). Both bits off disconnects OC2A
}

void zero_cross_detect()				// function to be fired at the zero crossing this function stalls 
{										// with the line low until we are ready to turn on.  Could be a problem
										// with the large delays needed for very low settings.	
	TCNT2 = 0;			//reset the count
	#ifdef VERBOSE
	digitalWrite(DEBUG_PIN, HIGH);
	//Serial.print("Zero crossed\toffTime:\t");		//only uncomment these if you really need em		
	//Serial.print(offTime);						//this intrupt needs to be fast or it could be 
	//Serial.print("\tTime:\t");					//intrupted while its still in the interupt, 
	//Serial.print(time);							//looping forever out of control.
	//Serial.print("\t");
	#endif
	if (offTime >= 7700)
	{
			digitalWrite(AC_PIN,LOW);  //full off
	}
	else if (offTime <= 1000)
	{
			digitalWrite(AC_PIN, HIGH); //full on
	}
	else
	{
	T2setPeriod(offTime);	//set the time to wait before 
								// pulsing AC_PIN
	T2setInterrupt();	//enable an interrupt on OCR2A = TCNT
							//aka count = top	
	}
#ifdef VERBOSE
//Serial.print("Count in zeroccross:\t");
//Serial.println(TCNT2,DEC);
//Serial.println("\t end zerocross");
//Serial.print('-');
digitalWrite(DEBUG_PIN, LOW);
#endif
}											// End zero_cross_detect

void T2setPeriod(unsigned long period)
{
    uint8_t pre, top;
  
    if ( period <= 0) return;
    period *= clockCyclesPerMicrosecond();
 
    //period /= 2;            // we work with half-cycles before the toggle 
    if ( period <= 256) {
	pre = 1;
	top = period-1;
    } else if ( period <= 256L*8) {
	pre = 2;
	top = period/8-1;
    } else if ( period <= 256L*32) {
	pre = 3;
	top = period/32-1;
    } else if ( period <= 256L*64) {
	pre = 4;
	top = period/64-1;
    } else if ( period <= 256L*128) {
	pre = 5;
	top = period/128-1;
    } else if ( period <= 256L*256) {
	pre = 6;
	top = period/256-1;
    } else if ( period <= 256L*1024) {
	pre = 7;
	top = period/1024-1;
    } else {
	pre = 7;
	top = 255;
    }
	#ifdef VERBOSE
//	Serial.print("In Period:\tpre:");
//	Serial.print(pre,DEC);
//	Serial.print("\ttop:");
//	Serial.println(top,DEC);
	#endif
	TCCR2B = (TCCR2B | pre); // the last three bits in Timer2's
			// control register B set the prescalor's mode
	OCR2A = top; // contains the number timer2 counts up to trigger the ISR
}

void T2setInterrupt()
{
	SREG = (SREG | _BV(7)); //set the global interrupts flag in the
				//status register to 1, now interrupts will work
	//Serial.print(_BV(7), BIN);
	TIMSK2 = (TIMSK2 | _BV(OCIE2A));  //Set Timer2's output comp
				//match on, Timer2 will generate an interrupt when
				//TCNT = OCR2A, or when our count reaches our top
				//the int is TIMER2 COMPA, and the vector is #9 
}

void T2disableInterrupt()
{
	TIMSK2 = (TIMSK2 & ~_BV(OCIE2A));  //Set Timer2's output comp
				//match off, Timer2 will no longer generate an
				//interrupt
}

ISR(TIMER2_COMPA_vect)
{
	digitalWrite(AC_PIN,HIGH);
  	#ifdef VERBOSE
	digitalWrite(DEBUG_PIN, HIGH);
	#endif
	delayMicroseconds(150);
	digitalWrite(AC_PIN,LOW); //Turn off AC_PIN after a 150uS pulse
	T2disableInterrupt();	//turn off the int routine
	//TCNT2 = 0;
	//T2setPeriod(0);			//and stop the counters prescaler
	#ifdef VERBOSE
	//Serial.print("Count in T2 overflow:\t");
	//Serial.println(TCNT2,DEC);
	digitalWrite(DEBUG_PIN,LOW);
	#endif
}


void loop() {							// Non time sensitive tasks - read the serial port
/*	offTime = offTime + inc;        //walk up and down debug routine
	if (offTime>=8100)
	{
		inc = -4;
	}
	else if (offTime<=2100)
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
		Serial.print("In loop:\t");
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
		Serial.println("");
		Serial.print("Input:");
		#endif
		while (Serial.read() != ':')  //ignore anything until we find the edge of the frame
		{
			#ifdef VERBOSE
			Serial.print("!");
			#endif
		}
		val = 0;
		
		cli();
		for (int i = 0; i<len; i++)		//disable interrupts to read the information on the serial port
		{
			cmd[i] = Serial.read();
			#ifdef VERBOSE
			Serial.print(cmd[i]);
			#endif
		}
		sei();
		
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
