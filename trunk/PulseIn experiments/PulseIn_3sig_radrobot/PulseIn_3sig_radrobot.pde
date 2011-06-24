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

--------------------------- PulseIn 4 channel decoder -----------------------------	
	
	This sktch takes 4 channels of PPM from a RC Reciver (I used a
	RCD3200 - 8 chan) and prints it to the serial port*/

///#define VERBOSE 1

#include <TimerOne.h>

#define FWD 0
#define REV 1

#define LEFT 0
#define RIGHT 1

#define OUT_COUNT 5

#define FIRE 19  //aka A5
#define L_FWD 18 //aka A4
#define L_REV 17 //aka A3
#define R_FWD 16 //aka A2
#define R_REV 15 //aka A1

#define IN_COUNT 3

#define RC_TURN 3
#define RC_FWD 2
#define RC_FIRE 4

byte inpins[] = {RC_FWD, RC_TURN, RC_FIRE};
byte outpins[] = {FIRE, L_FWD, L_REV, R_FWD, R_REV};
int L[]={L_FWD,L_REV}; //left chan, fwd and rev pins
int R[]={R_FWD,R_REV}; //right chan
int length[] = {0, 0, 0};
int tmp[] = {0, 0, 0};
int drive[2][2] = {{L_FWD,L_REV},	//drive[LEFT or RIGHT][FWD or REV]
				 {R_FWD,R_REV}};
volatile byte i = 0;
volatile byte count = 0;
unsigned long time;
unsigned long oldTime;
unsigned long delta;
long timeout;

void setup ()
{
	Serial.begin(9600);					//warm up the serial port
	Serial.println("PulseIn based 2 chan H-bridge");//with a friendly welcome
	pinMode(FIRE, OUTPUT);			//set pin to input
	pinMode(L_FWD, OUTPUT);			//set pin to input
	pinMode(R_FWD, OUTPUT);			//set pin to input
	pinMode(L_REV, OUTPUT);			//set pin to input
	pinMode(R_REV, OUTPUT);			//set pin to input
	pinMode(RC_FWD, INPUT);			//set pin to input
	digitalWrite(RC_FWD, HIGH);		//engage internal pull up
	pinMode(RC_TURN, INPUT);			//set pin to input
	digitalWrite(RC_TURN, HIGH);		//engage internal pull up
	pinMode(RC_FIRE, INPUT);			//set pin to input
	digitalWrite(RC_FIRE, HIGH);		//engage internal pull up
	Timer1.initialize(20000);
}

void loop ()
{
	oldTime = time;
	time = millis();
	delta = time - oldTime;

	tmp[count] = pulseIn(inpins[count], HIGH, timeout);	//pulseIn(pin, state, time)
	if ( tmp[count] > 1) //(900 <= tmp[count]) && (tmp[count] <= 2100) )	//valid inputs are 900-2100uS
	{
		length[count] = tmp[count];
		//Serial.println(delta);
	} 
	else
	{
		#ifdef VERBOSE
		//Serial.println(delta);
		#endif
	}
	#ifdef VERBOSE
	if (i==255)
	{
		Serial.print("Time:\t");
		for (int i = 0; i< IN_COUNT; i++)
		{
			Serial.print(length[i]);
			Serial.print("\t");
		}
		Serial.println();
	}
	#endif	
	i++;
	count = i % IN_COUNT;
	timeout = random(2500, 3000);
	go();
}

void go()
{
	for (byte k=0; k < IN_COUNT; k++)
	{
		tmp[k]=length[k]-1500;
	}
	
	digitalWrite(FIRE,  tmp[2]>0 ? HIGH : LOW); //set fire first;
	tmp[2]=tmp[1]+tmp[0];						//left leg
	tmp[RIGHT]=tmp[1]-tmp[0];					//right leg
	tmp[LEFT]=tmp[2];

	for (byte chan=LEFT; chan<2; chan++)
	{
		switch	(	 ( (-1000 <= tmp[chan]) && (tmp[chan] <=  -50))+	//Servo is in the lower third, so the motor should be in reverse
				(2 * ( ( -49 <= tmp[chan]) && (tmp[chan] <=  49)))+	//Servo is in the deadzone, so the motor should be in netrual
				(4 * ( (  50 <= tmp[chan]) && (tmp[chan] <= 1000))))	//Servo is in the upper third, forwards
		{
			case 1:	//rev
			digitalWrite(drive[chan][FWD], LOW);
			delayMicroseconds(50);
			digitalWrite(drive[chan][REV], HIGH);
			#ifdef VERBOSE
			if (i==255)
			{
			Serial.print(chan, DEC);
			Serial.print(":\t");
			Serial.print("REV ");
			}
			#endif
			break;
			case 2:	//nut
			digitalWrite(drive[chan][FWD], LOW);
			delayMicroseconds(50);
			digitalWrite(drive[chan][REV], LOW);
			#ifdef VERBOSE
			if (i==255)
			{
			Serial.print(chan, DEC);
			Serial.print(":\t");
			Serial.print("NET ");
			}
			#endif
			break;
			case 4:	//fwd
			digitalWrite(drive[chan][REV], LOW);
			delayMicroseconds(50);
			digitalWrite(drive[chan][FWD], HIGH);
			#ifdef VERBOSE
			if (i==255)
			{
			Serial.print(chan, DEC);
			Serial.print(":\t");
			Serial.print("FWD ");
			}
			#endif
			break;
			default:
			delayMicroseconds(1);
			#ifdef VERBOSE
			if (i==255)
			{
			Serial.print(chan, DEC);
			Serial.print(":\t");
			Serial.print("DEF ");
			}
			#endif

		}
	}
	
	
	
	#ifdef VERBOSE
	if (i==255)
	{
		Serial.println();
		Serial.print("Go:\t");
		for (int i = 0; i< 2; i++)
		{
			Serial.print(tmp[i]);
			Serial.print("\t");
		}
		Serial.println();
	}
	#endif	
}

/*int zone(int val)
{
	switch	(	 ( (-600 <= length[RC_FWD]) && (length[RC_FWD] <=  -50))+	//Servo is in the lower third, so the motor should be in reverse
			(2 * ( ( -49 <= length[RC_FWD]) && (length[RC_FWD] <=  49)))+	//Servo is in the deadzone, so the motor should be in netrual
			(4 * ( (  50 <= length[RC_FWD]) && (length[RC_FWD] <= 600))))	//Servo is in the upper third, forwards
	case 1:	//rev
	digitalWrite(L_FWD, LOW);
	digitalWrite(L_REV, HIGH);
	digitalWrite(R_FWD, LOW);
	digitalWrite(R_REV, HIGH);
	break;
	case 2:	//nut
	digitalWrite(L_FWD, LOW);
	digitalWrite(L_REV, LOW);
	digitalWrite(R_FWD, LOW);
	digitalWrite(R_REV, LOW);
	break;
	case 4:	//fwd
	digitalWrite(L_REV, LOW);
	digitalWrite(L_FWD, HIGH);
	digitalWrite(R_REV, LOW);
	digitalWrite(R_FWD, HIGH);
	break;
}
*/
