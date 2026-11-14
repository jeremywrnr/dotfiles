# bin

Standalone scripts. This directory is on `$PATH` (see `../zsh/00-path.zsh`), so
adding a file here adds a command — no symlinking, no re-running `install.sh`.

| tool | what it does |
| --- | --- |
| `conv` | convert files between formats: `conv png *.webp`, `conv mp3 *.flac`, `conv jpg *.ARW` |
| `to-mp4` | video → mp4, stream-copying rather than re-encoding when the codecs already suit |
| `set-media-date` | write EXIF/QuickTime dates onto images and videos |
| `screenshare` | Screen Sharing to a Mac through an ssh tunnel, torn down together (`screenshare <host>`) |
| `chrome-dev` | a dedicated Chrome for Testing for agent-driven UI work: its own persistent profile, DevTools on `127.0.0.1:9222` (or `$CHROME_DEV_PORT`), unpacked extensions loaded with `--ext DIR` (`chrome-dev --ext . https://example.com`). `--host HOST` runs it on another machine and tunnels DevTools back, so no window opens here |
| `mirror-github` | mirror a GitHub repo onto the self-hosted Gitea instance |
| `git-remote-setter` | flip a repo's origin between https and ssh (`git remote-setter ssh`) |
| `git-open` | open the repo's web remote in a browser (`git open`) |
| `brewup` | upgrade Homebrew without compiling: bottles and native casks only, each step skipped when there is nothing to do (`--all` for everything); no `brew bundle cleanup` without `../machines/Brewfile` beside the repo |
| `brew-bottled` | list the outdated Homebrew packages that install prebuilt; what `brewup` upgrades, and with `-v` why the rest are held back |
| `git-exec` | run a command in every git repo below the cwd, listing them all first and naming each as it runs (`cd ~/Code && git exec 'pwd && git up'`; `git exec -n` to only list); faster with `bfs` installed |
| `git-tidy` | remove the repo's local branches and worktrees whose work is already in the default branch, squash merges included (`git tidy`; `-n` or `-c` to only list; every repo: `cd ~/Code && git exec git tidy`). Keeps any worktree with uncommitted files, a lock, a rebase or merge under way, a process working in it or less than a day old, and a branch with anything upstream that isn't merged; never deletes on a remote. The old `git cob` alias now runs it |

`conv` and `to-mp4` need `ffmpeg` and ImageMagick; `set-media-date` needs
`exiftool`. Camera raw (`.ARW`, `.CR2`, `.NEF`, ...) goes through `sips` on
macOS rather than ImageMagick, whose raw delegate shells out to `darktable-cli`
and so fails with "command not found" instead of admitting it lacks raw
support; on Linux `conv` uses libraw's `dcraw_emu`. `install.sh` installs all
of them (apt on Linux, Brewfile on macOS).

These absorbed `~/Code/util`, which used to be a separate repo on `$PATH`. Most
of what lived there was one-line wrappers and is now a shell alias or function
in `../zsh/` — see `20-aliases.zsh` and `30-functions.zsh`.
