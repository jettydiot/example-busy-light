# 🚦 Busy Light

An AI-powered meeting indicator. Your Google Calendar controls a physical LED — red when busy, green when free.

**One LED. Zero sensors. The AI is the entire point.**

---

## Why this needs AI

A normal IoT rule can check a temperature threshold. It can't check your calendar.

This device is intentionally dumb — 3 LEDs wired to an ESP32. The intelligence lives in an AI agent (OpenClaw) that:

1. Checks your Google Calendar every 5 minutes
2. Determines: in a meeting? meeting soon? free?
3. Sends a command to the device: red, amber, or green

No cloud dashboard, no threshold rules, no complex firmware. Just an AI agent that knows your schedule and a light that shows it.

---

## Demo

```
9:00 AM  — Meeting starts  → 🔴 LED turns red
9:55 AM  — Meeting ends     → 🟢 LED turns green
10:50 AM — Meeting in 10min → 🟡 LED turns amber
11:00 AM — Meeting starts   → 🔴 LED turns red
```

Your family / colleagues / housemates see the light and know whether to interrupt you.

---

## Hardware

| Component | Cost |
|-----------|------|
| ESP32-C3 dev board | ~$4 |
| 3x LEDs (red, green, amber) | ~$0.30 |
| 3x 330Ω resistors | ~$0.10 |

**Total: under $5**

### Wiring

```
ESP32-C3
├── GPIO 3  ──── 330Ω ──── 🔴 Red LED    ──── GND
├── GPIO 4  ──── 330Ω ──── 🟢 Green LED  ──── GND
├── GPIO 5  ──── 330Ω ──── 🟡 Amber LED  ──── GND
└── USB     ──── Power
```

That's it. No sensors, no relay, no pull-up resistors.

---

## Quick start

### 1. Flash the device

```bash
git clone https://github.com/jettydiot/example-busy-light
cd example-busy-light && make setup

# Edit sdkconfig.defaults with your WiFi + fleet token
# Get fleet token at app.jettyd.com

make flash-monitor
```

You'll see:
```
I (3800) jettyd_wifi: Connected — IP: 192.168.1.42
I (5200) jettyd_prov: Provisioned! device_key=dk_...
I (5600) jettyd: Jettyd running
I (5600) jettyd: Drivers: 3    ← red, green, amber
```

### 2. Set up the AI agent

The `agent/` folder contains a script that checks your calendar and commands the light:

```bash
# Set your credentials
export JETTYD_API_KEY="tk_..."        # from app.jettyd.com
export DEVICE_ID="your-device-id"      # from the dashboard

# Test it manually
./agent/busy-light-cron.sh
# [busy-light] 2026-03-27 09:00: status=free   → green light

# Set up a cron to run every 5 minutes
crontab -e
# */5 * * * * JETTYD_API_KEY=tk_... DEVICE_ID=... /path/to/agent/busy-light-cron.sh
```

Or with OpenClaw:
```bash
openclaw cron set busy-light \
  --schedule "*/5 * * * *" \
  --command "bash ~/example-busy-light/agent/busy-light-cron.sh"
```

### 3. Done

The light now reflects your calendar. Walk away.

---

## How the AI agent works

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌───────────┐
│   Google     │────▶│   OpenClaw   │────▶│   jettyd    │────▶│  ESP32 +  │
│   Calendar   │     │   Agent      │     │   Platform  │     │  3 LEDs   │
│              │     │              │     │             │     │           │
│ "Meeting at  │     │ "Tom is in   │     │ POST /cmd   │     │ 🔴 Red ON │
│  9:00-10:00" │     │  a meeting → │     │ switch_on   │     │ 🟢 Off    │
│              │     │  red light"  │     │ red         │     │ 🟡 Off    │
└─────────────┘     └──────────────┘     └─────────────┘     └───────────┘
```

The device doesn't know about calendars. The platform doesn't know about calendars. Only the AI agent knows — and that's the point.

---

## Extend it

The beauty of separating intelligence (agent) from hardware (device) is that you can add features without touching the firmware:

| Feature | Change needed |
|---------|--------------|
| Slack status → LED | Modify agent script to check Slack API |
| Focus mode on Mac → LED | Agent checks `do-not-disturb` state |
| Spotify "recording" → LED | Agent checks Spotify playback |
| Multiple rooms | Flash more ESP32s, agent commands all of them |
| Teams/Zoom presence | Agent checks meeting app status |

None of these require reflashing the ESP32. The device stays the same forever.

---

## API commands reference

```bash
# Red (busy)
curl -X POST "https://api.jettyd.com/v1/devices/$DEVICE_ID/commands" \
  -H "Authorization: Bearer $JETTYD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command_type":"switch_on","payload":{"target":"red"}}'

# Green (free)
curl -X POST ... -d '{"command_type":"switch_on","payload":{"target":"green"}}'

# Amber (meeting soon)
curl -X POST ... -d '{"command_type":"switch_on","payload":{"target":"amber"}}'

# All off
curl -X POST ... -d '{"command_type":"switch_off","payload":{"target":"red"}}'
curl -X POST ... -d '{"command_type":"switch_off","payload":{"target":"green"}}'
curl -X POST ... -d '{"command_type":"switch_off","payload":{"target":"amber"}}'
```

---

## Links

- 📖 [QuickStart guide](https://docs.jettyd.com/quickstart)
- 🌱 [Greenhouse example](https://github.com/jettydiot/example-greenhouse) — sensors + auto-watering
- 🤖 [MCP server](https://www.npmjs.com/package/@jettyd/mcp) — AI agent integration
- 🌐 [jettyd.com](https://jettyd.com)

---

## License

MIT — see [LICENSE](LICENSE).

Built with 🦞 by [jettyd](https://jettyd.com)
