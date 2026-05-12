# Fall Button — Build Tutorial

End-to-end build guide. Total hands-on time: ~90 minutes spread across about a week (shipping is the slow part).

## Before you start

### Prerequisites

- **Home Assistant running 24/7** on a reliable host (Raspberry Pi, NUC, VM, container — any flavor works). HA Container, HA OS, and HA Supervised are all fine. If you're on HA Container or Supervised, you'll need direct file access to `configuration.yaml`/`secrets.yaml`/`automations.yaml` (typically via SSH or a bind-mounted volume). If you're on HA OS, install the "Terminal & SSH" add-on for the easiest path.
- **A home WiFi network** the button can reach from wherever the wearer typically is.
- **3–5 minutes of cooperation** from each person who needs to receive alerts (they each install one app and toggle a few settings).
- **Comfort with YAML** — you'll paste 3 small blocks into HA config and replace a few placeholder values.

### Parts to order

Order before you start; some take a few days to arrive.

| Item | Approx cost | Notes |
|---|---|---|
| **Shelly Button 1** (WiFi) | $20–30 | Search "Shelly Button 1 WiFi" on Amazon/eBay/the Shelly store. **Confirm it's the WiFi model, NOT "Shelly BLU Button"** (BLU is Bluetooth-only and will not work here). |
| **Breakaway lanyard** | $3 | Search "breakaway safety lanyard". The breakaway part is **non-negotiable** — a non-releasing lanyard around an elderly neck is a strangulation hazard. |

That's the entire parts list. No soldering, no 3D printing, no enclosure work.

### Decide on names and numbers in advance

You'll be asked for these during setup. Have them ready:

- **The wearer's phone number**, in international format with country code (e.g., `+15551234567` for a US number — start with `+1`, no spaces or dashes).
- **The wearer's address**, for the "Open map" button. Doesn't need exact formatting; you'll URL-encode it.
- **The wearer's first name** as it should appear in the notification ("CALL [NAME]"). Use whatever the recipients call them in everyday life — "Mom", "Grandpa", or a first name all work.
- **A short codename for the device** that will appear in HA. Avoid the wearer's real name here if you'd rather their identity not be visible in version-controlled YAML. ("pendant", "panic_button", or a generic word work fine.)

---

## Phase 1 — Set up ntfy and the phone apps

This phase has zero hardware involved. Do it first because it surfaces the most common failure mode (phones not configured to break through Do Not Disturb), and you don't want to discover that during a real emergency.

### 1a. Generate an ntfy topic

The ntfy topic is the private channel on ntfy.sh that your alerts will flow through. Anyone who knows the topic name can read AND post to it, so it needs to be unguessable.

From any terminal:

```bash
echo "fallbutton-$(openssl rand -hex 16)"
```

That produces something like `fallbutton-a1b2c3d4e5f6...` (32 random hex chars). Save it to a password manager or somewhere you won't lose it.

The `fallbutton-` prefix is just for your own memorability when you see it in HA logs. The 32-char random suffix is the actual entropy.

**Treat this topic like a password.** Don't paste it in public chats, screenshots, or commits. If it ever leaks, generate a new one and have everyone re-subscribe.

### 1b. Install ntfy on each recipient's phone

Each person who should get alerts (you, your spouse, the wearer's other family) needs the ntfy app:

- **iOS:** App Store → search "ntfy" → install the orange-bell app by Philipp C. Heckel.
- **Android:** Play Store → same search and publisher. Also available on F-Droid if preferred.

### 1c. Subscribe each phone to the topic

In the ntfy app on each phone:

1. Tap **+** (add subscription).
2. Topic name: paste your random topic.
3. Server: `ntfy.sh` (default, leave it alone).
4. Tap **Subscribe**.

### 1d. Critical step — configure each phone to break through silent mode

This is the step **most people skip**, and it's the difference between an alert that wakes someone up at 3 AM and one they don't hear. Do this on every recipient phone.

**iPhone:**

1. In the ntfy app, tap the topic → top-right settings icon.
2. **Notification sound:** pick something distinctive and loud (e.g., "Alarm" or a long ringtone). Avoid default notification tones — they get tuned out.
3. **Critical Alerts:** turn it on. iOS prompts for permission — tap **Allow**. (If iOS doesn't prompt, go to **iOS Settings → Notifications → ntfy → Critical Alerts** and enable it there.)
4. Verify: **iOS Settings → Notifications → ntfy** — Allow Notifications ON, Lock Screen / Notification Center / Banners all ON, Sounds ON, Critical Alerts ON.

**Android:**

1. Long-press the topic in the ntfy app → Notification settings.
2. Find the topic's channel. Tap it.
3. **Importance:** set to **Urgent** (the top option — produces sound and pops up over other apps).
4. Enable **Override Do Not Disturb** (sometimes labeled "Bypass DND").
5. **Sound:** pick something distinctive and loud. Not silent, not a default tone.
6. **Show on lock screen:** ON.

### 1e. Test fire from a terminal

Verify the chain works before involving Home Assistant or the button.

The script in `ha/ntfy_test_fire.sh` is the easiest way:

```bash
./ha/ntfy_test_fire.sh fallbutton-<your-random-suffix>
# pick option 1 (emergency)
```

Every subscribed phone should buzz **loudly** within ~3 seconds with title "EMERGENCY BUTTON (TEST)" and priority-5 styling.

**Now do the real test — silent mode bypass:**

1. Put one phone on **silent + Do Not Disturb**, lock it, set it down.
2. Fire the test again.
3. Phone should **still** ring/vibrate audibly.

If it doesn't, the Critical Alerts / DND-override step didn't take. Walk through 1d again on that phone. Don't move on until every phone passes the silent-mode test.

---

## Phase 2 — Add the ntfy webhook to Home Assistant

### 2a. Add the rest_command

Edit `/config/configuration.yaml` (or wherever your HA config lives) and append:

```yaml
rest_command:
  ntfy_send:
    url: "https://ntfy.sh/{{ topic }}"
    method: POST
    headers:
      Title: "{{ title }}"
      Priority: "{{ priority | default('3') }}"
      Tags: "{{ tags | default('') }}"
      Click: "{{ click | default('') }}"
      Actions: "{{ actions | default('') }}"
    payload: "{{ message }}"
    content_type: "text/plain; charset=utf-8"
```

**If you already have a `rest_command:` block** (you might, if you've set up other webhooks), don't add a second one — add `ntfy_send:` as a key under the existing `rest_command:`.

### 2b. Add your secrets

Edit `/config/secrets.yaml` and append (substituting your real values):

```yaml
# Fall Button secrets
ntfy_topic_fall: "fallbutton-PASTE-YOUR-RANDOM-TOPIC-HERE"

# Wearer's phone in tel: URL form. E.164 format (+countrycode then number, no spaces or dashes).
wearer_phone_url: "tel:+15551234567"

# Wearer's home address for the "Open map" button.
# IMPORTANT: ntfy parses the Actions header with commas and '+' as syntax tokens.
# The URL inside cannot contain literal commas or plus signs.
# Encode spaces as %20 and drop the address commas — Google Maps still resolves it.
wearer_map_url: "https://maps.google.com/?q=123%20Main%20Street%20Anytown%20CA%2090210"

# ntfy "Actions" header — up to 3 tappable buttons on the notification.
# Keep the phone URL identical to wearer_phone_url above.
# Keep the map URL identical to wearer_map_url above (same encoding rules).
wearer_actions: "view, Call them, tel:+15551234567, clear=true; view, Open map, https://maps.google.com/?q=123%20Main%20Street%20Anytown%20CA%2090210"
```

### 2c. Validate and restart HA

If you have SSH access:

```bash
ssh root@<ha-host> 'ha core check'   # HA OS
# OR for Container/Supervised, run from inside the container:
# python -m homeassistant --script check_config -c /config
```

You should get a clean pass. If not, fix the YAML errors before restarting.

Then restart HA: **Settings → System → Restart Home Assistant**.

### 2d. Sanity-test the webhook from inside HA

Once HA is back up:

1. **Developer Tools → Actions** (older HA versions: "Services").
2. Action: `rest_command.ntfy_send`
3. Switch to **YAML mode** and replace `data: {}` with:

```yaml
topic: fallbutton-PASTE-YOUR-RANDOM-TOPIC-HERE
title: HA test fire
message: If you see this on your phone, HA can talk to ntfy.
priority: "4"
tags: white_check_mark
```

4. Click **Perform action**.

Phones should buzz within ~2 seconds. If they do, the HA → ntfy leg works. If they don't, paste the call result and check the HA logs.

---

## Phase 3 — Pair the Shelly Button to your WiFi

When the button arrives:

1. **Plug the button into USB-C power and keep it plugged in for the entire setup.** It sleeps aggressively on battery — USB power keeps it awake long enough to configure.
2. **Hold the button down for 5+ seconds** until the LED flashes rapidly. That's AP mode. It now broadcasts a WiFi network called `shellybutton1-XXXXXX` (the X's are part of its MAC).
3. **Connect your laptop or phone to that `shellybutton1-XXXXXX` network.** Your OS will warn "no internet" — ignore it.
4. **Browse to `http://192.168.33.1`.** The Shelly web UI loads.
5. **Internet & Security → WIFI MODE - CLIENT** — check "Connect the Shelly device to an existing WiFi Network" → enter your home SSID and password → Save.
6. The button reboots and joins your home network. The `shellybutton1-XXXXXX` AP disappears.
7. **Find its new IP** in your router's DHCP client list. It will appear as `shellybutton1-XXXXXX` or similar. The MAC will start with one of the Shelly OUIs (search the term — Shelly publishes several). Verify by browsing to the IP — the Shelly UI should load.
8. **Reserve a static DHCP lease** for the button's MAC in your router. Critical step. Without it, the button could land on a different IP after a long power-off and HA loses track of it.

---

## Phase 4 — Update Shelly firmware

Shelly buttons shipped from some sellers can be running **very old** firmware (2020-era). Newer firmware adds important features (CoIoT peer support for reliable HA event delivery) and fixes bugs.

Check what's there:

```bash
curl http://<shelly-ip>/shelly
```

You'll see a `fw` field. If it starts with `2020` or `2021`, update. If it's `2023` or newer, you can skip ahead.

Update via API (this is the same thing the web UI's "Update Firmware" button does):

```bash
curl "http://<shelly-ip>/ota?update=true"
```

Wait ~90 seconds. The device downloads, flashes, reboots. Settings persist across the update. Verify:

```bash
curl http://<shelly-ip>/shelly | grep fw
```

The `fw` field should now show `v1.14.0` or newer.

---

## Phase 5 — Configure the Shelly

A few API calls to set up the button for HA integration. Run all four:

```bash
SHELLY=<shelly-ip>
HA=<home-assistant-ip>

# Give it a friendly name
curl "http://$SHELLY/settings?name=panic_button"

# Point CoIoT at HA for reliable event delivery (works after fw update only)
curl "http://$SHELLY/settings?coiot_peer=$HA:5683"

# Verify
curl http://$SHELLY/settings | grep -E '"name"|coiot'
```

You should see `"name":"panic_button"` and `coiot` showing `"peer":"<HA_IP>:5683"`.

---

## Phase 6 — Add the Shelly to Home Assistant

1. **HA UI → Settings → Devices & Services**
2. Look at the top for a discovered devices card. HA's Shelly integration normally auto-discovers via mDNS. If you see your button there, click **Configure** and accept the prompts.
3. If it's NOT auto-discovered, click **+ Add Integration** (bottom right) → search **Shelly** → enter the button's IP → submit.
4. Pick an area for the device (the wearer's room, "Living Room", whatever makes sense).

### Find the device_id and battery entity

For the automations to work, you need two IDs from the device page:

1. **Device ID.** Open **Settings → Devices & Services → Shelly → [your device]**. The URL in your browser's address bar ends in `/config/devices/device/<long_hex_id>`. Copy that hex string.
2. **Battery entity_id.** On the same device page, find the Battery entity in the entity list. Its name will be `sensor.shellybutton1_<mac>_battery` or similar. Copy the entity_id.

---

## Phase 7 — Add the three automations

Append the contents of [ha/automations.yaml.snippet](ha/automations.yaml.snippet) to your `/config/automations.yaml`. Replace **three** placeholders throughout:

- `<DEVICE_ID>` → the long hex device ID from Phase 6.
- `<BATTERY_ENTITY>` → the full battery entity_id from Phase 6 (e.g., `sensor.shellybutton1_aabbccddeeff_battery`).
- `<WEARER_NAME>` → first name as it should appear in the notification title and body. Used in two places: the title (`<WEARER_NAME> EMERGENCY BUTTON`) and the persistent-notification text.

The three automations you're adding:

1. **`fall_button_emergency`** — fires on ANY press of the button. Calls `rest_command.ntfy_send` with priority 5, an emergency title, and the click-to-call action. Includes a 30-second `delay` at the end of the action block to suppress duplicate flailing presses while `mode: single` is in effect.
2. **`fall_button_low_battery`** — fires when battery drops below 20%. Lower-priority alert reminding you to charge.
3. **`fall_button_offline_watchdog`** — runs every 6 hours. If the battery sensor hasn't updated in over 36 hours, it sends an alert. Catches the "dead battery you didn't notice" silent failure.

Validate and restart HA (`ha core check && ha core restart` if you have SSH; or via the UI).

---

## Phase 8 — Test end-to-end

This is the moment of truth.

1. **Unplug the Shelly from USB** so it's running on battery (as it will in actual use).
2. **Press the button once briefly.**
3. Within ~3 seconds, every subscribed phone should buzz with:
   - Title: `<WEARER_NAME> EMERGENCY BUTTON`
   - Body: time of press, "call them now or check on them"
   - Two action buttons: **Call them** and **Open map**
4. **Tap the alert** on one phone. Phone dialer should open with the wearer's number pre-filled.
5. **Press the button two more times within 30 seconds.** Verify you only got ONE notification (the cooldown swallowed the duplicates).
6. **Wait 35+ seconds**, press again. Verify a new notification arrives.

If any of those don't work, see [OPERATIONS.md → Troubleshooting](OPERATIONS.md#troubleshooting).

---

## Phase 9 — Lanyard and placement

1. Thread the breakaway lanyard through the loop on the back of the Shelly Button.
2. Adjust the lanyard length so the button sits at mid-chest when worn — close enough to the wearer's dominant hand that they can press it without looking.
3. Show the wearer:
   - Where the button lives (worn always, or on a nightstand at minimum).
   - How to press it (a single firm press; no need to hold).
   - That the device will vibrate / make no obvious confirmation. They should trust that it sent.
   - That they'll get a phone call from a family member within seconds if everyone's reachable.

---

## You're done

The button is in production. See [OPERATIONS.md](OPERATIONS.md) for periodic testing, battery management, and troubleshooting.
