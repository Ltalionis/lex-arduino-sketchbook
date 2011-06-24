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

------------------------------------- Timerone PWM --------------------------------	
	
	This example uses the timer one libary from <http://www.arduino.cc/playground/Code/Timer1>
	to generate PWM on any pins by setting up an intrupt that produces a 20mS frequency
	then simply holding the pin high as long as the duty cycle allows
	-Lex 1:10 PM 12/17/2010
*/

#include <TimerOne.h>	// we might need the libary
#define POT 0			//Our pot is on analog pin 0
#define SERVO 7			//And our servo is on pin 7 (not a standard PWM pin)

/*****************************************************************************************
//				These settings need to be tweaked for each servo/PWM device				//
*****************************************************************************************/
#define SERVO_FORWARD 2000	//uS value of maximum forward position	
#define SERVO_REVERSE 900	//uS value of maximum reverse position
#define SERV0_NETRUAL 1500	//uS value of netrual position
#define DB_LOWER 1200		//lower limit of the dead band
#define DB_UPPER 1800		//upper limit of the dead band

volatile int pot;		//read the value of our pot into here
volatile int usec;		//holds the ontime for this PWM cycle
byte i = 0;

void setup ()
{
	pinMode(SERVO, OUTPUT);				//SERVO can be any digital pin except 9 or 10.
	Serial.begin(9600);
	Serial.println("Pot to PWM, Timerone style with deadzone");	//Let us know what your doin'
	Timer1.initialize(20000);			//Hobby servos and Motor controlers use a 20mS period
	Timer1.attachInterrupt(manualpwm);	//so every 20mS we want to do our PWM thing
	delay(1);
}


void loop () 
{
	pot = analogRead(POT);									//read it
	usec = map(pot, 0, 1023, SERVO_REVERSE, SERVO_FORWARD);	//map it - repeat until its time
	if ( (DB_LOWER<=usec) && (usec<=DB_UPPER) )				// if we are inside the dead band, snap to netural
	{
		usec = SERV0_NETRUAL;
	}


	if ( i == 255)	//debugging output
	{
		//Serial.print("usec:\t");
		//Serial.println(usec);
		//Serial.print("Pot:\t");
		//Serial.println(pot);
		i = 0;
	}
	i++;
}

void manualpwm ()				
{
	digitalWrite(SERVO, HIGH);	//every 20mS we turn the servo pin high
	delayMicroseconds(usec);	//wait for just the right amount of time
	digitalWrite(SERVO, LOW);	//then pull it low.
}