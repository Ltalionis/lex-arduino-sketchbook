
#include <string.h>
#include <ctype.h>

#include <string.h>
#include <ctype.h>

#include <avr/pgmspace.h>
#include <MemoryFree.h> //for debugging

#include <avr/pgmspace.h>
#include <MemoryFree.h>

#define TX 0			//Our serial terminal
#define RX 1

#define OUT 25

void setup()
{
  Serial.begin(9600);
  delay(1);
  Serial.println("Welcome to My Brain");
  pinMode(25, OUTPUT);
}

void loop()
{
  delay(1000);
  digitalWrite(25, LOW);
  Serial.println("LOW");
  delay(1000);
  Serial.println("HIGH");
  digitalWrite(25, HIGH);
}
