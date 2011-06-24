/* tests timer 2 frequency shifting on the atmega 328p*/
#include <avr/interrupt.h>
#define FREQ 60 								//60Hrz power in these parts
unsigned long int period = 1000000 / (2 * FREQ);//The Timerone PWM period in uS, 60Hz = 8333 uS
uint8_t pre =0;
uint8_t top =0;
int count=0;

void setup() {
	pinMode(11,OUTPUT);

	Serial.begin(19200);
	delay(2);
	Serial.print("Ready");
	pinMode(11,OUTPUT);
	
	
	TCCR2B = 0; //disable and clear the relivant control regs
	TCCR2A = 0; //Timer2 control registers A & B have lots of jobs
		//each bit in these byte-sized registers has a diffrent job
	TCNT2 = 0;  //the actual count of the timer
				//see http://web.alfredstate.edu/weimandn/miscellaneous/atmega168_subsystem/atmega168_subsystem_index.html
				// and pg 159 on the datasheet
				
	T2setPeriod(period);//FrequencyTimer2::setPeriod(200);
	T2setMode();
	T2setInterrupt();
}

void T2setPeriod(unsigned long period)
{
	if ( period == 0) period = 1;
	period *= clockCyclesPerMicrosecond();

	period /= 2;            // we work with half-cycles before the toggle 
	if ( period <= 256) {    //figgure out what prescaler to use
		pre = 1;
		top = period-1;
	} else if ( period <= 256L*8) {
		pre = 2;
		top = period/8-1;
	} else if ( period <= 256L*32) {
		pre = 3;
		top = period/32-1;
	} else if ( period <= 256L*64) {
		pre = 4;
		top = period/64-1;
	} else if ( period <= 256L*128) {
		pre = 5;
		top = period/128-1;
	} else if ( period <= 256L*256) {
		pre = 6;
		top = period/256-1;
	} else if ( period <= 256L*1024) {
		pre = 7;
		top = period/1024-1;
	} else {
		pre = 7;
		top = 255;
	}
	TCCR2B = pre;         // the last three bits in Timer2's control register
			// set the prescalor's mode
	OCR2A = top;          // contains the number timer2 counts up to then
			// back down again to trigger the ISR
}

void T2setMode()
{
	ASSR &= ~_BV(AS2);    // clear bit AS2 in register ASSR 
			// this synroizes timer2 with the system clock
	TCCR2A = (TCCR2A & ~_BV(WGM20)); //sets WGM20 in Timer2 Control A to 0
	TCCR2A = (TCCR2A |  _BV(WGM21)); //sets WGM21 in Timer2 Control A to 1
	TCCR2B = (TCCR2B & ~_BV(WGM22)); //sets WGM22 in Timer2 Control B to 0
			// the three WGM bits define the Wave Generation Mode (010B=2)
			// we select mode 2, CTC, clear counter on compare with OCR2A
	TCCR2A = (TCCR2A & ~_BV(COM2A0)); //sets COM2A0 in Timer2 Control A to 0
	TCCR2A = (TCCR2A & ~_BV(COM2A1)); //sets COM2A1 in Timer2 Control A to 0
			//For CTC mode, these two bits control how 
			//OC2A (aka digital pin 11) responds when the timer
			//reaches OCR2A (aka top). Both bits off disconnects OC2A
}

void T2setInterrupt()
{
	SREG = (SREG | _BV(7)); //set the global interrupts flag in the
				//status register to 1, now interrupts will work
	//Serial.print(_BV(7), BIN);
	TIMSK2 = (TIMSK2 | _BV(OCIE2A));  //Set Timer2's output comp
				//match on, Timer2 will generate an interrupt when
				//TCNT = OCR2A, or when our count reaches our top
				//the int is TIMER2 COMPA, and the vector is #9 
}

ISR(TIMER2_COMPA_vect) {
	digitalWrite(11,HIGH);
  	delayMicroseconds(150);
	digitalWrite(11,LOW); //Turn off OC2A after a 150uS pulse
	//Serial.print('-');
	count++;
}

void loop() {
	static unsigned long v = 0;
	if ( Serial.available()) {
		char ch = Serial.read();
		switch(ch) {
		case '0'...'9':
			v = v * 10 + ch - '0';
			break;
		case 'p':
			T2setPeriod(v);
			Serial.print("set ");
			Serial.print((long)v, DEC);
			Serial.println();
			v = 0;
			break;
		case 'e':
			T2setMode();
			break;
		case 'd':
			//FrequencyTimer2::disable();
			break;
		case 'o':
			//FrequencyTimer2::setOnOverflow( Burp);
			break;
		case 'n':
			//FrequencyTimer2::setOnOverflow(0);
			break;
		case 'b':
			Serial.println(count,DEC);
			break;
		case 'x':
			Serial.print("TCCR2A:");
			Serial.println(TCCR2A,HEX);        
			Serial.print("TCCR2B:");
			Serial.println(TCCR2B,HEX);
			Serial.print("OCR2A:");
			Serial.println(OCR2A,HEX);
			Serial.print("TCNT2:");
			Serial.println(TCNT2,HEX);
			break;
		}
	}
}


