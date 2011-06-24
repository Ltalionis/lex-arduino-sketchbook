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

------------------------ 1 channel Remote Control H-Bridge ----------------------	
	
	This sketch takes a standard remote control style PWM signal 
	(20mS cycle, 1-2mS ontime with 1mS is full reverse and 2mS full forward)
	And controls 1 full H bridge circut, Forward-Netural-Reverse.
	Great for skid-steer/tracked robots.
	
	This Sketch uses a RC filter (R-180k C-10uF) to smooth the PWM wave.
	The endpoints for each of the map functions need to be tuned to the transmitter/reciver/ambitent air temperature/pressure/due point/etc.
	2:02 AM 12/26/2010
*/

#define VERBOSE 1

//----------------The first signal from the Reciver must be on pin 2!-------------------//
#define SIG1 0		// we are using analog pin 0 to read the smoothed voltage
#define M1_REV 8	// digital pin 8 drives motor 1 in reverse
#define M1_FWD 9	// digital pin 9 drives motor 1 forwards

/*****************************************************************************************
//				These settings need to be tweaked for each servo/PWM device				//
*****************************************************************************************/
#define SERVO_REVERSE 545	//maximum reverse position
#define DEADB_LOWER 555		//lower limit of the dead band
#define SERV0_NETRUAL 565	//netrual position
#define DEADB_UPPER 570		//upper limit of the dead band
#define SERVO_FORWARD 579	//maximum forward position	


#include <TimerOne.h>		//for their wonderful interrupt interface: <http://www.arduino.cc/playground/Code/Timer1>

volatile byte i = 0;				//counter!
int signal = 0;
int signalLength = 1500;
void setup ()
{
	pinMode(SIG1, INPUT);	//the analog pin we are reading
	pinMode(M1_REV, OUTPUT);
	pinMode(M1_FWD, OUTPUT);
	Serial.begin(9600);
	Serial.println("Remote Controlled Single Channel H-Bridge Controller");	//Let us know what your doin'
	delay(1);
}

void loop ()
{
	signalLength = analogRead(SIG1);				//hopefully, one day I wont need a RC circut hack.
//	signalLength = map(signal, 535, 565, SERVO_REVERSE, SERVO_FORWARD);	//these values have to be read from the pin  <---- == hackjob.
	#ifdef VERBOSE
	if (i==255)
	{
		Serial.print("sig:\t");
		Serial.print(signal);
		Serial.print("\tlength\t");
		Serial.print(signalLength);
		Serial.print("\t");
	}
	#endif
	switch  (	 ( (SERVO_REVERSE <= signalLength)&&(signalLength <= DEADB_LOWER))+		//Servo is in the lower third, so the motor should be in reverse
			(2 * ( (DEADB_LOWER <= signalLength) && (signalLength <= DEADB_UPPER)))+	//Servo is in the deadzone, so the motor should be in netrual
			(3 * ( (DEADB_UPPER <= signalLength) && (signalLength <= SERVO_FORWARD))))	//Servo is in the upper third, forwards
	{
		case 1:	//lower third, reverse
			digitalWrite(M1_FWD, LOW);	//break before make
			delayMicroseconds(10);
			digitalWrite(M1_REV, HIGH);
			#ifdef VERBOSE 
			if (i==255)
			{
				Serial.println("Servo Low");
			}
			#endif
			break;
			
		case 2: //deadzone!
			digitalWrite(M1_FWD, LOW);
			digitalWrite(M1_REV, LOW);
			#ifdef VERBOSE 
			if (i==255)
			{
				Serial.println("Servo dead");
			}
			#endif
			break;
			
		case 3: //upper third, forward
			digitalWrite(M1_REV, LOW);	//break before make
			delayMicroseconds(10);
			digitalWrite(M1_FWD, HIGH);
			#ifdef VERBOSE 
			if (i==255)
			{
			Serial.println("Servo high");
			}
			#endif
			break;
			
		default:						//invalid signal length
			;
			#ifdef VERBOSE 
			if (i==255)
			{
				Serial.println("Bad input");  //No input so keep the last good setting
			}
			#endif
	}
	i++;
}
