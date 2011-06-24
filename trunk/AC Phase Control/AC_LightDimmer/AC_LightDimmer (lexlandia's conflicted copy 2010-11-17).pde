/*
 AC Light Control
 
 Ryan McLaughlin <ryanjmclaughlin@gmail.com>
 
 The hardware consists of an Triac to act as an A/C switch and 
 an opto-isolator to give us a zero-crossing reference.
 The software uses two interrupts to control dimming of the light.
 The first is a hardware interrupt to detect the zero-cross of
 the AC sine wave, the second is software based and always running 
 at 1/128 of the AC wave speed. After the zero-cross is detected 
 the function check to make sure the proper dimming level has been 
 reached and the light is turned on mid-wave, only providing 
 partial current and therefore dimming our AC load.
 
 Thanks to http://www.andrewkilpatrick.org/blog/?page_id=445 
   and http://www.hoelscher-hi.de/hendrik/english/dimmer.htm
  
*/

#include <TimerOne.h>           // Avaiable from http://www.arduino.cc/playground/Code/Timer1

volatile int i=0;               // Variable to use as a counter
volatile boolean zero_cross=0;  // Boolean to store a "switch" to tell us if we have crossed zero
int AC_pin = 17;                // Output to Opto Triac
int Dimmer_pin = 0;             // Pot for testing the dimming
int LED = 13;                    // LED for testing
int dim = 0;                    // Dimming level (0-128)  0 = on, 128 = 0ff
int freqStep = 65;    // Set the delay for the frequency of power (65 for 60Hz, 78 for 50Hz) per step (using 128 steps)
                     // freqStep may need some adjustment depending on your power the formula 
                     // you need to us is (500000/AC_freq)/NumSteps = freqStep
                     // You could also write a seperate function to determine the freq

void setup() {                                      // Begin setup
 pinMode(AC_pin, OUTPUT);                          // Set the Triac pin as output
 pinMode(LED, OUTPUT);                             // Set the LED pin as output
 attachInterrupt(0, zero_cross_detect, FALLING);   // Attach an Interupt to Pin 2 (interupt 0) for Zero Cross Detection
 Serial.begin(9600);
 Timer1.initialize(freqStep);                      // Initialize TimerOne library for the freq we need
 Timer1.attachInterrupt(dim_check, freqStep);      // Use the TimerOne Library to attach an interrupt
                                                   // to the function we use to check to see if it is 
                                                   // the right time to fire the triac.  This function 
                                                   // will now run every freqStep in microseconds.                                            
}                                                   // End setup

void zero_cross_detect() {        // function to be fired at the zero crossing                           
   zero_cross = 1;               // set the boolean to true to tell our dimming function that a zero cross has occured
}                                 // End zero_cross_detect

void dim_check() {                   // Function will fire the triac at the proper time
 if(zero_cross == 1) {              // First check to make sure the zero-cross has happened else do nothing
   if(i>=dim) {                     // Check and see if i has accumilated to the dimming value we want
     digitalWrite(AC_pin, HIGH);    // Fire the Triac mid-phase
     delayMicroseconds(5);          // Pause briefly to ensure the triac turned on
     digitalWrite(AC_pin, LOW);     // Turn off the Triac gate (Triac will turn off at the next zero cross)
     i = 0;                         // Reset the accumilator
     zero_cross = 0;                // Reset the zero_cross so it may be turned on again at the next zero_cross_detect    
   } else {
     i++;                           // If the dimming value has not been reached, incriment our counter
   }                                // End dim check
 }                                  // End zero_cross check
}                                    // End dim_check function

void loop() {                        // Main Loop
 dim = (Serial.read() - '0') * 14 ;  // Read the serial port, '9' = 126
 analogWrite(LED, dim);             // Write the value to the LED for testing
}

