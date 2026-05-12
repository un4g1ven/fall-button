# Fall Button

**A DIY wearable emergency button for ~$28 one-time, $0/month forever.**

When pressed, a button worn on a lanyard fires a max-priority, Do-Not-Disturb-bypassing alert to every family member's phone. Tap the alert and your phone dials the wearer immediately. The "Open map" action button opens a map to their home address. No subscriptions, no vendor lock-in, no cellular fees.

```
   [Shelly Button 1]  ─── WiFi press ──>  [Home Assistant]
                                                │
                                                ▼
                                       rest_command.ntfy_send
                                                │
                                                ▼
                                    POST https://ntfy.sh/<topic>
                                                │
                          ┌─────────────────────┼─────────────────────┐
                          ▼                     ▼                     ▼
                  [family phone 1]     [family phone 2]     [family phone N]
                          │                     │                     │
                          └─────── tap ─────────┴───── tap ───────────┘
                                                │
                                                ▼
                                  dialer opens, calls the wearer
```

## Who this is for

You have a parent, grandparent, or loved one who might fall, lock themselves out, or otherwise need help. You want them to be able to summon help with a single button press. You don't want to pay $30–60/month for a commercial medical alert pendant.

You're also comfortable with:

- A bit of YAML editing
- A self-hosted [Home Assistant](https://www.home-assistant.io/) instance that runs 24/7
- Walking family members through installing a small mobile app

If any of that sounds intimidating, this isn't the project for you — and that's fine. Commercial alternatives are a click away.

## What this is NOT

**This is a supplement, not a replacement, for a monitored medical alert system.**

- It requires the wearer to be **conscious** and **able to press a button**. Unconscious falls won't be detected.
- It depends on **WiFi**. If their router is down, presses go nowhere.
- It depends on **Home Assistant** being up. If your HA box is rebooting, presses go nowhere.
- It depends on **your phones being on a network**. Out of cell range = no alert.

For the worst cases (unconscious fall, no WiFi), pair this with an Apple Watch (fall detection) or a monitored cellular pendant. Use Fall Button for the much more common case: "I fell and I can press a button but I can't get to a phone."

## Costs

| Item | One-time | Recurring |
|---|---|---|
| Shelly Button 1 (WiFi) | ~$25 | — |
| Lanyard with breakaway clasp | ~$3 | — |
| Home Assistant | $0 (already running) | $0 |
| ntfy.sh notification service | $0 | $0 (free tier easily covers personal use) |
| **Total** | **~$28** | **$0/month** |

## What's in this repo

- **[TUTORIAL.md](TUTORIAL.md)** — Step-by-step build guide from unboxing to first successful press. ~90 minutes end-to-end.
- **[OPERATIONS.md](OPERATIONS.md)** — Ongoing maintenance, periodic testing, troubleshooting common failures.
- **[ha/](ha/)** — Drop-in HA YAML snippets and the ntfy test-fire script.

## Architecture decisions worth understanding before you build

These are the design choices that matter, briefly:

- **Long-press vs any-press.** This repo defaults to **any press fires an alert**. A panicking elderly person cannot be relied on to hold a button for 1.5 seconds. The cost of a false alarm (annoying phone call) is much lower than the cost of a missed real emergency. If accidental presses become a problem, recess the button under a guard — don't switch back to long-press. A 30-second cooldown is already in place to suppress flailing duplicates.
- **One ntfy topic, all phones subscribe.** A single notification reaches every subscriber. No per-recipient configuration on the HA side.
- **Critical Alerts / DND bypass.** The whole point of this is that the alert breaks through silent mode at 3 AM. The [phone setup checklist](ha/PHONE_SETUP_CHECKLIST.md) walks each recipient through enabling it.
- **No cloud dependencies that cost money.** Shelly Cloud is disabled. ntfy.sh is free. Home Assistant is self-hosted. The only thing on a third-party server is the notification relay — which is fine, because the message body contains no personally identifying information beyond what you put in it.

## License

MIT. Use it, fork it, share it with families who need it.

## Contributing

If you build this and discover a better way to do something — a phone-config gotcha I missed, a router quirk, a Shelly firmware bug — open an issue or PR. This document gets better the more families use it.
