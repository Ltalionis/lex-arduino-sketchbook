
#include "TimerOne.h"
void setup () {
Timer1.initialize(20000);  //20milisec/1024 = 19.5 u sec per tick
Timer1.pwm(9,512);        //pwm on 0 - 1024
Serial.begin(9600);
}

int pot = 0;
int val = 0;
byte count = 0;

void loop() {
//  if (count == 10) {
    Serial.print("Pot: ");
    Serial.print(analogRead(0));
    pot = analogRead(0);
    val = map(pot, 0, 1023, 52, 102); // servo pwm takes between 1-2ms pulses
    Serial.print("\tval: ");          // 52*19.5= 1.01ms ; 102*19.5 = 1.99ms
    Serial.println(val);
    Timer1.pwm(9, val);
    count = 0;
//   } else {
//     count =+ 1;
//   }
}
