/* Demo program of TimerTwo lib 
 * Much thanks to http://www.arduino.cc/playground/Code/FrequencyTimer2
 * for the general structure
 */

 #include <TimerTwo.h>
unsigned int v=0;
unsigned int count=0;
unsigned int burp=0;

void setup ()
{
  Serial.begin(115200);
  pinMode(11, OUTPUT);
  pinMode(13, OUTPUT);
  digitalWrite(11, LOW);
  digitalWrite(13, LOW);
  Serial.println("TimerTwo Libary Test");
  Timer2.initialize(PRESCALE_1024);
}

void ovf() { 
  count++;
  digitalWrite(13,HIGH);
}

void pin13() {
  digitalWrite(13,LOW);
  burp++;
}
void loop ()
{
  if ( Serial.available()) {
    char ch = Serial.read();
    switch(ch) {
    case '0'...'9':
      v = v * 10 + ch - '0';
      break;
    case 'P':
      Timer2.setPeriod(v);
      Serial.print("prescale set ");
      Serial.print(v, DEC);
      Serial.println();
      v = 0;
      break;
    case 'e':
      Timer2.pwm(11, v);
      Serial.print("duty cycle on pin 11:\t");
      Serial.println(v, DEC);
      v=0;
      break;
    case 'd':
      Timer2.disablePwm(11);
      Serial.println("pwm off on pin 11");
      break;
    case 'p':
      Timer2.setPwmDuty(11, v);
      Serial.print("duty cycle set:\t");
      Serial.println(v,DEC);
      v=0;
      break;
    case 's':
      Timer2.start();
      Serial.println("Starting timer2");
      break;
    case 't':
      Timer2.stop();
      Serial.println("Halting timer2");
      break;
    case 'r':
      Timer2.restart();
      Serial.println("reseting timer2 to 0");
      break;
    case 'i':
      Timer2.attachInterrupt(ovf);
      Serial.print("burp much?\t");
      Serial.println(count);
      break;
    case 'I':
      Timer2.attachInterruptA(pin13);
      Serial.print("software PWM on pin13\t");
      Serial.println(burp);
      break;
    case 'q':
      Timer2.detachInterrupt();
      Serial.print("no more blurp!\t");
      Serial.println(count);
      break;
    case 'Q':
      Timer2.detachInterruptA();
      Serial.print("no more PWM on 13:\t");
      Serial.println(burp);
      break;
    }
  }
}
