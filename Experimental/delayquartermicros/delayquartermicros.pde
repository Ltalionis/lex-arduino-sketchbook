void setup () {

  Serial.begin(9800);
  Serial.print(clockCyclesPerMicrosecond());
  pinMode(5, OUTPUT);
 }

void loop () {
 digitalWrite(5, LOW);          //4.5uSec=>18QuSec
delayQuarterMicroseconds(100-18); 
  digitalWrite(5, HIGH);
  delayQuarterMicroseconds(100);// 100/4=25uSec  +4.5=29.9
}

/* Delay for the given number of microseconds.  Assumes a 8 or 16 MHz clock. */
void delayQuarterMicroseconds(unsigned int us)
{
	// calling avrlib's delay_us() function with low values (e.g. 1 or
	// 2 microseconds) gives delays longer than desired.
	//delay_us(us);

#if F_CPU >= 16000000L
	// for the 16 MHz clock on most Arduino boards

	// for a one-microsecond delay, simply return.  the overhead
	// of the function call yields a delay of approximately 1 1/8 us.
	if (--us == 0)
		return;

	// the following loop takes a quarter of a microsecond (4 cycles)
	// per iteration, so execute it four times for each microsecond of
	// delay requested.
//	us <<= 2;

	// account for the time taken in the preceeding commands.
	us -= 3;
#else
	// for the 8 MHz internal clock on the ATmega168

	// for a one- or two-microsecond delay, simply return.  the overhead of
	// the function calls takes more than two microseconds.  can't just
	// subtract two, since us is unsigned; we'd overflow.
	if (--us == 0)
		return;
	if (--us == 0)
		return;

	// the following loop takes half of a microsecond (4 cycles)
	// per iteration, so execute it twice for each microsecond of
	// delay requested.
	us <<= 1;
    
	// partially compensate for the time taken by the preceeding commands.
	// we can't subtract any more than this or we'd overflow w/ small delays.
	us--;
#endif

	// busy wait
	__asm__ __volatile__ (
		"1: sbiw %0,1" "\n\t" // 2 cycles
		"brne 1b" : "=w" (us) : "0" (us) // 2 cycles
	);
}

