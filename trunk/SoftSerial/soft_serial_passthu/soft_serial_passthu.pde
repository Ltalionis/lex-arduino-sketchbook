#include "NewSoftSerial.h"

NewSoftSerial xbeeSerial =  NewSoftSerial(2, 3);


void setup()  {
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  Serial.println("Goodnight moon!");
  // set the data rate for the SoftwareSerial port
  xbeeSerial.begin(9600);
  xbeeSerial.println("Hello, world?");
}

byte data;

void loop()                     // run over and over again
{
  xbeeSerial.print(data++);

  delay(200);
}
