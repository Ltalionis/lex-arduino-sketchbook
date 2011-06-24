/* Copyright 2010 Lex Talionis.


The hardware consists of an Solid State Relay (SSR) to act as an A/C switch and 
an opto-isolator to give us a zero-crossing reference.  I'm using an H11AA1.
On a zero-cross of the AC sine wave the H11AA1 chip momentarly pulls pin 10 high.  
The interrupt on pin 10 detects this and waits until the approate amount of time
has passed then turns on the AC_PIN, triggering the SSR

Based on:
AC Light Control by Ryan McLaughlin <ryanjmclaughlin@gmail.com>
LED Dimmer

Thanks to http://www.andrewkilpatrick.org/blog/?page_id=445 
and http://www.hoelscher-hi.de/hendrik/english/dimmer.htm

*/

#include <TimerOne.h>           // Avaiable from http://www.arduino.cc/playground/Code/Timer1
#define FREQ 60 				//60Hrz power in these parts
#define AC_PIN 7              // Output to Opto Triac
#define LED 13                    // builtin LED for testing
#define VERBOSE 1            //print debugging output

char cmd[4] = {0,0,0,0};			//Buffer for serial port commands
volatile unsigned int i=0;               // Variable to use as a counter
unsigned long int time = 0;
int offTime = 1000;			//the time to idle low on the AC_PIN
int period = 1000000 / 2 * FREQ; //The Timerone PWM period in uS, 60Hz = 8333 uS 
int microSecPerStep = period>>10;    // Set the delay per step (using 1024 steps), 60Hz = 8uS per step
// You could also write a seperate function to determine the freq
byte step =3;

void setup() {                                      // Begin setup
	Serial.begin(9600);
	pinMode(AC_PIN, OUTPUT);                          // Set the Triac pin as output
	digitalWrite(AC_PIN, LOW);
	pinMode(LED, OUTPUT);                             // Set the LED pin as output
	attachInterrupt(0, zero_cross_detect, RISING);   // Attach an Interupt to Pin 2 (interupt 0) for Zero Cross Detection 
	Serial.println("AC SSR Testing Routine");
}                                                   // End setup

void zero_cross_detect() {        // function to be fired at the zero crossing  
#ifdef VERBOSE
	Serial.print("Zero:\t");		// this function stalls with the line low until 
	//Serial.print(millis());		// we are ready to turn on.  Could be a problem with large delays.
	Serial.print("Trigger delay: ");
	Serial.println(offTime);
	digitalWrite(AC_PIN, HIGH);
	delayMicroseconds(50);
	digitalWrite(AC_PIN,LOW);
#endif
	//time = millis();				//recored the time for peroid analysis
	delayMicroseconds(7000); 	
	digitalWrite(AC_PIN, HIGH);    // Fire the SSR after waiting the specified time
	delayMicroseconds(250);		
	digitalWrite(AC_PIN, LOW);     // Turn off the SSR gate (SSR will not turn off until next zero cross)
}                                 // End zero_cross_detect

void loop() {                        // Non time sensitive tasks - read the serial port and your led indicator
	//labviewInput();  // Read the value from the serial port, save it as the offTime value
	/*digitalWrite(AC_PIN, HIGH);
	delayMicroseconds(offTime);
	digitalWrite(AC_PIN, LOW);
	delayMicroseconds(period-offTime);
	analogWrite(LED, map(offTime, 0, period, 0, 255));   */          // Write the value to the LED for testing.  analogWrite is 8	bit*/
}

int labviewInput() {
	//Serial.println("In Labview  ");
	if (Serial.available() > 5)   {
		while (Serial.read() != ':')
		{
			// do nothing
			Serial.println("Frame Error");
		}
		int val = 0;	//final value
		byte len = 4; //Lenght of our string
		for (int i = 0; i<len; i++) {		// for each digit in our fixed length string we find the humerical value of it
			cmd[i] = Serial.read();
			//Serial.print(cmd[i]);
			switch (cmd[i])
			{
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':	// if cmd[i] is a numeral we can just subtract '0' and get its value. now we want to
			case '8':	// shift it into place, each hex digit is four digits in bin so if we find its place 
			case '9':	// value, (4-i-1), we can multply by 4 (done as another bit shift) to get 
				val += (cmd[i] - '0')<<( (len-i-1)<<2 );  // the total bit shift: (i,(4-i-1)<<2): (0,12) (1,8) (2,4) (3,0) 
				break;
				
			case 'A':
			case 'B':
			case 'C':
			case 'D':
			case 'E':
			case 'F': // if cmd[i] is a letter we only have to change the offset we subtract from it
				val += (cmd[i] - 'A' + 10)<<( (len-i-1)<<2 );
				break;
				
			}	
			//Serial.print("val after case:");
			//Serial.println(val);
		}
		cmd[5] = 0;
		offTime = val;
		Serial.print("offTime: ");
		Serial.println(offTime);
	}
	else
	{
		//what do you do now?
	}
}
