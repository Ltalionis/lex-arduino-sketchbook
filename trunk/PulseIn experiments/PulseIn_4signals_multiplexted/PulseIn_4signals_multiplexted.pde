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

#define VERBOSE 1

#define PIN_COUNT 4

byte pins[] = {8, 9, 10, 11};
int length[] = {0, 0, 0, 0};
int tmp[] = {0, 0, 0, 0};
volatile byte i = 0;
volatile byte count = 0;
unsigned long time;
unsigned long oldTime;
unsigned long delta;

void setup ()
{
	Serial.begin(9600);					//warm up the serial port
	Serial.println("PulseIn 4 channel testing");		//with a friendly welcome
	for (int i = 0; i < PIN_COUNT; i++)
	{
		pinMode(pins[i], INPUT);			//set pin 8 to input
	}
}

void loop ()
{
	oldTime = time;
	time = millis();
	delta = time - oldTime;
	for (int j = 0; j < PIN_COUNT; j=+2)
	{
		tmp[j+i] = pulseIn(pins[j+i], HIGH, 4200);	//pulseIn(pin, state, time	
	}
	for (int j = 0; j<PIN_COUNT; j+=2)
	{
		if ( tmp[j+i] > 1) //(900 <= tmp[count]) && (tmp[count] <= 2100) )	//valid inputs are 900-2100uS
		{
			length[j+i] = tmp[j+i];
			Serial.println(delta);
		} 
		else
		{
			#ifdef VERBOSE
			Serial.println(delta);
			#endif
		}
	}
	#ifdef VERBOSE
//	if (i==255)
//	{
		Serial.print("Time:\t");
		for (int i = 0; i< PIN_COUNT; i++)
		{
			Serial.print(length[i]);
			Serial.print("\t");
		}
//	}
	#endif	
	if (i==1)
	{
		i=0;
	} else {
		i=1;
	}
	count = i;
}
