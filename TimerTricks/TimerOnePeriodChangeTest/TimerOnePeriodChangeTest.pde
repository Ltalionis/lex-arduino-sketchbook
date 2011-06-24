#include <TimerOne.h>

void setup ()
{
	Serial.begin(9600);
	Serial.println("welcome to pwm period change speed test");
	Timer1.initialize(20000);
	Timer1.attachInterrupt(manualpwm);
	delay(1);
}

unsigned long millis_record[16];
unsigned long millis_tmp;
unsigned long millis_acc;
unsigned long millis_avg;
void loop() {
  millis_avg = 0;
  for (byte i; i < 16; i++)
  {
    millis_acc = 0;
    for (byte j; j<16; j++)
    {
      millis_tmp = millis();
      Timer1.setPeriod(i<<j);
      millis_acc += millis() - millis_tmp;
      Serial.print(millis_acc);
    }
    millis_record[i] = millis_acc >> 4; // devide by 16
    Serial.print(millis_record[i]);
    millis_avg += millis_record[i];
    Serial.print(" ");
  }
  Serial.print("         Avg: ");
  Serial.println(millis_avg >> 4);
  delay(500);
}

void manualpwm()
{
  //donothing
}

