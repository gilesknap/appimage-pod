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

> **DLS users:** AppImage extractions land in `~/.cache/app-image-podman/`
> and can fill your home quota fast (a single Krita extraction is several
> hundred MB). Move `~/.cache` out of your home dir before you start —
> see [Disk quota — moving .cache][dls-quota].

[dls-quota]: https://dev-guide.diamond.ac.uk/linux-user-environment/how-tos/disk-quota/

## Quick Start

Drop the launch script into your `$HOME/bin` and make it executable:

```bash
cd $HOME/bin
curl -fsSL https://codeload.github.com/gilesknap/appimage-pod/tar.gz/refs/heads/main \
  | tar xz --strip-components=1 appimage-pod-main/appimage-pod
chmod +x appimage-pod
```

> We pull through `codeload.github.com` rather than
> `raw.githubusercontent.com` because the latter is fronted by a 5-minute
> Fastly cache that ignores `Cache-Control: no-cache` and query-string
> cache-busters. `codeload` serves the tarball fresh, so the snippet
> always lands the latest commit.

Then run any AppImage. You can pass a URL — the AppImage will be
downloaded, extracted, and run in one step. For example, [Krita] (a
free digital painting program) ships as an AppImage:

```bash
appimage-pod https://download.kde.org/stable/krita/5.3.1/krita-5.3.1-x86_64.AppImage
```

[Krita]: https://krita.org/

…or a local file:

```bash
appimage-pod ~/Downloads/UaExpert-2.0.1-x86_64.AppImage
```

The first invocation pulls `ghcr.io/gilesknap/appimage-pod:latest` and
extracts the AppImage to `~/.cache/app-image-podman/<Name>/`. Subsequent
invocations reuse both.

After the first run the original `.AppImage` (or URL) is no longer
needed: the extraction lives in the cache. Re-launch by bare name:

```bash
appimage-pod krita
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
appimage-pod [--name NAME] [--rebuild-image] [--re-extract] <AppImage|URL|name> [args...]
appimage-pod --show
```

The positional argument can be:

- a **path** to a local `.AppImage` file (extracted on first use, then cached),
- an **http(s) URL** (downloaded into the cache, then extracted), or
- a **bare name** that already exists in the cache (e.g. `UaExpert`).

After the first run from a file or URL, the original is no longer needed —
re-launch by name.

| Flag | Effect |
|------|--------|
| `--name NAME`     | Override the derived app name (used for the per-app cache and config dirs). Default: derived from the AppImage filename, the URL basename, or the positional argument in name mode. |
| `--rebuild-image` | Force rebuild of the runtime image from `./Containerfile` (only useful from a clone). |
| `--re-extract`    | Force re-extraction of the AppImage (only valid when launching from a file path or URL). |
| `--show`          | List all cached AppImages and exit. |

## Trying it out

A few good AppImages to smoke-test the runtime:

```bash
# appimagetool — small (~15MB), reference AppImage from the AppImage project
appimage-pod https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage --version

# Krita — a digital painting program; heavyweight, exercises Qt/OpenGL/multimedia
appimage-pod https://download.kde.org/stable/krita/5.3.1/krita-5.3.1-x86_64.AppImage
```

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
