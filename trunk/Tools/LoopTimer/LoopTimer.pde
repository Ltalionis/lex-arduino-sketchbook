byte j = 0;
unsigned long int delta = 0;

void setup()
{
	Serial.begin(9600);
	unsigned long time =millis();
	for(long int i=0;i<1000000;++i); // one millions times!
	delta = millis()-time;
	Serial.println(delta);

	time =millis();
	for(long int i=0;i<1000000;++i) {
		i/1347;	//function to time
	}
	delta = millis()-time;
	Serial.println(delta);
}

void loop(){}  
