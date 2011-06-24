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

char data[25];

void loop()                     // run over and over again
{
  int i = 0;
  data[0] = 0;
  while (xbeeSerial.available()) {   //read the aether
//      Serial.print("x:");
//      Serial.print(i++, DEC);
     data[i] = (char) xbeeSerial.read();            // using this write %60@5char
//   xbeeSerial.print(data[i], BYTE);
      i++;
  }
  for (int j = 0; i != j; j++) {       // spray it back
      Serial.print(data[j], BYTE);
      xbeeSerial.print(data[j], BYTE);      //%79@5char
  }
  
  while (Serial.available()) {
//      Serial.print("s:");
//      Serial.print(Serial.available(), DEC);
      xbeeSerial.print(Serial.read(), BYTE);
  }
}
