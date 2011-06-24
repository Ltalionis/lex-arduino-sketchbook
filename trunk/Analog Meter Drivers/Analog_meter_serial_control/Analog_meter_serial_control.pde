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

volatile byte cmd[4] = {0,0,0,0};		//most recent CPU value (DEC between 0-100 in ASCII)
volatile byte i=0;			// global counter
volatile byte j=0;

byte val = 0;			//average pot input value

void setup ()
{
	pinMode(METER, OUTPUT);
	pinMode(POT, INPUT);
	Serial.begin(9600);
	Serial.println("Analog_meter_serial_control");
	
	//Serial.print("val:\t");
	//Serial.println(val, DEC);
}

void loop ()
{
	while (Serial.available() > 4)		//we are expecting a string like ":XXX" where XXX is a 3 digit interger, padded with '0' or ' '  
	{									// ":100" & ": 46" & ":057" & ":  4" & ":007" are all valid strings
		while (Serial.read() != ':');	// Read up to the next frame tolken
		{
			Serial.print('!');
		}
		for (i=0; i<=2; i++)
		{
			cmd[i] = Serial.read();
			Serial.print(cmd[i]);
			//      1 if cmd is a ascii numeral              2 if cmd is space  - returns 0 for all other chars
			switch ( (('0' <= cmd[i]) && (cmd[i] <= '9')) + (2 * (cmd[i]==' ')) )
			{
				case 1:		//cmd[i] is a numeral
				{
					Serial.print("N");
					cmd[i] -= '0';
					break;
				}	
				case 2:		//cmd[i] is a space
				{
					Serial.print("S");
					cmd[i] = 0;	
					break;
				}
				case 0: 
				{
					Serial.print(i, DEC);
					goto bailout;	//if cmd[i] isnt anything we want, dump the whole packet
				}
			}
		}
		cmd[3] = 0;
		//Serial.print("tens:\t\t");
		//Serial.println((cmd[0])*10, DEC);
		//Serial.print("ones:\t\t");
		//Serial.println(cmd[1], DEC);
		val = ( (cmd[0])*100 )+( cmd[1]*10 )+ cmd[2];
		Serial.print("\tval:\t");
		Serial.print(val, DEC);
		//Serial.print("maped val:\t");
		//Serial.println(map(val, 0, 100, 0, 255), DEC);
		analogWrite(METER, map(val, 0, 100, 0, 255));	// 
		bailout:
		Serial.println();
	}
	delayMicroseconds(10);		// if theres not enough data, wait for a little to show up
}