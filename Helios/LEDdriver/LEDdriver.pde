/*	Fade in and Fade out
 
 	Copyright Lex Talionis, 2010
 	
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
 
 */

char cmd[4]= {0, 0, 0, 0};			// incoming serial byte
byte fade;
byte led[8]= {3, 5, 6, 9, 10, 11, 7, 8};	// array of pins that LEDs are attached to
char frame = 0;

byte str2hex (const char * str);

void setup()
{
	Serial.begin(19200);
	for (int i = 0; i<8; i++)
	{
		pinMode(led[i], OUTPUT);
	}
}

void loop()
{
	if (Serial.available() > 24)
	{
		while (Serial.read(); != ':')
			{
				//Do nothing
			}
		for (int i = 0; i<8; i++)
		{
			cmd[0] = Serial.read();
//			Serial.print(cmd[0], BYTE);
			cmd[1] = Serial.read();
//			Serial.print(cmd[1]);
			cmd[2] = Serial.read();
//			Serial.println(cmd[2]);
			cmd[3] = 0;
			fade = str2hex(cmd+1);
			if (cmd[0] >= '1' && cmd[0] <= '6')
			{
//       		Serial.println(fade, HEX);
//  	       	Serial.println(cmd[0]-'0'-1, DEC);
				analogWrite(led[(cmd[0]-'0'-1)], fade);
                
			}
			else if (cmd[0] == '7' || cmd[0] == '8')
			{
				if (fade >= 128)
				{
//          		Serial.println("HIGH");
					digitalWrite(led[(cmd[0]-'0'-1)], HIGH);
				}
				else if (fade < 128)
				{
//          	    Serial.println("LOW");
					digitalWrite(led[(cmd[0]-'0'-1)], LOW);
				}
			}
		}
		frame = 0;
	}
	else
	{
		delayMicroseconds(10);
	}
}

byte str2hex (const char * str)		// only converts two digits
{
	int val = 0;
	if (str[0] >= 'A' && str[0] <= 'F')
	{
		val = (str[0] - 'A' + 10)<<4;
// 		Serial.print((str[0] - 'A' + 10)*16, DEC);
//    	Serial.print("val:");
//    	Serial.println(val);
	}
	else if (str[0] >= '0' && str[0] <= '9')
	{
		val = (str[0] - 48)<<4;
//    	Serial.print((str[0] - '0')*16, DEC);
//    	Serial.print("val:");
//    	Serial.println(val);
	}
// 	Second Digit
	if (str[1] >= 'A' && str[1] <= 'F')
	{
		val += (str[1] - 'A' + 10);
 //   	Serial.print((str[1] - 'A' + 10), DEC);
 //   	Serial.print("val:");
 //   	Serial.println(val);
	}
	else if (str[1] >= '0' && str[1] <= '9')
	{
		val += (str[1] - 48);
	}
	return val;
}
