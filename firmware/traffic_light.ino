// traffic_light.ino — Claude Code status traffic light
// ESP32-S3 Zero, native USB CDC. Single-char serial protocol:
//   R=red  Y=yellow  G=green  O=all off
const int PIN_RED    = 1;   // GPIO1
const int PIN_YELLOW = 2;   // GPIO2
const int PIN_GREEN  = 3;   // GPIO3

void setColor(char c) {
  digitalWrite(PIN_RED, LOW);
  digitalWrite(PIN_YELLOW, LOW);
  digitalWrite(PIN_GREEN, LOW);
  switch (c) {
    case 'R': digitalWrite(PIN_RED, HIGH);    break;
    case 'Y': digitalWrite(PIN_YELLOW, HIGH); break;
    case 'G': digitalWrite(PIN_GREEN, HIGH);  break;
    case 'O': break; // all already off
  }
}

void setup() {
  pinMode(PIN_RED, OUTPUT);
  pinMode(PIN_YELLOW, OUTPUT);
  pinMode(PIN_GREEN, OUTPUT);
  setColor('O');
  Serial.begin(115200);
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'R' || c == 'Y' || c == 'G' || c == 'O') setColor(c);
    // any other byte (newline, etc.) is ignored — state unchanged
  }
}
