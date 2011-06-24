#include "TimerOne.h"
// use .9 for a 10us cycle
#define CYCLE 5
#define TWENTY_MS 20000/CYCLE
#define ONE_MS (1000/CYCLE) *.7
#define TWO_MS (2000/CYCLE) *.7

#define MOTOR1 4

void setup () {
  Timer1.initialize(CYCLE);  //.01ms per cycle, 2,000 cycles = 20ms
  //Timer1.pwm(9,512);        //pwm on 0 - 1024
  Timer1.attachInterrupt(pwmcount);
  Serial.begin(9600);
  pinMode(MOTOR1, OUTPUT);
  digitalWrite(MOTOR1, LOW);
}

int pot = 0;
int val = 0;
int count = 0;

void pwmcount() {
  count += 1;
  if (count == val) {
    digitalWrite(MOTOR1, LOW);
  } else if (count == TWENTY_MS) { //cycles in 20ms 
    count = 0;
    digitalWrite(MOTOR1, HIGH);
  }
}

void loop() {
    Serial.print("Pot: ");
    Serial.print(analogRead(0));
    pot = analogRead(0);
    val = map(pot, 0, 1023, ONE_MS, TWO_MS); //100 cycles 1ms ; 200 cycles = 2ms
    Serial.print("\tval: ");
    Serial.println(val);
  }
