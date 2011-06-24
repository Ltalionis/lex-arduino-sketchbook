/*
	
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


#define POTM 0
#define OPTOREAD 1
#define MOTOR1 7
#define SW1 2
#define SW2 3
#define SW3 4
#include <TimerOne.h>


int oldPot = 1500;
int pot;
int usec;
int msec;

void setup ()
{
	pinMode(MOTOR1, OUTPUT);
	Serial.begin(9600);
	Serial.println("welcome");
	Timer1.initialize(20000);
	Timer1.attachInterrupt(manualpwm);
	pinMode(SW1, INPUT);
	digitalWrite(SW1, HIGH);
	pinMode(SW2, INPUT);
	digitalWrite(SW2, HIGH);
	pinMode(SW3, INPUT);
	digitalWrite(SW3, HIGH);
	delay(1);
}


void loop () 
{
  Serial.print("SW1:\t");
  Serial.print(digitalRead(SW1));
  /*
  Serial.print("usec:\t");
    Serial.print(usec);
    Serial.print("\tPot:\t");
    Serial.print(pot);
    */
  pot = analogRead(POTM);
    /*
    if (pot > (oldPot + 4))	
    { 
	oldPot += 4;
    }
    else if (pot < (oldPot - 4))
    {
        oldPot -= 4;
    }
    if (oldPot > 675) // hard limit
    {
      oldPot = 675;
    }
    */
    
    usec = map(pot, 0, 1023, 900, 1900);
    delay(5); 
    Serial.print("usec:\t");
    Serial.print(usec);
    Serial.print("\tPot:\t");
    Serial.print(5*pot);
  Serial.print("\tOpto Voltage:\t");
  Serial.print(5*analogRead(OPTOREAD));
  Serial.println();
}

void manualpwm ()
{
    digitalWrite(MOTOR1, HIGH);
    delayMicroseconds(usec);
    digitalWrite(MOTOR1, LOW);
}
