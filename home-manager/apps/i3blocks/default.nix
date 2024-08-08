
programs.i3blocks.enable = true;
programs.i3blocks.bars = {
	  separator_block_width=15;

	  speedblock = {
	    command = "$SCRIPTS/speedtestline.sh";
	    interval = 300;
	  };
	  uptime = lib.hm.dag.entryAfter ["speedblock"] {
	    command = "$SCRIPTS/mainuptime.sh";
	    interval = 60;
	  };
	  gpupower = lib.hm.dag.entryAfter ["uptime"] {
	    command = "$SCRIPTS/gpupower.sh";
	    interval = 180;
	  };
	  gpuutil = lib.hm.dag.entryAfter ["gpupower"] {
	    command = "$SCRIPTS/gpuutil.sh";
	    interval = 180;
	  };
	  memory = lib.hm.dag.entryAfter ["gpuutil"] {
	    label = "MEMORY ";
	    command = "awk '/MemFree/{ printf("%.1fG/n", $2/1024/1024) }' /proc/meminfo";
	  };
	  disk = lib.hm.dag.entryAfter ["memory"] {
	    label = "DISK ";
	    command = "df -h -P -l "/" | awk '/\/.*/ { print $4 }'";
	  };
	  time = lib.hm.dag.entryAfter ["disk"] {
	    command = "date + "%A, %B %d %Y, %r";
	    interval=3;
	  };
}
