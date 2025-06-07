{inputs, ...}: {
  home.shellAliases.v = "nvim";
  
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      foldmethod = "indent";
    };
    performance = {
      combinePlugins = {
        enable = true;
	standalonePlugins = [
	  "nvim-treesitter"
        ];
      };
      byteCompileLua.enable = true;
    };

    viAlias = true;
    vimAlias = true;
    
    luaLoader.enable = true;
  };
}
