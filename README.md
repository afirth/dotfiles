# afirth's dotfiles

Modified from geerlinguy. This stuff is just here for me to set up my boxes. If you find it useful, fork away.

## quickstart

# Ubuntu 18.x
```
sudo apt-get update
sudo apt-get install -y git make
mkdir ~/git
cd ~/git && git clone https://github.com/afirth/dotfiles
cd dotfiles
make
```

# OSX
```
cd mac-dev-playbook && ansible-playbook main.yml -i inventory -K --tags "dotfiles"
```

## Description

My configuration. OSX centric

[edit 2019 - not anymore! I've joined #linuxmasterrace on most of my boxes]

## License

MIT / BSD

## Cloudflare WARP

Install the Linux client separately from the default desktop setup:

```sh
make cloudflare-warp
```

This opt-in target uses Cloudflare's [official APT repository](https://pkg.cloudflareclient.com/)
for the machine's Ubuntu or Debian codename and amd64/arm64 architecture. Ubuntu
22.04 uses `jammy`. The release must be available in Cloudflare's repository.
The target installs the repository signing key with a scoped `signed-by` keyring,
then installs `cloudflare-warp`. An installed package is left unchanged on repeat
runs; use APT to upgrade it. This target does not require apt-fast.

Registration and connection are explicit steps, following Cloudflare's
[Linux client instructions](https://developers.cloudflare.com/warp-client/get-started/linux/):

```sh
warp-cli registration new
warp-cli connect
warp-cli status
curl https://www.cloudflare.com/cdn-cgi/trace  # expect warp=on
```

The Make target does not register an account, accept terms on your behalf, or
connect the tunnel. Use `warp-cli disconnect` to disconnect.

Run the installation orchestration tests without root, network access, or a
running WARP service (requires Python 3, GNU Make, Bash and GnuPG):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```
