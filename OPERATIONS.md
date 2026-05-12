# Fall Button — Operations Guide

How to keep this thing working over months and years.

## Routine maintenance

### Quarterly: test the full chain

**Every 6–8 weeks**, do a live test:

1. Press the button once.
2. Confirm **every** subscribed phone buzzed within ~3 seconds.
3. Tap the alert on one phone, confirm the dialer opens with the wearer's number.

If any phone didn't buzz, that phone's Critical Alerts / DND-bypass config has drifted (after an OS update, app reinstall, or new device). Walk through [TUTORIAL.md Phase 1d](TUTORIAL.md#1d-critical-step--configure-each-phone-to-break-through-silent-mode) again on the silent phone.

Don't skip this. Phones reset notification permissions surprisingly often, and you don't want to discover that during a real emergency.

### When you (or recipients) get a new phone

You **must** redo Phase 1b–1d on the new device. Old phone keeps working, but the new phone is silent until you reconfigure. Add it to your migration checklist.

### Charging

Battery on a Shelly Button 1 lasts ~6 months between charges with daily heartbeat traffic. The `fall_button_low_battery` automation texts everyone when it drops below 20% — that's your cue to bring it home for an overnight USB-C charge.

If the wearer is reluctant to part with it, charge it at a regular time (e.g., overnight every 5 months by calendar reminder) rather than waiting for the low-battery alert. The low-battery alert is a safety net, not a primary signal.

### Firmware updates

Shelly publishes firmware updates periodically. Before applying, **read the changelog** to make sure they don't change CoIoT behavior in a way that would break the HA integration.

To update:

```bash
curl "http://<shelly-ip>/ota?update=true"
```

Or via the Shelly's web UI at `http://<shelly-ip>` → Settings → Firmware → Update.

After updating, re-test the full chain (press the button, confirm all phones buzz). Firmware updates have, on occasion, reset settings like CoIoT peer — verify those are still pointed at HA:

```bash
curl http://<shelly-ip>/settings | grep coiot
```

---

## Troubleshooting

### A phone didn't buzz on a press

Most common causes, in order of likelihood:

1. **Critical Alerts / DND-bypass got disabled on that phone.** Most likely after an iOS update or ntfy app update. Fix: redo [TUTORIAL.md Phase 1d](TUTORIAL.md#1d-critical-step--configure-each-phone-to-break-through-silent-mode) on the silent phone.
2. **The phone is offline / out of cell coverage / on airplane mode.** ntfy delivers when the phone reconnects, but that's too late for an emergency. Educate recipients to keep their phones on a network.
3. **They unsubscribed from the topic by accident.** Open the ntfy app, verify the topic is still listed and not muted.
4. **The ntfy app got force-killed by aggressive Android battery-saving.** Some Android OEMs (Samsung, Xiaomi, OnePlus) kill background apps to save battery. Exempt the ntfy app from battery optimization in **Android Settings → Apps → ntfy → Battery → Unrestricted**.

### NO phone buzzed on a press

If *no* phone got the alert, the failure is upstream of the phones. Check in order:

1. **Did the HA automation fire?** **Settings → Automations & Scenes → fall_button_emergency** — look at "Last triggered". If it didn't fire recently, the button isn't reaching HA. Skip to step 3.
2. **Did the rest_command call succeed?** Check **Developer Tools → Logs** for any `rest_command` or `ntfy` errors. A 401 means your topic name has a typo or got rotated; a 400 means a payload formatting bug (especially around the Actions header — see the [URL encoding gotcha](#ntfy-actions-header-rejects-the-url)).
3. **Is the button reaching HA at all?** Run:
   ```bash
   curl http://<shelly-ip>/status | grep -i input
   ```
   You should see `inputs:[{event:"S",...}]` (or `"L"` for a long press) immediately after a press. If the button itself isn't registering the press, the button hardware is the problem (check battery, check that the button click feels firm).
4. **Is CoIoT working?** HA's Shelly integration needs CoIoT to receive events from battery-sleep devices like the Button 1. Verify:
   ```bash
   curl http://<shelly-ip>/settings | grep coiot
   ```
   Should show `"peer":"<HA_IP>:5683"`. If it shows no peer, re-apply via the API (`/settings?coiot_peer=<HA_IP>:5683`).

### The "Call them" button doesn't dial

Most common cause: the phone number in `wearer_phone_url` isn't in proper `tel:` URL format.

- ✅ `tel:+15551234567` — correct (E.164, leading +, country code, no spaces)
- ❌ `tel:555-123-4567` — works on some platforms but inconsistent
- ❌ `(555) 123-4567` — missing `tel:` prefix
- ❌ `+1 555 123 4567` — spaces break it on some Android dialers

Fix in `/config/secrets.yaml` and restart HA.

### The "Open map" button doesn't open / opens to the wrong place

The `wearer_map_url` and `wearer_actions` URLs **cannot contain literal commas or plus signs**. ntfy's Actions header parser uses `,` as a parameter separator and `+` as a grammar token, so any URL containing them inside an Actions header gets rejected or mangled.

Use this format:

```yaml
wearer_map_url: "https://maps.google.com/?q=123%20Main%20Street%20Anytown%20CA%2090210"
```

- Spaces → `%20`
- No commas in the address part
- No `+` characters

Google Maps resolves the bare-tokens address fine without commas.

### ntfy Actions header rejects the URL

If the HA log shows `code: 40018, error: "actions invalid; term 'XYZ' unknown"`, it's the URL-in-actions parsing issue above. Re-encode the URL per the previous section.

### HA can't reach the Shelly Button anymore (the device shows "unavailable")

1. Verify the button is on the network: `ping <shelly-ip>` from the HA host.
2. If unreachable, check the button physically — is it still on? Battery dead?
3. If reachable but HA still shows it unavailable, restart the HA Shelly integration: **Settings → Devices & Services → Shelly → ⋯ → Reload**.
4. If the IP changed (no DHCP reservation): browse to the new IP, then in HA: **Settings → Devices & Services → Shelly → [device] → Configure → Edit host**, update the IP. Then immediately add a DHCP reservation in your router so it can't happen again.

### Watchdog firing falsely ("button is silent")

The `fall_button_offline_watchdog` automation fires when the battery sensor hasn't updated in 36+ hours. This *should* only happen if the device is genuinely offline. False positives usually mean:

1. **The button is charging and not waking up to report.** Some firmware versions don't update sensors while plugged in. After unplugging, it should resume normal heartbeat behavior within a few hours.
2. **CoIoT lost its way after a router reboot.** Re-apply the CoIoT peer setting via `curl "http://<shelly-ip>/settings?coiot_peer=<HA_IP>:5683"` and wait for the next press or wake cycle.
3. **Threshold too aggressive.** If your button naturally goes 24+ hours without a press in normal use, edit the automation and raise the threshold from `36 * 3600` to `72 * 3600` (3 days).

### "I'm getting too many false alarms — she keeps accidentally pressing it"

If the button is getting pressed too easily (e.g., by clothing, by being slept on), the fix is **mechanical, not software**. Do not switch back to long-press triggering — that defeats the entire reliability gain. Instead:

- **Recess the button face** so clothing or skin pressure can't activate it. A small printed guard, a piece of foam with a hole, or a button cover from a hobby shop.
- **Wear-style change** — switch from pendant-on-chest to wristband (often easier to position so it doesn't get pressed accidentally during sleep).
- **Increase the cooldown** in `fall_button_emergency`: change `delay: "00:00:30"` to `"00:02:00"` so noisy presses produce one alert per 2-minute window.

---

## Adding more recipients later

To add a 4th, 5th, 6th phone:

1. Install ntfy on the new phone.
2. Subscribe to the **same** topic name (it's in your password manager / `ntfy_topic_fall` secret).
3. Configure Critical Alerts / DND-bypass on the new phone ([TUTORIAL.md Phase 1d](TUTORIAL.md#1d-critical-step--configure-each-phone-to-break-through-silent-mode)).
4. Fire a test from `ntfy_test_fire.sh` and confirm the new phone buzzes.

No HA-side changes needed. ntfy delivers to every subscriber automatically.

To **remove** a phone (someone moved away, no longer needs to be on the alert list): they just unsubscribe in the app. No change on your side.

---

## Adding more buttons later

You can deploy a second button (e.g., one for each of two grandparents) without much work:

1. Order another Shelly Button 1.
2. Repeat Tutorial Phases 3–7 for the new button, with a different device name (e.g., `dad_button`) and a different `<DEVICE_ID>`.
3. Decide whether to use the **same ntfy topic** (everyone alerts the same group) or a **different topic per wearer** (different recipients for each).
4. Add a parallel set of automations in `automations.yaml` using the new device's IDs.

For multiple wearers in the same household, same topic with a different message body (so recipients know who pressed) is usually simplest. The `title` field is the right place to differentiate.

---

## When to walk away from this system

A few scenarios where you should **stop relying on Fall Button** as the primary safety tool:

- **The wearer's cognition has declined to the point they can't form the intent to press a button.** Switch to a passive system (Apple Watch fall detection, in-home camera with AI fall detection, or a monitored cellular pendant).
- **They've stopped wearing it.** Stick-to-the-wrist friction means many elderly users abandon pendants within months. If you find it sitting in a drawer for weeks, it's not protecting them.
- **Repeated false alarms are causing fatigue.** If recipients start ignoring "another false alarm" notifications, the system has failed in a worse way than not existing. Either fix the false-alarm rate (recess the button, change wear style) or shut it down and switch to something passive.

The point of the Fall Button isn't to exist; it's to summon help when it's needed. Be honest about whether it's still serving that purpose.
