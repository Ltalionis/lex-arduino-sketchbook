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
  while (xbeeSerial.available()) {   //Report what the xBee says
      Serial.print("inwhile");
      data[i] = (char) xbeeSerial.read();
      i++;
    }
   if (data[0] =! 0) {
      Serial.print("xBee Says:");
      Serial.print(data);         //prints on adruino console
      Serial.println("\t");
      xbeeSerial.print(data);     //gets looped back to xbee
   }
   delayMicroseconds(50);
   
 /* if (Serial.available()) {    // local input gets passed to xbee
      data = (char) Serial.read();
      Serial.print("You Said:");
      Serial.print(data);
      Serial.println("\t");
      xbeeSerial.print(data);
  }*/
}
