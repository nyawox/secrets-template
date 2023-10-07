{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.secrets = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable secrets in your system
      '';
    };
    enablePassword = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable password from secrets
      '';
    };
    homewifiSSID = mkOption {
      type = types.str;
      default = "YourWifiSSID";
      description = ''
        Default wifi SSID used on iwd
      '';
    };
    home2GwifiSSID = mkOption {
      type = types.str;
      default = "YourWifiSSID2G";
      description = ''
        Default wifi SSID used on iwd
      '';
    };
  };
  config = {
    # Used to pass flake check
    secrets.enable = lib.mkForce false;
    secrets.enablePassword = lib.mkForce false;
    sops = mkIf config.secrets.enable {
      defaultSopsFile = mkIf config.secrets.enable "/etc/secrets/yoursecrets.yaml";
      #https://github.com/Mic92/sops-nix/issues/167
      gnupg.sshKeyPaths = mkIf config.secrets.enable [];
      # This will automatically import SSH keys as age keys
      # Don't forget to copy key there
      age.sshKeyPaths = mkIf config.secrets.enable ["/etc/ssh/your_id_ed25519"];
      secrets.userpassword = mkIf config.secrets.enablePassword {
        neededForUsers = true;
        sopsFile = ./userpassword.yaml;
      };
    };
    #
    users.users."${config.var.username}".hashedPasswordFile = mkIf config.secrets.enablePassword config.sops.secrets.userpassword.path;
    # sops.secrets.rootpassword = {
    #   neededForUsers = true;
    #   sopsFile = ./rootpassword.yaml;
    # };
    # users.users."root".hashedPasswordFile = config.sops.secrets.rootpassword.path;
    # Disable root
    users.users."root".hashedPassword = mkIf config.secrets.enablePassword "*";

    environment.systemPackages = mkIf config.secrets.enable [
      pkgs.sops
    ];

    environment.persistence."/persist".files = mkIf config.modules.sysconf.impermanence.enable [
      "/etc/ssh/your_id_ed25519"
      "/etc/ssh/your_id_ed25519_pub"
    ];
  };
}
