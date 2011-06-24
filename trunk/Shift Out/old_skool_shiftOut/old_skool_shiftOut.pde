#define SHIFTDATA 10	// 8 port shift register pins (TPIC6A596NE)
#define SHIFTLATCH 8
#define SHIFTCLOCK 9




void setup()
{
	Serial.begin(9600);
	pinMode(SHIFTDATA, OUTPUT);			//Setup the Shift Reg
	pinMode(SHIFTLATCH, OUTPUT);
	pinMode(SHIFTCLOCK, OUTPUT);
	digitalWrite(SHIFTCLOCK, LOW);		//SRCK and RCK Idle low
	digitalWrite(SHIFTLATCH, LOW); 
	shiftOut(SHIFTDATA, SHIFTCLOCK, MSBFIRST, 0); 					//turn all relays off, for safety!

	Serial.println("welcome to the bare essentals shift routuine");
}
byte k=0;
void loop()
{
	for (int i=0;i<=7;i++)
	{
		k=1<<i;
		Serial.println(k, BIN);
		digitalWrite(SHIFTLATCH, LOW);
		shiftOut(SHIFTDATA, SHIFTCLOCK, MSBFIRST, k);
		digitalWrite(SHIFTLATCH, HIGH);
		delay(500);
	}
}
