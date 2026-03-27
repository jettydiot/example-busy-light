---
name: busy-light
description: "AI-powered busy light — checks Google Calendar and sets an LED to red (in meeting), amber (meeting soon), or green (free)."
---

# Busy Light Skill

Checks Google Calendar every 5 minutes and sends commands to a jettyd busy-light device.

## Setup

1. Flash the ESP32 with this firmware project
2. Set `JETTYD_API_KEY` and `DEVICE_ID` environment variables
3. Set up a cron job: every 5 minutes, run `agent/busy-light-cron.sh`

## How it works

| Calendar state | LED color | Command sent |
|---|---|---|
| In a meeting now | 🔴 Red | `switch_on red` |
| Meeting in < 10 min | 🟡 Amber | `switch_on amber` |
| Free | 🟢 Green | `switch_on green` |

## Requirements

- `gog` CLI (Google Calendar access via OpenClaw)
- jettyd API key
- Device provisioned and online
