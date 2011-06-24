/*
*  Interrupt and PWM utilities for 8 bit Timer2 on ATmega168/328
 *  Original code by Jesse Tane for http://labs.ideo.com August 2008
 *  Modified March 2009 by Jérôme Despatis and Jesse Tane for ATmega328 support
 *  Modified June 2009 by Michael Polli and Jesse Tane to fix a bug in setPeriod() which caused the timer to stop
 *  Modified May 2011 by Lex Talionis to provide similar functioniality on Timer 2
 *
 *  This is free software. You can redistribute it and/or modify it under
 *  the terms of Creative Commons Attribution 3.0 United States License. 
 *  To view a copy of this license, visit http://creativecommons.org/licenses/by/3.0/us/ 
 *  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 *
 */

#include <avr/io.h>
#include <avr/interrupt.h>

#define RESOLUTION 256    // Timer2 is 8 bit

class TimerTwo
{
public:

  // properties
  unsigned int pwmPeriod;
  unsigned char clockSelectBits;

  // methods
  void initialize(long microseconds=1000000);
  void start();
  void stop();
  void restart();
  void pwm(char pin, byte duty, long microseconds=-1);
  void disablePwm(char pin);
  void attachInterrupt(void (*isr)(), long microseconds=-1);
  void detachInterrupt();
  void setPeriod(long microseconds);
  void setPwmDuty(char pin, byte duty);
  void (*isrCallback)();
};

void TimerTwo::initialize(long microseconds)
{
  TCCR2B = _BV(WGM22);        // stop the timer & set mode 5: phase and frequency correct pwm
  TCCR2A = _BV(WGM20);        // see:http://web.alfredstate.edu/weimandn/miscellaneous/atmega168_subsystem/atmega168_subsystem_index.html
  setPeriod(microseconds);
}

void TimerTwo::setPeriod(long microseconds)
{
  long cycles = (F_CPU * microseconds) / 2000000;                                // the counter runs backwards after TOP, interrupt is at BOTTOM so divide microseconds by 2
  if(cycles < RESOLUTION)              clockSelectBits = _BV(CS20);              // no prescale, full xtal
  else if((cycles >>= 3) < RESOLUTION) clockSelectBits = _BV(CS21);              // prescale by /8
  else if((cycles >>= 2) < RESOLUTION) clockSelectBits = _BV(CS21) | _BV(CS20);  // prescale by /32
  else if((cycles >>= 1) < RESOLUTION) clockSelectBits = _BV(CS22);              // prescale by /64
  else if((cycles >>= 1) < RESOLUTION) clockSelectBits = _BV(CS22) | _BV(CS20);  // prescale by /128
  else if((cycles >>= 1) < RESOLUTION) clockSelectBits = _BV(CS22) | _BV(CS21);  // prescale by /256
  else if((cycles >>= 2) < RESOLUTION) clockSelectBits = _BV(CS22) | _BV(CS21) | _BV(CS20);  // prescale by /1024
  else        cycles = RESOLUTION - 1, clockSelectBits = _BV(CS22) | _BV(CS21) | _BV(CS20);  // request was out of bounds, set as maximum
  OCR2A = pwmPeriod = cycles;                                                     // ICR1 is TOP in p & f correct pwm mode
  TCCR2B &= ~(_BV(CS10) | _BV(CS11) | _BV(CS12));
  TCCR2B |= clockSelectBits;                                                     // reset clock select register
  Serial.print("period set:\tpwmPeriod:");
  Serial.print(pwmPeriod); 
  Serial.print("\tClock bits:");
  Serial.println(clockSelectBits, BIN);
}

void TimerTwo::setPwmDuty(char pin, byte duty)
{
  unsigned long dutyCycle = pwmPeriod;
  dutyCycle *= duty;
  dutyCycle >>= 8;
  if(pin == 1 || pin == 11)     OCR2A = dutyCycle;
  else if(pin == 2 || pin == 3) OCR2B = dutyCycle;
}

void TimerTwo::pwm(char pin, byte duty, long microseconds)  // expects duty cycle to be 8 bit (256)
{
  if(microseconds > 0) setPeriod(microseconds);
  if(pin == 1 || pin == 11) {
    DDRB |= _BV(PORTB3);                                   // sets data direction register for pwm output pin
    TCCR2A |= _BV(COM2A1);                                 // activates the output pin
  }
  else if(pin == 2 || pin == 3) {
    DDRB |= _BV(PORTD3);
    TCCR2A |= _BV(COM2B1);
  }
  setPwmDuty(pin, duty);
  start();
}

void TimerTwo::disablePwm(char pin)
{
  if(pin == 1 || pin == 11)     TCCR2A &= ~_BV(COM2A1);   // clear the bit that enables pwm on PB1
  else if(pin == 2 || pin == 3) TCCR2A &= ~( _BV(COM2B0) |_BV(COM2B1) );   // clear the bit that enables pwm on PB2
}

void TimerTwo::attachInterrupt(void (*isr)(), long microseconds)
{
  stop();
  if(microseconds > 0) setPeriod(microseconds);
  isrCallback = isr;                                       // register the user's callback with the real ISR
  TIMSK2 |= _BV(TOIE2);                                     // sets the timer overflow interrupt enable bit
  sei();                                                   // ensures that interrupts are globally enabled
  start();
 }

void TimerTwo::detachInterrupt()
{
  TIMSK2 &= ~_BV(TOIE2);                                   // clears the timer overflow interrupt enable bit 
}

void TimerTwo::start()
{
  TCCR2B |= clockSelectBits;
}

void TimerTwo::stop()
{
  TCCR2B &= ~(_BV(CS20) | _BV(CS21) | _BV(CS22));          // clears all clock selects bits
}

void TimerTwo::restart()
{
  TCNT2 = 0;
}
TimerTwo Timer2;
void setup ()
{
  Serial.begin(9600);
  delay(1);
  pinMode(3, OUTPUT);
  digitalWrite(3, LOW);
  Serial.println("Timer2Testing");
  Timer2.initialize(8333);
}

long v=0;
int count=0;
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

ISR(TIMER2_OVF_vect)          // interrupt service routine that wraps a user defined function supplied by attachInterrupt
{
  Timer2.isrCallback();
}

