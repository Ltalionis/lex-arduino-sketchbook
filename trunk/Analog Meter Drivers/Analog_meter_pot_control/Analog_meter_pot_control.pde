/* Copyright Lex Talionis 2010
	
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

	This sketch take a 0-10k pot on analog 0 and outputs pwm to an analog meter on pin 3
	
*/

#define POT 0
#define METER 3

volatile int buffer[16];		//to stablizse the pot input
volatile byte i=0;				// global counter
long int avg = 0;					//average pot input value

void setup ()
{
	pinMode(METER, OUTPUT);
	pinMode(POT, INPUT);
	Serial.begin(9600);
	Serial.println("Analog_meter_pot_control");

	while (i<16)					//fill up the buffer to start
	{
		buffer[i] = analogRead(POT);
		Serial.print(i,DEC);
		Serial.print(":\t");
		Serial.println(buffer[i]);
		i++;
	}
	Serial.println("buffer full");
	for (byte j=0; j<=15; j++) //devide each entry by 16, then add to the running average 
	{
		avg += (buffer[j]);		
	}
	Serial.print("avg:\t");
	Serial.println(avg);
}

void loop ()
{
	if(i==16)
	{
		i=0;
	}
	//avg =- (buffer[i]>>4); 			// subtract 1/16th of the oldest entry 
	avg -= buffer[i];
	buffer[i] = analogRead(POT);	// overwrite the oldest entry
	//avg += (buffer[i]>>4);			//devide the new entry by 16, then add to the running average 
	avg += (buffer[i]);
	analogWrite(METER, (avg>>6));	// analogRead is 10bit, Write is 8bit.  avg's max is 1024*16=16384, or 14bits 14-8=6bits left. I like bit shifts.
	i++;
	Serial.println(avg);
}