{ pkgs, ... }: 

{

  home.packages = with pkgs; [ vesktop ];

  xdg.desktopEntries = 
    {

      vesktop = {
	name = "vesktop";
	genericName = "Discord Launcher";
	exec = "vesktop %U";
      };

    };

  vesktop = {
    settings = {
      hardwareAcceleration = true;
    };
    vencord.settings = {
      autoUpdate = true;
      plugins = {
	FakeNitro.enabled = true;
	BetterSettings.enabled = true;
	SpotifyControls.enabled = true;
      };
    };
  };

}
