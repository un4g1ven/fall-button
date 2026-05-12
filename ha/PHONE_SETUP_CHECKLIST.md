# Phone Setup Checklist

**Send this to every person who should get alerts.** Walk through it with them together if needed — the Critical Alerts / DND-bypass step is the one most people miss, and it's the difference between an alert that wakes them at 3 AM and one they sleep through.

You'll need:

- The ntfy topic name (the person setting up will send this to you privately).
- 5 minutes.

---

## Step 1 — Install the ntfy app

- **iPhone:** App Store → search "ntfy" → install the orange-bell app by Philipp C. Heckel.
- **Android:** Play Store → same search and publisher. (F-Droid also works.)

---

## Step 2 — Subscribe to the alert topic

1. Open ntfy.
2. Tap **+**.
3. Topic name: paste the topic you were sent.
4. Server: `ntfy.sh` (leave the default).
5. Tap **Subscribe**.

---

## Step 3 — Configure for emergency-grade alerts (the important step)

Without this, the alert is just a regular notification you might miss when the phone is on silent. **Do this now, or the system doesn't work for you.**

### iPhone

1. In ntfy, tap the topic → top-right gear icon.
2. **Notification sound:** pick something distinctive (suggestion: "Alarm" or a long, attention-grabbing ringtone — NOT a default notification tone you'd tune out).
3. **Critical Alerts:** turn it on.
   - iOS will ask permission. Tap **Allow**.
   - This lets the alert break through Do Not Disturb and silent mode.
4. Open **iOS Settings → Notifications → ntfy** and verify:
   - Allow Notifications: ON
   - Lock Screen / Notification Center / Banners: all ON
   - Sounds: ON
   - Critical Alerts: ON

### Android

1. Long-press the topic in ntfy → **Notification settings**.
2. Tap into the channel for this topic.
3. **Importance:** set to **Urgent** (the top option — makes sound and pops up).
4. **Override Do Not Disturb:** enable (also called "Bypass DnD" on some Android versions).
5. **Sound:** pick something distinctive. Avoid silence or a tone you've already learned to ignore.
6. **Show on lock screen:** ON.
7. **Battery optimization:** **Android Settings → Apps → ntfy → Battery → Unrestricted.** Some manufacturers (Samsung, Xiaomi, OnePlus) kill background apps to save battery; this exempts ntfy.

---

## Step 4 — Save the wearer's contact

Make sure the wearer is in your contacts under their real name. The emergency notification has a "Call them" button that opens the dialer — easier if your phone shows "Calling Mom" rather than just `+1 555-1234567`.

---

## Step 5 — Test

The person setting up will fire a test notification. You should:

- [ ] See an alert on your lock screen even if your phone was on silent.
- [ ] Hear the alert sound you picked.
- [ ] Be able to tap "Call them" and have the dialer open with the right number.

If anything doesn't work, redo **Step 3** — that's where it almost always goes wrong.

---

## Reminders

- **Don't mute or unsubscribe from the topic.** Even if you don't see a real alert for a year, leave it alone.
- **If you get a new phone**, you MUST redo Steps 1–3 on the new device. The old setup doesn't migrate.
- **Periodic test fires are normal** — every 6–8 weeks, the person setting up will press the button briefly and ask everyone to confirm their phone buzzed. This is how we catch a phone whose settings have drifted.
