#define POTM 0
#define MOTOR1 5

int oldPot;
int pot;
int usec;
int msec;

void setup ()
{
  pinMode(MOTOR1, OUTPUT);
  Serial.begin(9600);
  Serial.println("welcome");
}


void loop () 
{
 //   msec = usec/1000;

/*    Serial.print("0: ");
    Serial.print(analogRead(0));
    Serial.print("\t\t1:");
    Serial.print(analogRead(1));
    Serial.print("\t\t2:");
    Serial.print(analogRead(2));
    Serial.print("\t\t3:");
    Serial.println(analogRead(3));
    Serial.print("\t\t4:");
    Serial.print(analogRead(4));
    Serial.print("\t\t5:");
    Serial.println(analogRead(5));
    for (int i = 0; i != 7; ++i)
    {
        pot += (analogRead(0) - pot)/8;
    //    Serial.print("in pot loop");
    }
    
  */  
  pot = analogRead(0);
    if (pot > (oldPot + 4))	
    { 
	oldPot += 4;
    }
    else if (pot < (oldPot - 4))
    {
        oldPot -= 4;
    }
    pot = oldPot;
    if (pot > 675) // hard limit
    {
      pot = 675;
    }
    usec = map(pot, 0, 1023, 1000, 2000);
    Serial.print("oldPot:\t");
    Serial.print(oldPot);
    Serial.print("\tPot:\t");
    Serial.println(pot);
    digitalWrite(MOTOR1, HIGH);
    delayMicroseconds(usec);
    digitalWrite(MOTOR1, LOW);
    delay(18);
}
