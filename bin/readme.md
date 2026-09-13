# bin

Standalone scripts. This directory is on `$PATH` (see `../zsh/00-path.zsh`), so
adding a file here adds a command — no symlinking, no re-running `install.sh`.

| tool | what it does |
| --- | --- |
| `conv` | convert files between formats: `conv png *.webp`, `conv mp3 *.flac`, `conv jpg *.ARW` |
| `to-mp4` | video → mp4, stream-copying rather than re-encoding when the codecs already suit |
| `set-media-date` | write EXIF/QuickTime dates onto images and videos |
| `net` | ping-loop until the connection comes back, reporting total downtime |
| `mirror-github` | mirror a GitHub repo onto the self-hosted Gitea instance |
| `git-remote-setter` | flip a repo's origin between https and ssh (`git remote-setter ssh`) |
| `git-open` | open the repo's web remote in a browser (`git open`) |
| `git-exec` | run a command in every git repo below the cwd, naming each one first (`cd ~/Code && git exec 'pwd && git up'`) |

`conv` and `to-mp4` need `ffmpeg` and ImageMagick; `set-media-date` needs
`exiftool`. Camera raw (`.ARW`, `.CR2`, `.NEF`, ...) goes through `sips` on
macOS rather than ImageMagick, whose raw delegate shells out to `darktable-cli`
and so fails with "command not found" instead of admitting it lacks raw
support; on Linux `conv` uses libraw's `dcraw_emu`. `install.sh` installs all
of them (apt on Linux, Brewfile on macOS).

These absorbed `~/Code/util`, which used to be a separate repo on `$PATH`. Most
of what lived there was one-line wrappers and is now a shell alias or function
in `../zsh/` — see `20-aliases.zsh` and `30-functions.zsh`.
