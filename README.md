# Dotfiles
This project aims to separate logic from configuration files.

The goal is to quickly install and configure a terminal environment using the dotfiles bash script. You can keep your configuration files separate of the dotfiles script and simply link to them in your profile. Profiles allow different configurations easily using the dotfiles script.

The dotfiles script is mainly four components:
- dotfiles (Interface)
    - This is the interface script that combines everything together in a way the user can interact with.
- lib/lib-core.sh (Library)
    - This is a library of common functionality.
- lib/lib-configs.sh (Configs)
    - This is a library that handles parsing your profile.json and triggering the right installers. 
    - It also handles copying your config files to dotfiles/_home and then symlinking them to ~/.
- lib/lib-installers.sh (Installers)
    - This is a library that handles installing software.

This project was designed to serve my own purposes and mostly to learn bash. I don't aim to support anything or add additional installers that I don't use. However, you are welcome to fork this repository and add your own installers. Check out the "Adding your own installers" section.

![Example Usage 1](/screenshots/example_usage_1.png?raw=true "Example Usage 1")
![Example Usage 2](/screenshots/example_usage_2.png?raw=true "Example Usage 2")
![Example Usage 3](/screenshots/example_usage_3.png?raw=true "Example Usage 3")

# Supported Operating Systems
Although I don't support this software I generally have tested and designed it to work on most versions of the following operating systems:
- Ubuntu
- Debian
- macOS
- CentOS

# Dependencies

`Bash 4.4+`
- Bash 4.4+ is needed because associative arrays are used in this script.
- The dotfiles script will attempt to upgrade bash itself to a version that is above 4.4.

`jq`
- JQ is used to help parse the profile.json file quickly and accurately.

`stow`
- GNU Stow is used to symlink ~/dotfiles/_home to ~/

# Getting Started
Here is a quick one liner to clone the repo, cd into it and run the script.

```shell
git clone https://github.com/mikeabreu/dotfiles ~/dotfiles && cd ~/dotfiles && ./dotfiles 
```

# Configuration Files
This project contains some example configuration files that you can use if you'd like. However, the main purpose is to separate configuration files from this repo. 

An example workflow is shown below.

1. Clone dotfiles to ~/dotfiles.
```shell
git clone https://github.com/mikeabreu/dotfiles ~/dotfiles
```
2. Clone your configs repo to ~/dotfiles/configs
```shell
cd ~/dotfiles && git clone https://github.com/mikeabreu/configs
```
3. Run dotfiles with your custom profile.
```shell
cd ~/dotfiles && ~/dotfiles -p configs/profiles/macos.json
```
macos.json
```json
{
    "name": "macos",
    "shell": "zsh",
    "shell_framework": "oh-my-zsh",
    "shell_theme": "spaceship-prompt",
    "shell_plugins": [
        "zsh-autosuggestions",
        "zsh-syntax-highlighting"
    ],
    "system_packages": [
        "vim",
        "git",
        "tmux",
        "grc",
        "htop",
        "pup",
        "ipcalc",
        "pyenv",
        "p7zip",
        "parallel",
        "dos2unix",
        "bat"
    ],
    "configs_path": "configs/macos/home"
}
```
![Example Configuration File Structure](/screenshots/example_configuration_structure.png?raw=true "Example Configuration File Structure")

# Customization
documentation is a work in progress

## Changing profiles
documentation is a work in progress

## Adding your own key/values to profile schema
documentation is a work in progress

## Adding your own installers
documentation is a work in progress
