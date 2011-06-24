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

--------------------------- PulseIn Demenstration -----------------------------	
	
	This sktch takes a single PPM SIG_PIN from a RC Reciver (I used a
	RCD3200 - 8 chan) and prints it to the serial port*/

#define VERBOSE
#define SIG_PIN 8

int length = 1500;
int tmp = 0;
volatile byte i = 0;

void setup ()
{
	Serial.begin(9600);								//warm up the serial port
	Serial.println("PulseIn usage example");		//with a friendly welcome
	pinMode(SIG_PIN, INPUT);							//set pin 8 to input
}

void loop ()
{
	
	tmp = pulseIn(SIG_PIN, HIGH, 20000);	//read the lenght of the pulse on pin 8
											//and store it in our temp var.  if a 
											//signal does not show up in a little over one cycle (20mS) this will time out)
	if ( (900 <= tmp) && (tmp <= 2100) )	//valid inputs are 900-2100uS
	{
		length = tmp;
	}
	#ifdef VERBOSE
	Serial.print("Time:\t");				//let us know what happened
	Serial.print(length);
	Serial.println();
	i++;
	#endif	
}
