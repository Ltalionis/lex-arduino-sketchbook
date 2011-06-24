/* Copyright Lex Talionis 2010



*/

volatile byte i =0;
void setup() {
	Serial.begin(9600); 
	Serial.println("prints the state of every pin, then a timestamp");
	Serial.println("Digital\t\t\t\t\tsnalog");
	Serial.println("0 1 2 3 4 5 6 7 8 910111213\t0\t1\t2\t3\t4\t5\ttime");
	for (int j=0;j<=19;j++) // all arduino pins
	{
		pinMode(j, INPUT);
	}
}

void loop() {
	for (int j=0;j<=13;j++) //all digital pins
	{
		if (i==255)
		{
			Serial.print(digitalRead(j));
			Serial.print(" ");
		}
		delayMicroseconds(10);                     
	}
	if (i==255)
	{
		Serial.print("\t");
	}
	for(int j=0;j<=5;j++)
	{
		if (i==255)
		{
			Serial.print(analogRead(j));
			Serial.print("\t");
		}
		delayMicroseconds(10);
	}	
	if (i==255)
	{
		Serial.println(millis());
	}
	i++;
}
