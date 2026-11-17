# Jellyfin with rffmpeg

The official [Jellyfin](https://jellyfin.org) image with
[rffmpeg](https://github.com/joshuaboniface/rffmpeg) added, so transcodes can run on another host
over SSH. Based on [Shadowghost/jellyfin-rffmpeg](https://github.com/Shadowghost/jellyfin-rffmpeg).

## What the image adds

- `rffmpeg` at `/usr/local/bin/rffmpeg`, with `ffmpeg` and `ffprobe` symlinked to it in
  `/usr/local/bin`.
- `openssh-client`, `python3-click` and `python3-yaml`.
- An entrypoint that lets the container run as any UID. `ssh` refuses to start for a UID with no
  passwd entry, so when the running UID isn't in `/etc/passwd`, the entrypoint writes a `jellyfin`
  entry for it (home `$JELLYFIN_DATA_DIR`) to `/tmp` and loads it with
  [`libnss_wrapper`](https://cwrap.org/nss_wrapper.html). `/tmp` has to be writable; the rest of
  the root filesystem can be read-only.

Jellyfin itself starts as before, and keeps using its own ffmpeg until you point it at rffmpeg.

## Using it

1. Set `JELLYFIN_FFMPEG=/usr/local/bin/ffmpeg`.
2. Mount a config at `/etc/rffmpeg/rffmpeg.yml`, or set `RFFMPEG_CONFIG` to another path. Without
   one, rffmpeg uses its defaults. See
   [`rffmpeg.yml.sample`](https://github.com/joshuaboniface/rffmpeg/blob/master/rffmpeg.yml.sample).
3. Make these writable and persistent where needed:
   - the state directory, `/var/lib/rffmpeg` by default, which holds the host database;
   - the SSH persistence directory, `/run/shm` by default.
4. Mount the SSH private key and pass it in the config's `remote.args`.
5. Set `TMPDIR` to a directory the transcode hosts also mount. Jellyfin 10.10 and later need this.
6. Mount the media and the transcode directory at the same paths on the transcode hosts as in the
   container. rffmpeg passes paths through unchanged.
7. Run `rffmpeg init` (add `--no-root` when the container doesn't run as root), then
   `rffmpeg add <host>`:

   ```sh
   docker exec -it jellyfin rffmpeg init
   docker exec -it jellyfin rffmpeg add <host>
   docker exec -it jellyfin rffmpeg status
   ```

The transcode hosts need `jellyfin-ffmpeg` and an SSH user with the container's UID and GID.

If no host is reachable, rffmpeg runs ffmpeg locally. That fallback uses the same arguments, so it
only works if the container can do whatever hardware acceleration Jellyfin is set to use.

## Building

```sh
docker build -t jellyfin-rffmpeg .
```

| Build arg | Default |
| --- | --- |
| `RFFMPEG_REPO` | `https://github.com/joshuaboniface/rffmpeg.git` |
| `RFFMPEG_COMMIT` | the commit pinned in the `Dockerfile` |

`RFFMPEG_REPO` has to be a git URL ending in `.git`. BuildKit only clones URLs that look like git
repositories; any other `https://` URL is downloaded as a plain file, which ignores
`RFFMPEG_COMMIT` and, for a repository's web page, saves the HTML as `rffmpeg`.

### GitHub Actions

`.github/workflows/build.yaml` builds and smoke-tests every pull request. On `master` it pushes the
image to the current server's container registry, tagged with the Jellyfin version from the base
image's `org.opencontainers.image.version` label and `latest`.

| Setting | Kind | Purpose |
| --- | --- | --- |
| `REGISTRY` | variable | Registry host, if it differs from the instance's server URL |
| `REGISTRY_USER` | variable | Registry login |
| `REGISTRY_TOKEN` | secret | Token for `REGISTRY_USER` with package write access |
| `RFFMPEG_REPO` | variable | rffmpeg repository to build from, e.g. a mirror; must end in `.git` |

### Updates

Renovate updates the pinned Jellyfin base image, and follows rffmpeg's `master` branch to update
`RFFMPEG_COMMIT`. rffmpeg has no releases.
