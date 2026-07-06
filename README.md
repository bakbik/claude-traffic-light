# claude-traffic-light 🚦

A Claude Code plugin that drives a **physical USB traffic light** showing your session status at a glance.

| Light | Meaning |
|-------|---------|
| 🔴 Red | Claude needs your input / a permission |
| 🟡 Yellow | Claude is working |
| 🟢 Green | Turn done / standby (holds until your next prompt; also the session-start color) |

It's a small DIY build: an ESP32 with three LEDs, plugged into your PC over USB. The plugin fires on Claude session events and tells the board which LED to light.

---

## How it works

```
Claude Code event          plugin hook              PC                    board
─────────────────          ───────────              ──                    ─────
UserPromptSubmit  ───►  traffic.ps1 Y  ───►  write "Y" to COM port  ───►  ESP32 lights yellow
Notification      ───►  traffic.ps1 R  ───►         "R"             ───►  ESP32 lights red
Stop              ───►  traffic.ps1 G  ───►         "G"             ───►  ESP32 lights green
SessionStart      ───►  traffic.ps1 G  ───►         "G"             ───►  ESP32 lights green (standby)
```

The firmware speaks a trivial one-character serial protocol (`R`/`Y`/`G`/`O`). A tiny per-platform helper finds the board's serial port and writes the character: `scripts/traffic.ps1` on Windows, `scripts/traffic.sh` on Linux/macOS. Everything is stateless and instant.

---

## Part 1 — The physical build

### Bill of materials

| Qty | Part | Notes |
|-----|------|-------|
| 1 | **ESP32-S3 Zero** (Waveshare) | Any ESP32 with native USB works; pin numbers below assume the S3 Zero |
| 3 | 5 mm LEDs — red, yellow, green | Standard through-hole |
| 3 | Resistors, **220 Ω** (220–330 Ω fine) | One per LED, current limiting |
| 1 | USB-C **data** cable | Charge-only cables will NOT enumerate a COM port |
| — | Breadboard or perfboard + hookup wire | Perfboard if you want it permanent |
| 1 | Enclosure (optional) | 3D-printed traffic-light box, project box, or cardboard |

### Wiring

Each LED gets its own GPIO through a resistor; all three cathodes share **GND**.

```
        ESP32-S3 Zero
      ┌────────────────┐
      │          GPIO1 ├──[220Ω]──▶|── red LED ──┐
      │          GPIO2 ├──[220Ω]──▶|── yellow ───┤
      │          GPIO3 ├──[220Ω]──▶|── green ────┤
      │            GND ├──────────────────────────┘
      │                │
      │   USB-C  ──────┼──────►  to PC
      └────────────────┘

   ▶|  = LED.  The ▶ (anode, long leg) faces the resistor/GPIO.
              The | (cathode, short leg) goes to the shared GND rail.
```

| LED | GPIO pin | Resistor | LED long leg (anode) | LED short leg (cathode) |
|-----|----------|----------|----------------------|-------------------------|
| 🔴 Red | GPIO1 | 220 Ω | → resistor → GPIO1 | → GND |
| 🟡 Yellow | GPIO2 | 220 Ω | → resistor → GPIO2 | → GND |
| 🟢 Green | GPIO3 | 220 Ω | → resistor → GPIO3 | → GND |

**Wiring rules — most build problems are one of these:**

1. **Polarity matters.** LED long leg = anode = toward the resistor/GPIO. Short leg = cathode = toward GND. Backwards → the LED stays dark. Flip it.
2. **Every cathode must reach a GND pin.** A missing ground is the #1 "nothing lights up" cause.
3. **One resistor per LED**, in series. Don't skip them.
4. **Avoid special pins.** Don't use strapping pins (GPIO0, GPIO45, GPIO46) or the USB pins (GPIO19, GPIO20). GPIO1/2/3 are safe.
5. **Use a data USB-C cable.** Charge-only cables give power but no serial port.

### Sanity-check a single LED

Long leg → 3V3 pin through a 220 Ω resistor, short leg → GND. It should light. If it does, the LED and resistor are good and any problem is in the GPIO wiring or polarity.

---

## Part 2 — Flash the firmware

The sketch is in [`firmware/traffic_light.ino`](firmware/traffic_light.ino).

### Option A — Arduino IDE

1. Install the **ESP32 board package** (Boards Manager → "esp32" by Espressif).
2. Board: **ESP32S3 Dev Module**.
3. Tools → enable **USB CDC On Boot**.
4. Select the board's COM port → Upload.
5. Open Serial Monitor at **115200**, type `R` / `Y` / `G` / `O` — confirm each LED (and only that one) lights.

### Option B — arduino-cli

```bash
arduino-cli core install esp32:esp32
arduino-cli compile --fqbn "esp32:esp32:esp32s3:CDCOnBoot=cdc" firmware
arduino-cli upload -p COM8 --fqbn "esp32:esp32:esp32s3:CDCOnBoot=cdc" firmware
```

Replace `COM8` with your board's port. Native USB CDC means opening the port from the PC does **not** reset the board, so LED state holds between hook calls.

---

## Part 3 — Install the plugin

> Works on **Windows, Linux, and macOS**. Run these in a real `claude` **terminal** — the interactive `/plugin` menu may not work in embedded/desktop hosts; the CLI does.

```bash
claude plugin marketplace add bakbik/claude-traffic-light
claude plugin install claude-traffic-light@claude-traffic-light
```

Then **fully restart** Claude Code. On each session the light will now track your status automatically.

---

## Configuration

- **Serial port** is auto-detected: on Windows via the Espressif USB vendor ID (`303A`), on Linux via `/dev/serial/by-id/*Espressif*`, on macOS via `/dev/cu.usbmodem*`.
- If detection picks the wrong port, set `TRAFFIC_COM` as an override:

  ```powershell
  setx TRAFFIC_COM COM8            # Windows
  ```
  ```bash
  export TRAFFIC_COM=/dev/ttyACM0  # Linux/macOS (put it in your shell profile)
  ```
- **Linux:** your user needs write access to the serial device — add yourself to the `dialout` group and re-login:

  ```bash
  sudo usermod -aG dialout "$USER"
  ```

---

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| **`running scripts is disabled on this system`** | PowerShell ExecutionPolicy. The plugin hooks already pass `-ExecutionPolicy Bypass`; if you call `traffic.ps1` yourself, add that flag or `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. |
| **Hooks never fire** (no LED change) | Command hooks run in a real `claude` **CLI** process. Some embedded/desktop hosts don't execute plugin command-hooks. Verify with a headless run: `"hi" \| claude -p`, then check `scripts/traffic.log`. |
| **`sent=False` in the log** | The board's COM port wasn't found or was busy. Check the cable is a data cable, the board enumerates a COM port, and set `TRAFFIC_COM` if needed. |
| **`sent=false` on Linux** | Usually a permissions issue: the device is `root:dialout`. Add yourself to `dialout` (see Configuration) and re-login. Otherwise check `ls /dev/serial/by-id/` and set `TRAFFIC_COM`. |
| **An LED never lights** | Polarity (flip the LED), missing GND, or wrong GPIO. Run the single-LED sanity check above. |
| **`unable to verify the first certificate`** on install/update | TLS interception by antivirus/proxy (e.g. Avast HTTPS scanning). Node doesn't trust the AV root. Export the AV root CA to a `.pem` and set `NODE_EXTRA_CA_CERTS` to it, or disable the AV's HTTPS scanning. |
| **No COM port at all** | Charge-only cable, or missing USB driver. Use a data cable; check Device Manager. |

### Debug log

Both helpers append every call to `scripts/traffic.log` (timestamp, color, `sent=True/False`). It's the fastest way to see whether hooks fire and whether the serial write lands.

---

## Repo layout

```
.claude-plugin/
  plugin.json        # hook definitions (UserPromptSubmit/Notification/Stop/SessionStart)
  marketplace.json   # marketplace manifest
scripts/
  traffic.ps1        # Windows entry called by hooks: arg R|Y|G|O -> serial write
  TrafficLight.psm1  # COM-port resolution + serial send (Windows)
  traffic.sh         # Linux/macOS entry: same protocol, port via /dev/serial/by-id
firmware/
  traffic_light.ino  # ESP32 firmware (single-char serial -> LEDs)
```

## License

MIT
