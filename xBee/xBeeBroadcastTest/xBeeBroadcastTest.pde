#include "NewSoftSerial.h"

NewSoftSerial xbeeSerial =  NewSoftSerial(2, 3);


void setup()  {
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  Serial.println("Arduino Console");
  // set the data rate for the SoftwareSerial port
  xbeeSerial.begin(9600);
  xbeeSerial.println("Arduino testing xBee Port");
}

int i = 0;
int count = 0;
void loop()                     // run over and over again
{
  if (millis() - count > 10000)
  {
    xbeeSerial.print(i++);
    count = millis();
  }
  if (xbeeSerial.available())
  {
    Serial.print(xbeeSerial.read());
  }
}
