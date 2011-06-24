/*	This program reports the result of polling pin 10

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
byte pulse;
byte count = 0;
byte str2hex (const char * str);
byte inpin = 10;
void setup()
{
	Serial.begin(9800);
	for (int i = inpin; i<inpin; i++)
	{
		pinMode(i, OUTPUT);
	}
}
void loop() {
  pulseCounter();
}

byte pulseCounter()
{
  byte count = 0;
  for (int i=0; i < 50; i++)          //Takes at least 25.5ms to run
  {                                   //120 pulse per sec = 8.3333ms per pulse
    pulse = digitalRead(inpin);          //we should see 3 pulses per
    count = pulse + count;
    Serial.print(pulse,DEC);
    delayMicroseconds(100);
  }
  Serial.print("        Count:");
  Serial.println(count, DEC);
  delay(500);
  return count;
}




