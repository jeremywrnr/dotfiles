# GameCube controller adapter

Input Integrity / Wii U adapter, USB id `057e:0337`. Linux has no kernel driver
for it: `usbhid` binds the interface but the report descriptor is vendor
specific and the adapter stays silent until it gets a `0x13` init command.

Two mutually exclusive ways to drive it — only one process can own the device.

**Dolphin / Slippi (the default).** Nothing bound to the adapter; Dolphin claims
it over libusb as "GameCube Adapter for Wii U". Lowest latency, and what Slippi
expects. Needs only `51-gcadapter.rules`, which grants the `plugdev` group
access to the adapter and to `/dev/uinput`.

**Everything else.** `wii-u-gc-adapter` detaches `usbhid` and re-exposes all
four ports as `js0`–`js3` via uinput, for Steam, RetroArch and friends. Build it
from https://github.com/ToadKing/wii-u-gc-adapter into `~/Code/wii-u-gc-adapter`
(needs `build-essential libusb-1.0-0-dev libudev-dev`).

    systemctl --user start wii-u-gc-adapter   # generic gamepad
    systemctl --user stop  wii-u-gc-adapter   # back to Dolphin

The unit is installed but **not enabled at boot**, on purpose: leaving it running
makes Dolphin report "Adapter Not Detected".
