# Installation Steps:
# 1. sh <(curl -L https://nixos.org/nix/install)
# 2. cp nix ~/
# 3. nix run nix-darwin/master#darwin-rebuild --extra-experimental-features 'nix-command flakes' -- switch --flake ~/nix#cya
# 4. darwin-rebuild switch --flake ~/nix#cya

# References:
# 1. https://github.com/ryan4yin/nix-darwin-kickstarter
# 2. https://nixos-and-flakes.thiscute.world/
# 3. https://davi.sh/blog/2024/02/nix-home-manager/

# Code:
{
  description = "nix-darwin system flake configuration for macOS";
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
          # @see: https://stackoverflow.com/questions/79473295/error-trying-to-setup-basic-nix-darwin-with-home-manager-flake
          # @see: https://github.com/nix-community/home-manager/issues/6036
          users.users."${username}".home = "/Users/${username}";

          # nixpkgs
          nixpkgs.config.allowUnfree = true;
          nixpkgs.hostPlatform = "aarch64-darwin";

          # packages which need to be installed by nix
          environment.systemPackages = with pkgs; [
            curl
            git
            mkalias
            wget
            nixfmt-rfc-style
          ];

          # packages which need to be installed by homebrew
          homebrew.enable = true;
          homebrew.brews = [
            "mas"
          ];
          homebrew.casks = [
            "keka"
            "google-chrome"
            "stats"
          ];
          homebrew.taps = [ ];
          homebrew.masApps = { };
          homebrew.onActivation.cleanup = "none";
          homebrew.onActivation.autoUpdate = false;
          homebrew.onActivation.upgrade = false;

          # Turn on the experimental features
          nix.settings.experimental-features = "nix-command flakes";

          # default shell
          programs.zsh.enable = true;

          # macOS system settings
          system.stateVersion = 6;
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.defaults.dock.autohide = true;
          system.defaults.dock.show-recents = false;
          system.defaults.dock.persistent-apps = [ ];
          system.defaults.dock.orientation = "right";
          system.defaults.finder.ShowPathbar = true;
          system.defaults.finder.ShowStatusBar = true;
          system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
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
              # Set up applications.
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
        };
      home_manager_configuration =
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
            bottom
            fastfetch
            fzf
            lsd
            jq
            neovim
            nerd-fonts.hack
            nerd-fonts.victor-mono
            nerd-fonts.roboto-mono
            nerd-fonts.jetbrains-mono
            p7zip
            ripgrep
            tmux
            unzip
            vim
            wezterm
            xz
            yazi
            zip
          ];
          programs.home-manager.enable = true;
          programs.zsh.enable = true;
          programs.zsh.enableCompletion = true;
          programs.zsh.shellAliases.ff = "fastfetch";
          programs.zsh.shellAliases.ls = "lsd";
          programs.zsh.shellAliases.tree = "lsd --tree -al";
          programs.zsh.shellAliases.nv = "nvim";
          programs.zsh.shellAliases.em = "emacs -nw";
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
            }
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users."${username}" = home_manager_configuration;
            }
          ];
        };
      };
    };
}
