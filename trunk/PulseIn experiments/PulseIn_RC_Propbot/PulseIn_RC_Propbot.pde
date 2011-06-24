/*  Copyright Lex Talionis 2010
	
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

-------------------------Propbot motorcontroller - 3 channel -----------------------------	
	
	This sktch takes 3 channels of PPM from a RC Reciver (I used a
	RCD3200 - 8 chan) and prints it to the serial port*/

#define VERBOSE 1		// Print debugging info to the serial port

#define PIN_COUNT 3		// how many ppm signals do we have?
#define FWD 1			// add a couple of keywords for readability
#define REV 0

#define SERVO_REVERSE 900	//maximum reverse position
#define DEADB_LOWER 1300	//lower limit of the dead band
#define SERV0_NETRUAL 1500	//netrual position
#define DEADB_UPPER 1700	//upper limit of the dead band
#define SERVO_FORWARD 2100	//maximum forward position	


const byte pins[PIN_COUNT] = {14, 15, 16};	//the input pins wired to the reciver
int length[PIN_COUNT] = {SERV0_NETRUAL, SERV0_NETRUAL, SERV0_NETRUAL};//the length of the pulse on each pin
volatile int tmp[PIN_COUNT] = {0, 0, 0};		//a place to put the results of pulseIn
byte motor[PIN_COUNT][2] = {{13,12},			//control pins for the 3 H-bridges.  Steering-turning-weapon
	{11,10},									//order is {FWD, REV}
	{9,8} };
long timeout = SERV0_NETRUAL;					//the max time for pulseIN to wait (set randomly)
volatile byte count = 0;						//which input to read this time?

#ifdef VERBOSE
volatile byte i = 0;							//the debug counter
unsigned long time = 0;							//the time we started this loop
unsigned long oldTime = 0;						//the time we started the last loop
unsigned long delta = 0;						//how long the last loop took
unsigned long pulseTime = 0;					//how long pulseIn takes to execute
#endif

void setup ()
{
	Serial.begin(19200);								//warm up the serial port
	Serial.println("PulseIn 4 channel testing");		//with a friendly welcome
	for (int i = 0; i < PIN_COUNT; i++)
	{
		pinMode(pins[i], INPUT);			//set pins attached to the reciver to input
		pinMode(motor[i][0], OUTPUT);
		pinMode(motor[i][1], OUTPUT);		//and set our H-bridge pins to output
	}
}

void loop ()
{
	#ifdef VERBOSE
	oldTime = time;					//tell us how long this loop took
	time = millis();
	#endif
	
	tmp[count] = pulseIn(pins[count], HIGH, timeout);	//the guts of our loop, we only check for a pulse on one pin per loop
														//if we call pulseIn to many times per loop no values update
	
	#ifdef VERBOSE
	pulseTime = millis() - time;
	if (i==255)
	{
		//Serial.print("count: ");			//lets take a peak at whats going in our variables
		//Serial.print(count, DEC);
		//Serial.print("   ");
		//Serial.print("timeout: ");
		//Serial.print(timeout);
		//Serial.print("   ");
		//Serial.print("tmp: ");
 		//Serial.print(tmp[count]);
		//Serial.print("\t");
	}
	#endif
	switch  (	 ( (SERVO_REVERSE <=tmp[count])&& (tmp[count] <= DEADB_LOWER))+		//Servo is in the lower third, so the motor should be in reverse
			(2 * ( (DEADB_LOWER <= tmp[count]) && (tmp[count] <= DEADB_UPPER)))j+	//Servo is in the deadzone, motor to netrual
			(3 * ( (DEADB_UPPER <= tmp[count]) && (tmp[count] <= SERVO_FORWARD))))	//Servo is in the upper third, forwards
	{
	case 1:	//lower third, reverse
		digitalWrite(motor[count][FWD], LOW);	//break before make - both pins high in an H-bridge will cause a short
		delayMicroseconds(10);
		digitalWrite(motor[count][REV], HIGH);
		length[count]=tmp[count];
		#ifdef VERBOSE 
		//if (i==255)
		//{
		//Serial.println("Servo Low");
		//}
		#endif
		break;
		
	case 2: //deadzone!
		digitalWrite(motor[count][FWD], LOW);
		digitalWrite(motor[count][REV], LOW);
		length[count]=tmp[count];
		#ifdef VERBOSE 
		//if (i==255)
		//{
		//Serial.println("Servo dead");
		//}
		#endif
		break;
		
	case 3: //upper third, forward
		digitalWrite(motor[count][REV], LOW);	//break before make
		delayMicroseconds(10);
		digitalWrite(motor[count][FWD], HIGH);
		length[count]=tmp[count];
		#ifdef VERBOSE 
		//if (i==255)
		//{
		//Serial.println("Servo high");
		//}
		#endif
		break;
		
	default:						//invalid signal length
		;
		#ifdef VERBOSE 
		//if (i==255)
		//{
		//	Serial.println("Bad input");  //No input so keep the last good setting
		//}
		#endif
	}
	
	//----------------Debugging output below --------------------------//
	#ifdef VERBOSE
	if (i==255)
	{
		Serial.print("Pins:\t");
		for (int i = 0; i< PIN_COUNT; i++)
		{
			Serial.print(pins[i], DEC);
			Serial.print("-");
			Serial.print("length: ");
			Serial.print(length[i]);
			Serial.print(" ");
			switch     ( ( (SERVO_REVERSE <=length[i])&& (length[i] <= DEADB_LOWER))+		//Servo is in the lower third, so the motor should be in reverse
					(2 * ( (DEADB_LOWER <= length[i]) && (length[i] <= DEADB_UPPER)))+	//Servo is in the deadzone, so the motor should be in netrual
					(3 * ( (DEADB_UPPER <= length[i]) && (length[i] <= SERVO_FORWARD))))	//Servo is in the upper third, forwards
			{                                                                                                                                                                 
			case 1:	//lower third, reverse
				Serial.print("REV  ");
				break;
			
			case 2: //deadzone!
				Serial.print("MID  ");
				break;
			
			case 3: //upper third, forward
				Serial.print("FWD  ");
				break;
			
			default:						//invalid signal length
				Serial.print("BAD  ");
			}
		}
		Serial.println();
	}
	#endif	
	
	i++;
	count = i % PIN_COUNT;				//update the index
	timeout = random(20, 200);			//and make a new timeout
}
