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
 
 #include <TimerOne.h>

 #define SERVO 9
 #define MOTOR 8
 
int dutyCycle[] = {1500, 1500};			//duty cycle for each motor in uSec
int __dutyCycle[] = {1500, 1500};

char cmd[4] = {0,0,0,0}; // the command

 void setup() {
	Serial.begin(9600);	
	pinMode(SERVO, OUTPUT);
	pinMode(MOTOR, OUTPUT);

	Timer1.initialize(20000);
	Timer1.attachInterrupt(manualpwm);
	delay(1);
	Serial.println("HeliosPWM Controller, runs fuel servo and fan motor");
}

void loop() {
	
	if (Serial.available() > 3)    //looking for :MXXSXX  -- M for motor or S for servo, then a hex number in ascii [0-9ABCEDF], two commands per frame
	{
                while (Serial.read() != ':')
		{
			//Do nothing
		}
		cmd[0] = Serial.read();		//zeroth digit is the channel number
//		Serial.print(cmd[0], BYTE);
		cmd[1] = Serial.read();		// 1st & 2nd give a hex value
//		Serial.print(cmd[1]);
		cmd[2] = Serial.read();
//		Serial.println(cmd[2]);
		cmd[3] = 0;
		if (cmd[0] == 'S' || cmd[0] == 's')
		{
                Serial.print("Servo chan\t");
  		Serial.println(str2hex(cmd+1), DEC);
//         	Serial.printlncmd[0]-'0'-1, DEC);
			dutyCycle[0] = map(str2hex(cmd+1), 0, 256, 1000, 2000);
				
		}
		else if (cmd[0] == 'M' || cmd[0] == 'm')
		{
                  Serial.print("Servo chan\t");
  		Serial.println(str2hex(cmd+1), DEC);
			dutyCycle[1] = map(str2hex(cmd+1), 0, 256, 1000, 2000);
		}
	}

}

void manualpwm()                            //Worst case runtime: 6.25mS
{                                           //Best case: 3.25mS
    digitalWrite(SERVO, HIGH);			//each write takes 4.5uSec
	delayMicroseconds(dutyCycle[0]);	//write from the shadow copy
	digitalWrite(SERVO, LOW);

	digitalWrite(MOTOR, HIGH);
	delayMicroseconds(dutyCycle[1]);
	digitalWrite(MOTOR, LOW);
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
