# References:
# 1. https://github.com/ryan4yin/nix-darwin-kickstarter
# 2. https://nixos-and-flakes.thiscute.world/
# 3. https://davi.sh/blog/2024/02/nix-home-manager/

# Bootstrap:
# 1. sh <(curl -L https://nixos.org/nix/install)
# 2. nix run nix-darwin/master#darwin-rebuild --extra-experimental-features 'nix-command flakes' -- switch --flake ~/dot#cya
# 3. darwin-rebuild switch --flake ~/dot#cya

# Code:
{
  description = "nix-darwin configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core.url = "github:homebrew/homebrew-core";
    homebrew-core.flake = false;
    homebrew-cask.url = "github:homebrew/homebrew-cask";
    homebrew-cask.flake = false;
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
    }:
    let
      hostname = "cya";
      username = "cya";
      darwin_configuration =
        { pkgs, config, ... }:
        {
          # users
          users.users."${username}".home = "/Users/${username}";

          # nixpkgs
          nixpkgs.config.allowUnfree = true;
          nixpkgs.hostPlatform = "aarch64-darwin";

          # environment
          environment.systemPackages = with pkgs; [
            curl
            git
            mkalias
            wget
            nil
            nixfmt-rfc-style
          ];

          # homebrew
          homebrew.enable = true;
          homebrew.brewPrefix = "/opt/homebrew/bin";
          homebrew.global.brewfile = true;
          homebrew.global.autoUpdate = false;
          homebrew.taps = [
            # "FelixKratz/formulae"
            # "nikitabobko/tap"
          ];
          homebrew.brews = [
            "m-cli"
          ];
          homebrew.casks = [
            "aldente"
            "firefox"
            "google-chrome"
            "hiddenbar"
            "intellij-idea-ce"
            "joplin"
            "keka"
            "microsoft-edge"
            "microsoft-excel"
            "microsoft-powerpoint"
            "microsoft-word"
            "miniforge"
            "neohtop"
            "raycast"
            "sf-symbols"
            "spotify"
            "stats"
            "visual-studio-code"
          ];
          homebrew.masApps = {
            # Xcode = 497799835;
            # adguard-for-safari = 1440147259;
          };
          homebrew.onActivation.cleanup = "none";
          homebrew.onActivation.autoUpdate = false;
          homebrew.onActivation.upgrade = false;

          # nix
          nix.settings.experimental-features = "nix-command flakes";
          nix.settings.auto-optimise-store = false;
          nix.gc.automatic = true;
          nix.gc.options = "--delete-older-than 7d";

          # system
          system.stateVersion = 6;
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.defaults.menuExtraClock.Show24Hour = true;
          system.defaults.menuExtraClock.ShowAMPM = false;
          system.defaults.menuExtraClock.ShowDayOfMonth = false;
          system.defaults.menuExtraClock.ShowDayOfWeek = false;
          system.defaults.menuExtraClock.ShowDate = 1;
          system.defaults.menuExtraClock.ShowSeconds = false;
          system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
          system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
          system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
          system.defaults.dock.autohide = true;
          system.defaults.dock.show-recents = false;
          system.defaults.dock.persistent-apps = [
            "/System/Applications/launchpad.app"
          ];
          system.defaults.dock.orientation = "right";
          system.defaults.finder.ShowPathbar = true;
          system.defaults.finder.ShowStatusBar = true;
          system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
          system.defaults.controlcenter.BatteryShowPercentage = true;
          system.activationScripts.extraActivation.text = ''
            softwareupdate --install-rosetta --agree-to-license
          '';
          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                  echo "copying $src" >&2
                  ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
                  done
            '';
          security.pam.services.sudo_local.touchIdAuth = true;
        };
      darwin_home_manager_configuration =
        {
          pkgs,
          config,
          lib,
          ...
        }:
        {
          home.username = "${username}";
          home.homeDirectory = "/Users/${username}";
          home.stateVersion = "24.11";
          home.activation.trampolineApps =
            let
              apps = pkgs.buildEnv {
                name = "home-manager-applications";
                paths = config.home.packages;
                pathsToLink = "/Applications";
              };
            in
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              toDir="$HOME/Applications/Home Manager Trampolines"
              fromDir="${apps}/Applications/"
              rm -rf "$toDir"
              mkdir "$toDir"
              (
               cd "$fromDir"
               for app in *.app; do
               /usr/bin/osacompile -o "$toDir/$app" -e 'do shell script "open '$fromDir/$app'"'
               done
              )
            '';
          home.packages = with pkgs; [
            bat
            btop
            bottom
            cargo
            clang-tools
            direnv
            emacs
            fastfetch
            fd
            fzf
            graphviz
            go
            htop
            lazygit
            lsd
            lua
            lua-language-server
            jdk23
            jq
            neovim
            nerd-fonts.blex-mono
            nerd-fonts.fira-mono
            nerd-fonts.hack
            nerd-fonts.victor-mono
            nerd-fonts.roboto-mono
            nerd-fonts.jetbrains-mono
            nerd-fonts.ubuntu
            nerd-fonts.ubuntu-mono
            nerd-fonts.terminess-ttf
            nerd-fonts.noto
            nerd-fonts.mplus
            nerd-fonts.go-mono
            nerd-fonts.zed-mono
            nerd-fonts.mononoki
            nerd-fonts.monaspace
            nerd-fonts.meslo-lg
            nerd-fonts.inconsolata
            nerd-fonts.caskaydia-mono
            nerd-fonts.fantasque-sans-mono
            nushell
            nodejs_22
            nnn
            p7zip
            R
            rstudio
            ripgrep
            ripgrep-all
            starship
            tmux
            texliveTeTeX
            texstudio
            tldr
            unzip
            vim
            wezterm
            xz
            yazi
            zip
            zstd
          ];
          home.file.".config/aerospace/aerospace.toml".source = ./home/aerospace/aerospace.toml;
          home.file.".vim/vimrc".source = ./home/vim/vimrc;
          home.file.".config/wezterm/wezterm.lua".source = ./home/wezterm/wezterm.lua;
          home.file.".config/nvim/init.lua".source = ./home/nvim/init.lua;
          home.file.".emacs.d/init.el".source = ./home/emacs/init.el;
          programs.home-manager.enable = true;
          programs.zsh.enable = true;
          programs.zsh.enableCompletion = true;
          programs.zsh.shellAliases.ff = "fastfetch";
          programs.zsh.shellAliases.ls = "lsd";
          programs.zsh.shellAliases.tree = "lsd --tree -al";
          programs.zsh.shellAliases.nv = "nvim";
          programs.zsh.shellAliases.em = "emacs -nw";
          programs.starship.enable = true;
          programs.starship.settings.add_newline = false;
          programs.starship.settings.line_break.disabled = true;
          programs.direnv.enable = true;
          programs.direnv.nix-direnv.enable = true;
          programs.direnv.enableZshIntegration = true;
        };
    in
    {
      darwinConfigurations = {
        "${hostname}" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            darwin_configuration
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew.enable = true;
              nix-homebrew.enableRosetta = true;
              nix-homebrew.user = "${username}";
              nix-homebrew.taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              nix-homebrew.mutableTaps = false;
              nix-homebrew.autoMigrate = true;
            }
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users."${username}" = darwin_home_manager_configuration;
            }
          ];
        };
      };
    };
}
