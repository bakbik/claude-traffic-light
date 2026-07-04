# claude-traffic-light

Claude Code plugin that drives a physical USB traffic light showing session status.

| Color | Meaning |
|-------|---------|
| 🔴 Red | Claude needs input / permission |
| 🟡 Yellow | Claude working |
| 🟢 Green | Turn done (holds until next prompt) |
| Dark | Idle / session start |

Hardware: an ESP32 (tested on ESP32-S3 Zero) over USB serial, 3 LEDs on GPIO1/2/3.
See the firmware + wiring in the companion project.

## Install

```
/plugin marketplace add bakbik/claude-traffic-light
/plugin install claude-traffic-light@claude-traffic-light
```

Then restart Claude Code. On each session:

- `SessionStart` → light off
- `UserPromptSubmit` → yellow
- `Notification` → red
- `Stop` → green

## How it works

Plugin hooks call `scripts/traffic.ps1 <R|Y|G|O>`, which resolves the board's COM
port (Espressif VID `303A`, or `$env:TRAFFIC_COM` override) and writes a single
char over serial. The ESP32 firmware lights the matching LED.

`traffic.ps1` always exits 0 — an unplugged light never stalls a Claude session.

## Firmware

Flash this Arduino sketch to the ESP32 (native USB CDC, single-char protocol):

```cpp
const int PIN_RED=1, PIN_YELLOW=2, PIN_GREEN=3;
void setColor(char c){
  digitalWrite(PIN_RED,LOW); digitalWrite(PIN_YELLOW,LOW); digitalWrite(PIN_GREEN,LOW);
  switch(c){case 'R':digitalWrite(PIN_RED,HIGH);break;
            case 'Y':digitalWrite(PIN_YELLOW,HIGH);break;
            case 'G':digitalWrite(PIN_GREEN,HIGH);break;}
}
void setup(){pinMode(PIN_RED,OUTPUT);pinMode(PIN_YELLOW,OUTPUT);pinMode(PIN_GREEN,OUTPUT);setColor('O');Serial.begin(115200);}
void loop(){if(Serial.available()>0){char c=Serial.read();if(c=='R'||c=='Y'||c=='G'||c=='O')setColor(c);}}
```

Wiring: each `GPIO → 220Ω → LED anode`, LED cathode → GND.
