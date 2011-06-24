#include "NewSoftSerial.h"

#define CTS 4

NewSoftSerial xbeeSerial =  NewSoftSerial(2, 3);

char data[220];
byte ctsStatus;
byte tmp;

void setup()
{
  pinMode(13, OUTPUT);
  pinMode(CTS,INPUT);
  Serial.begin(9600);
  Serial.println("Arduino Console");
  xbeeSerial.begin(9600);
  xbeeSerial.println("Arduino testing xBee Port");
}

void loop()
{
  int i = 0;
  data[0] = 0;
  while (xbeeSerial.available())
  {                                     //read the aether
    data[i] = (char) xbeeSerial.read();
    Serial.print(data[i], BYTE);
    i++;
  }
  ctsStatus = digitalRead(CTS);
  if (ctsStatus == 0)                    // inverse logic, we are clear on 0
  {
    for (int j = 0; (i != j); j++)
    {                                       // spray it back
      Serial.print(data[j], BYTE);
      xbeeSerial.print(data[j], BYTE);
   
    }
  }
}

