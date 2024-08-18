{inputs, ...}: {
#  imports = [
 #   inputs.nixvim.homeManagerModules.nixvim
  #  ];

  home.shellAliases.v = "nvim";
  
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    performance = {
      combinePlugins = {
        enable = true;
	standalonePlugins = [
	  "nvim-treesitter"
        ];
      };
      byteCompileLue.enable = true;
    };

    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;
  };
}
