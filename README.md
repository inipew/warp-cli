# WARP-CLI Installer
![App Screenshot](https://raw.githubusercontent.com/Sir-MmD/warp-cli/refs/heads/main/logo.png)
### About
This is a simple script to install the Cloudflare WARP Linux Client (warp-cli). It uses Cloudflare's official repository: https://pkg.cloudflareclient.com

<div align="center">

| Supported OS  | CPU Type         |
|:--------------:|:----------------:|
| **APT Based OS** | x86_64 / aarch64 |
| **YUM Based OS** | x86_64 / aarch64 |

</div>


### Installation
```bash
bash -c "$(wget https://raw.githubusercontent.com/Sir-MmD/warp-cli/main/warp-cli.sh -O -)"
```
### Note
This script sets the default mode of WARP to SOCKS5 and uses port 10808. If needed, you can change it using the ```warp-cli``` command
