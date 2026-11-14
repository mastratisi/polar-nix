# polar-nix

Nix flake for [Polar](https://polar.sh)'s [`polar` CLI](https://polar.sh/docs/integrate/cli)
(webhook forwarding, sample events, sessions), following the npm release feed.

`@polar-sh/cli` on npm only selects a per-platform package (`@polar-sh/cli-linux-x64`, ...), each
holding one prebuilt executable. This flake fetches that executable and patches its interpreter
with `autoPatchelfHook`; nothing is built from source.

## Use

```
nix run github:mastratisi/polar-nix -- --version
```

In a flake-based NixOS config:

```nix
inputs.polar-nix.url = "github:mastratisi/polar-nix";
# ...
nixpkgs.overlays = [ polar-nix.overlays.default ];
environment.systemPackages = [ pkgs.polar-cli ];
```

Systems: x86_64-linux and aarch64-linux. Binary: `polar`.

## Known gaps

- `polar update` cannot replace a binary in the Nix store; updates come from this flake.
- The CLI sends telemetry unless `POLAR_CLI_TELEMETRY_OPTOUT=1` (or `DO_NOT_TRACK=1`) is set.
- Only the x86_64-linux build has been run; aarch64-linux is evaluated only.

## How it stays current

- `update.sh` reads `https://registry.npmjs.org/@polar-sh/cli/latest` and writes `release.json`
  (version, and per system the tarball URL and npm's SRI integrity hash). Needs `jq` and `curl`
  (both in `nix develop`).
- `.github/workflows/update.yml` runs it daily, builds, checks `polar --version` matches, commits
  `release.json` if it changed, and tags the commit `v<version>`.
- `package.nix` only reads `release.json`; it has no version of its own.

Update by hand: `nix develop -c ./update.sh && nix build`.
