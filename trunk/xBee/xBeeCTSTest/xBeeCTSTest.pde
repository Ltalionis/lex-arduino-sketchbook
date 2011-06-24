#include "NewSoftSerial.h"

#define CTS 4

NewSoftSerial xbeeSerial =  NewSoftSerial(2, 3);

char data[25];
byte ctsStatus;
byte tmp;
void setup()  {
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  Serial.println("Arduino Console");
  // set the data rate for the SoftwareSerial port
  xbeeSerial.begin(9600);
  xbeeSerial.println("Arduino testing xBee Port");
}

void loop()                     // run over and over again
{
  ctsStatus = digitalRead(CTS);
  if (ctsStatus == 0)        // inverse logic, we are clear on 0
  {
    xbeeSerial.print("12345678 112345678 212345678 312345678 412345678 ");
  }
  Serial.print(ctsStatus, DEC); //print the old
  ctsStatus = digitalRead(CTS);
  Serial.print(ctsStatus, DEC); //then the new
}
/*  int i = 0;
  data[0] = 0;
  ctsStatus = digitalRead(CTS);
  while (xbeeSerial.available()) {   //read the aether
//      Serial.print("x:");
//      Serial.print(i++, DEC);
     data[i] = (char) xbeeSerial.read();            // using this write %60@5char
   Serial.print(data[i], BYTE);
      i++;
  }
  if (ctsUpdate(CTS) == LOW) {
    for (int j = 0; i != j; j++) {       // spray it back
     Serial.print(data[j], BYTE);
     xbeeSerial.print(data[j], BYTE);      //%79@5char
    }
  }
  
  while (Serial.available()) {
//      Serial.print("s:");
//      Serial.print(Serial.available(), DEC);
      xbeeSerial.print(Serial.read(), BYTE);
  }
}

byte ctsUpdate (byte PIN)
{
  byte tmp = 0;
  tmp = digitalRead(PIN);
  if (ctsStatus != tmp)
  {
    ctsStatus = tmp;
    Serial.print(tmp);
  }
  return ctsStatus;
}*/
