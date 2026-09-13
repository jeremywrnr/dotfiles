# bin

Standalone scripts. This directory is on `$PATH` (see `../zsh/00-path.zsh`), so
adding a file here adds a command — no symlinking, no re-running `install.sh`.

| tool | what it does |
| --- | --- |
| `conv` | convert files between formats: `conv png *.webp`, `conv mp3 *.flac`, `conv gif clip.mp4` |
| `to-mp4` | video → mp4, stream-copying rather than re-encoding when the codecs already suit |
| `set-media-date` | write EXIF/QuickTime dates onto images and videos |
| `net` | ping-loop until the connection comes back, reporting total downtime |
| `tm` | Time Machine health: how old the last *complete* backup is, why the last one failed, whether there is room for the next |
| `mirror-github` | mirror a GitHub repo onto the self-hosted Gitea instance |
| `git-remote-setter` | flip a repo's origin between https and ssh (`git remote-setter ssh`) |
| `git-open` | open the repo's web remote in a browser (`git open`) |

`tm` is macOS-only. `install.sh` loads a launchd agent that runs `tm check`
every four hours and notifies only when something is wrong — see
`../launchd/com.jeremy.tm-check.plist`.

macOS gates Time Machine's prefs *and* the backup volume's directory listing
behind Full Disk Access, which a terminal has and a launchd agent does not, so
`tm` reads two ways: with access it reports the exact age of the last complete
backup, and without it falls back to the unified log, which is ungated and still
catches the case that matters (the last attempt failed). Adding `/bin/bash`
under Privacy & Security → Full Disk Access gives the agent the precise view
too, at the cost of handing every shell script that access.

`conv` and `to-mp4` need `ffmpeg` and ImageMagick; `set-media-date` needs
`exiftool`. `install.sh` installs all of them (apt on Linux, Brewfile on macOS).

These absorbed `~/Code/util`, which used to be a separate repo on `$PATH`. Most
of what lived there was one-line wrappers and is now a shell alias or function
in `../zsh/` — see `20-aliases.zsh` and `30-functions.zsh`.
