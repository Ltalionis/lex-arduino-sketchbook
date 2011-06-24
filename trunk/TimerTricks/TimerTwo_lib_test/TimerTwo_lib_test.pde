/* Demo program of TimerTwo lib 
 * Much thanks to http://www.arduino.cc/playground/Code/FrequencyTimer2
 * for the general structure
 */

 #include <TimerTwo.h>
unsigned long v=0;
int count=0;

void setup ()
{
  Serial.begin(9600);
  delay(1);
  pinMode(3, OUTPUT);
  digitalWrite(3, LOW);
  Serial.println("TimerTwo Libary Test");
  Timer2.initialize(8333);
}

void burpcount() { 
  count++;
}
void loop ()
{
  if ( Serial.available()) {
    char ch = Serial.read();
    switch(ch) {
    case '0'...'9':
      v = v * 10 + ch - '0';
      break;
    case 'p':
      Timer2.setPeriod(v);
      Serial.print("set ");
      Serial.print((long)v, DEC);
      Serial.println();
      v = 0;
      break;
    case 'e':
      Timer2.pwm(3, 128);	//half throttle
      Serial.println("50% duty cycle");
      break;
    case 'd':
      Timer2.disablePwm(3);
      Serial.println("pwm off on pin 3");
      break;
    case 'o':
      Timer2.start();
      Serial.println("Starting timer2");
      break;
    case 'f':
      Timer2.stop();
      Serial.println("Halting timer2");
      break;
    case 'r':
      Timer2.restart();
      Serial.println("starting timer2 over again");
      break;
    case 'b':
      Timer2.setPwmDuty(3, v);
      //Serial.print("duty cycle set:\t");
      //Serial.println(v,DEC);
      v=0;
      break;
    case 'i':
      Timer2.attachInterrupt(burpcount);
      Serial.print("\t\tburp much?\t");
      Serial.println(count);
      break;
    case 'q':
      Timer2.detachInterrupt();
      Serial.print("no more blurp!\t");
      Serial.println(count);
      break;
    }
  }
}
