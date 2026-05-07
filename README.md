# appimage-pod

Run any Linux AppImage inside a [podman] container, with X11 forwarding and
per-app persistent state. The container provides the GUI runtime libraries
(Qt5/Qt6, GTK3, X11/xcb, multimedia); the AppImage itself is extracted to a
host cache and bind-mounted in at runtime — so a single image works for any
AppImage and rebuilding for a new app takes seconds.

| | |
|:---:|:---:|
| Source | <https://github.com/gilesknap/appimage-pod> |
| Image  | `ghcr.io/gilesknap/appimage-pod:latest` |
| Releases | <https://github.com/gilesknap/appimage-pod/releases> |

## Quick Start

Drop the launch script into your `$HOME/bin` and make it executable:

```bash
cd $HOME/bin
curl -O https://raw.githubusercontent.com/gilesknap/appimage-pod/main/appimage-pod
chmod +x appimage-pod
```

Then run any AppImage:

```bash
appimage-pod ~/Downloads/UaExpert-2.0.1-x86_64.AppImage
```

The first invocation pulls `ghcr.io/gilesknap/appimage-pod:latest` and
extracts the AppImage to `~/.cache/app-image-podman/<Name>/`. Subsequent
invocations reuse both.

After the first run the original `.AppImage` file is no longer needed:
the extraction lives in the cache. Re-launch by bare name:

```bash
appimage-pod UaExpert
```

List what's currently cached:

```bash
appimage-pod --show
```

> If you don't have `$HOME/bin`, create it with `mkdir $HOME/bin`. It will
> be added to `$PATH` in any new shells; your current shell won't see it
> until you reopen it.

## How it works

- **Runtime image** — Ubuntu 24.04 plus the system libs that AppImages
  typically link against (libc, libstdc++, libGL, the xcb stack, GTK3,
  multimedia, secrets, fonts). AppImages bundle their own toolkit (Qt
  etc.) so the image only needs the host-level dependencies.
- **AppImage extraction** — done once on the host. The Type-2 AppImage
  magic bytes are zeroed on a copy so the runtime can be exec'd as a
  plain ELF (without `binfmt_misc` registration), then `--appimage-extract`
  produces a tree the container bind-mounts at `/opt/app`. The script
  re-extracts only if the source AppImage's sha256 changes.
- **Per-app state** — `~/.config/app-image-podman/<Name>/` is mounted as
  the container's `$HOME`. Whatever the app writes anywhere under `$HOME`
  (XDG dirs, dotfiles, caches) ends up captured in that one tree per app.

## Usage

```
appimage-pod [--name NAME] [--rebuild-image] [--re-extract] <AppImage|name> [args...]
appimage-pod --show
```

The positional argument is either a path to an `.AppImage` file or a bare
name that already exists in the cache (e.g. `UaExpert`). A bare name skips
the extraction step entirely — the original file can be deleted once it's
been cached on first run.

| Flag | Effect |
|------|--------|
| `--name NAME`     | Override the derived app name (used for the per-app cache and config dirs). Default: derived from the AppImage filename, or from the positional argument when launching by name. |
| `--rebuild-image` | Force rebuild of the runtime image from `./Containerfile` (only useful from a clone). |
| `--re-extract`    | Force re-extraction of the AppImage (only valid when launching from a file path). |
| `--show`          | List all cached AppImages and exit. |

| Env var | Effect |
|---------|--------|
| `APP_IMAGE_PODMAN_IMAGE` | Override the runtime image reference. |

## Building from source

```bash
git clone https://github.com/gilesknap/appimage-pod
cd appimage-pod
./appimage-pod --rebuild-image ~/Downloads/Some.AppImage
```

[podman]: https://podman.io/
