# My Dotfiles

- **Terminal**: Alacritty
- **Editor**: Neovim
- **Shell**: fish + starship
- **WM**: Niri
- **Bar**: Waybar
- **Launcher**: Rofi
- **Colorscheme**: Catppuccin Mocha
- **Other**: tmux, jj, btop, mako, wofi

## Screenshots

<p align="center">
  <img src="./screenshots/screenshot.png" width="100%">
</p>

<!-- <p align="center"> -->
<!--   <img src="./screenshots/fastfetch.png" width="49%"> -->
<!--   <img src="./screenshots/neovim.png" width="49%"> -->
<!-- </p> -->


## Installation

````bash
git clone https://github.com/xdagiz/dots ~/dotfiles

# Symlink everything into $HOME
stow -d ~/dotfiles -t ~ home

# Or, if stow is invoked inside the repo:
cd ~/dotfiles && stow home
````
