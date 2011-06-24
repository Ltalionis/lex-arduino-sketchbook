
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

int value = 0;
int value2 = 0;
void setup()
{
  Serial.begin(9600);
  delay(1);
  Serial.println("Welcome to My Brain");
  pinMode(25, INPUT);
  pinMode(27, INPUT);
}

void loop()
{
  delay(1000);
  value = digitalRead(25);
  value2 = digitalRead(27);
  Serial.print(value);
  Serial.print("   ");
  Serial.println(value2);
}
