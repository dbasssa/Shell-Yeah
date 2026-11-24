# Shell-Yeah

a Quickshell based Desktop shell for Arch & Arch-based distros running MangoWM

---
## Install guide
The Install script (install.sh) has 4 modes that you can use. to run the script you need to `cd Shell-Yeah` and `chmod +x install.sh`. then run `./install.sh [mode]` or `bash install.sh [mode]`

**--auto** will run an automatic dependency check, file movement, and package install via. pacman and your preffered AUR helper (yay/paru are the only supported helpers right now)

**--custom** will allow you to choose what features you want in the shell, as well as allowing manual package install. this will **NOT** run a dependecy check

**--check-deps** will run a dependency check using pacman. It is recommended to run this before --custom to check and install dependencies yourself.

**--check-integ** will verify the files and running processes. It is recommended to run this after any install. 


**Note:** by default, the script will edit your mango config using the current file type (.conf/.toml). if you want to disable this, run --no-binds, which will not edit anything in your config, other than moving the border colours to a separate file for theme-ability. Currently, no full bypass exists, since the shell is meant to be fully themeable on demand.


**Without install script**

`git clone` this repo

`cd Shell-Yeah`

if you have a pre-existing quickshell config, run `mv ~/.config/quickshell ~/.config/quickshell.bak`

`cp -r quickshell ~/.config`

`qs -p ~/.config/quickshell`

**Note:** once the install file is fully built, there will be no need to do this, as the install file will take care of each of these actions.
**Note 2:** This wont enable every single feature of the shell. (e.g. Dmenu picker wont be available, rofi or another launcher with a dmenu protocol will be needed)

---
## Features
- Notification handling + Do Not Disturb
- Screenshots (grim + slurp)
- wallpapers + automatic pywal (optional)
- Fully automated color application to mangowm borders
- Workspace and Layout management via IPC (mmsg)
- CLipboard history
- Quick and easy audio output management
- Wifi, Ethernet, and Bluetooth management
- System monitors for RAM and CPU
- Lock Screen & idle behavior

**Features Currently in Development**
- App customisation from theme instead of wallpaper (toggle built in, so disabling pywal is possible)
- GTK and Qt themes (this will probably take a long time because i dont know how to make/choose themes)

---
## IPC Commands
These are bindable in your config and used to open things like the control center, settings app, clipboard manager, app launcher, etc.

```
qs ipc call app-launcher toggle
qs ipc call ctrlcntr-qs toggle
spawn,qs ipc call lockscreen-qs toggle
spawn,qs ipc call clipboard-qs toggle
spawn,qs ipc call settings-qs toggle
```

The install script will bind these in your config unless the --no-binds flag is present.  
