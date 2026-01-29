# When backup is lost

## Windows

- Install Windows Terminal
  - 'Settings' -> 'PowerShell' -> 'Appearance'
    - Change 'Font face' to 'MesloLGS' font (Install 'MesloLGS' font for Powerlevel10K)
    - Change 'Font size' to 10
    - Change 'Cursor shape' to 'Filled box'
- Install Docker Desktop (Don't use WSL as backend as we will be using devcontainers)
  - Turn on 'Start Docker Desktop when you sign in to your computer'
  - Turn off 'Open Docker Dashboard when Docker Desktop starts'
  - Adjust resource to higher limits
- Install Git
  - Uncheck 'Windows Explorer integration'
  - Override default branch name to 'main'
  - Select 'Checkout as-is, commit Unix-style line endings'
- Turn off everything in 'Settings' -> 'Personalization' -> 'Start'
- Uninstall redundant apps under 'Settings' -> 'App'
- Uninstall WSL
- Open 'File Explorer Options' -> Uncheck 'Hide File Extensions'
- Turn off 'For improved security, only allow Windows Hello sign-in for Microsoft accounts on this device' in sign-in options
- 'Windows Update' -> 'Advanced options' -> Turn on 'Recieve updates for other Microsoft products' for auto WSL2 update
- Power
  1. 'Power Options' -> 'Choose what the power buttons do' in sidebar -> Turn off 'Turn on fast startup'
  2. 'Customize Power Saving Settings' -> Set 'Power Mode' to 'Best Performance'
  3. 'Choose a Power -> 'Create a power plan' in sidebar and create a power plan -> Set created power plan to max-performance / no-powermanagement on power-plugged-in settings and balanced for battery settings.
- (Only Lenovo Laptop) Install 'AutoHotKey' in Onedrive and put 'AutoHotKey.ahk' in startup folder
- Install Macrium Reflect Home 8 from 'https://manage.macrium.com' and import backup definition from OneDrive 'Documents/Reflect' directory (Set schedule in edit if not set)

## Mac

- Install Docker Desktop
  - Turn on 'Start Docker Desktop when you sign in to your computer'
  - Turn off 'Open Docker Dashboard when Docker Desktop starts'
- Install Iterm2
  - Import Terminal profile 'Default.json'
- Uncheck all search result except 'Applications' and 'Folders' in Spotlight settings
- Desktop & Dock
  - Auto hide dock
  - Change to smaller icon size
- Mission Control
  - Enable 'Mission control have own spaces'
  - Enable 'Tile windows have margins'
- Keyboard
  - Replace 'US' layout with 'Unicode Hex Input' layout
  - Enable 'Use function key as standard function keys'
  - 'Input source switch to previous source' to win (opt)  + space
  - Invoke 'defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 70 "{enabled=NO;}"' in terminal (Disables ctrl + alt + D for intellij shortcut)
  - Add 'Terminal Shortcuts'
    - Bigger                 -> ctrl + shift + =
    - Smaller                -> ctrl + shift + -
    - Default Font Size      -> ctrl + shift + 0
- Setup 'Time Machine'

## Note

- When installing Intellij
  - Make sure you install with Jetbrains Toolbox (Also make sure to give permission to user write access to Jetbrains directory for auto updates)
  - Make sure you import the '.ideavimrc' from settings repository
  - Make sure you set the following in 'Terminal' settings
    - Set 'Terminal engine' to 'Classic'
    - Disable 'Shell Integration'
    - Set 'MesloLGS NF' as font 
    - Disable 'Audio bell'
- When icon in startup menu or taskbar is broken
  1. Run rebuild_icon.bat in Onedrive
  2. After restart, try changing Settings -> Display -> Scale and Layout to others and change back

## Work Laptop

- Login with personal account to VSCode (Settings Sync) and Intellij (Backup and Sync) for keyboard shortcut sync
- Import Vimium config from personal laptop
