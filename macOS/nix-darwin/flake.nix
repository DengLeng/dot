# Steps:
# 1. sh <(curl -L https://nixos.org/nix/install)
# 2. mkdir ~/.config/
# 3. cp nix-darwin ~/.config
# 4. nix run nix-darwin/master#darwin-rebuild --extra-experimental-features 'nix-command flakes' -- switch --flake ~/.config/nix-darwin#cya
# 5. darwin-rebuild switch --flake ~/.config/nix-darwin#cya
# References:
# 1. https://github.com/ryan4yin/nix-darwin-kickstarter
# 2. https://nixos-and-flakes.thiscute.world/
# 3. https://davi.sh/blog/2024/02/nix-home-manager/
{
  description = "nix-darwin system flake configuration for macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      home-manager,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          # user $HOME path
          # @see: https://stackoverflow.com/questions/79473295/error-trying-to-setup-basic-nix-darwin-with-home-manager-flake
          users.users.cya.home = "/Users/cya";

          # nixpkgs setup
          nixpkgs = {
            config = {
              allowUnfree = true;
            };
            hostPlatform = "aarch64-darwin";
          };

          # packages which need to be installed by nix
          environment.systemPackages = [
            pkgs.curl
            pkgs.git
            pkgs.mkalias
            pkgs.wget
            pkgs.nixfmt-rfc-style
          ];

          # packages which need to be installed by homebrew
          homebrew = {
            enable = true;
            brews = [
              "mas"
            ];
            casks = [
              "firefox"
              "keka"
              "google-chrome"
              "microsoft-edge"
              "microsoft-excel"
              "microsoft-powerpoint"
              "microsoft-word"
              "neohtop"
              "spotify"
              "stats"
            ];
            taps = [ ];
            masApps = { };
            onActivation.cleanup = "none";
            onActivation.autoUpdate = false;
            onActivation.upgrade = false;
          };

          # Turn on the experimental features
          nix.settings.experimental-features = "nix-command flakes";

          # default shell
          programs.zsh.enable = true;

          # macOS system settings
          system = {
            stateVersion = 6;
            configurationRevision = self.rev or self.dirtyRev or null;
            defaults = {
              dock = {
                autohide = true;
                show-recents = false;
                persistent-apps = [ ];
              };
              finder = {
                _FXShowPosixPathInTitle = true;
                AppleShowAllExtensions = true;
                FXEnableExtensionChangeWarning = false;
                QuitMenuItem = true;
                ShowPathbar = true;
                ShowStatusBar = true;
              };
            };
            activationScripts = {
              extraActivation = {
                text = ''
                  softwareupdate --install-rosetta --agree-to-license
                '';
              };
              applications = {
                text =
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
            };
          };
        };
      home_manager_configuration =
        { pkgs, config, ... }:
        {
          home.username = "cya";
          home.homeDirectory = "/Users/cya";
          home.stateVersion = "24.11";
          home.packages = [
            pkgs.bottom
            pkgs.fastfetch
            pkgs.fzf
            pkgs.lsd
            pkgs.jq
            pkgs.neovim
            pkgs.nerd-fonts.hack
            pkgs.nerd-fonts.victor-mono
            pkgs.nerd-fonts.roboto-mono
            pkgs.nerd-fonts.jetbrains-mono
            pkgs.p7zip
            pkgs.ripgrep
            pkgs.tmux
            pkgs.unzip
            pkgs.vim
            pkgs.wezterm
            pkgs.xz
            pkgs.yazi
            pkgs.zip
          ];
          programs.home-manager.enable = true;
          programs.zsh = {
            enable = true;
            enableCompletion = true;
            shellAliases = {
              ls = "lsd";
              nv = "nvim";
              em = "emacs -nw";
              switch = "darwin-rebuild switch --flake ~/.config/nix-darwin#cya";
            };
          };
        };
    in
    {
      darwinConfigurations."cya" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "cya";
              autoMigrate = true;
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.cya = home_manager_configuration;
          }
        ];
      };
    };
}
