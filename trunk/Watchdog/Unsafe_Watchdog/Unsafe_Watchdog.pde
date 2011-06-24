#define PRI_FUEL 7

void setup() {
 Serial.begin(115200);
 Serial.print("Welcome to the Watchdog");
 pinMode(PRI_FUEL, OUTPUT);
 digitalWrite(PRI_FUEL, HIGH);
}

void loop() {
  
}
