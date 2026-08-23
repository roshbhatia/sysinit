{ lib }:
rec {
  modNames = [
    {
      bit = 1048576;
      name = "cmd";
    }
    {
      bit = 262144;
      name = "ctrl";
    }
    {
      bit = 524288;
      name = "alt";
    }
    {
      bit = 131072;
      name = "shift";
    }
  ];

  keyNames = {
    "2" = "d";
    "3" = "f";
    "8" = "c";
    "12" = "q";
    "15" = "r";
    "18" = "1";
    "36" = "enter";
    "44" = "slash";
    "46" = "m";
    "48" = "tab";
    "49" = "space";
    "50" = "grave";
    "53" = "escape";
    "96" = "f5";
    "97" = "f6";
    "98" = "f7";
    "99" = "f3";
    "100" = "f8";
    "103" = "f11";
    "107" = "f14";
    "113" = "f15";
    "118" = "f4";
    "120" = "f2";
    "123" = "left";
    "124" = "right";
    "125" = "down";
    "126" = "up";
  };

  keyAliases = {
    esc = "escape";
    "/" = "slash";
    "`" = "grave";
  };
  canonicalKey = k: keyAliases.${k} or k;

  mkChord = mods: key: lib.concatStringsSep "+" ((map (m: m.name) mods) ++ [ (canonicalKey key) ]);

  disabled = {
    enable = false;
  };

  hotkey = enable: char: code: mods: {
    inherit enable;
    keys = [
      char
      code
      mods
    ];
  };

  baseSymbolicHotkeys = {
    "7" = hotkey false 65535 120 8650752;
    "8" = hotkey false 65535 99 8650752;
    "9" = hotkey false 65535 118 8650752;
    "10" = hotkey false 65535 96 8650752;
    "11" = hotkey false 65535 97 8650752;
    "12" = hotkey false 65535 122 8650752;
    "13" = hotkey false 65535 98 8650752;
    "15" = disabled;
    "16" = disabled;
    "17" = disabled;
    "18" = disabled;
    "19" = disabled;
    "20" = disabled;
    "21" = disabled;
    "22" = disabled;
    "23" = disabled;
    "24" = disabled;
    "25" = disabled;
    "26" = disabled;
    "27" = hotkey false 96 50 1048576;
    "32" = hotkey false 65535 126 8650752;
    "33" = hotkey false 65535 125 8650752;
    "36" = hotkey false 65535 103 8388608;
    "52" = hotkey false 100 2 1572864;
    "53" = hotkey false 65535 107 8388608;
    "54" = hotkey false 65535 113 8388608;
    "57" = hotkey false 65535 100 8650752;
    "59" = hotkey false 65535 96 9437184;
    "60" = hotkey false 32 49 262144;
    "61" = hotkey false 32 49 786432;
    "64" = hotkey false 32 49 1048576;
    "65" = hotkey false 32 49 1572864;
    "79" = hotkey false 65535 123 8650752;
    "80" = hotkey true 65535 123 8781824;
    "81" = hotkey false 65535 124 8650752;
    "82" = hotkey true 65535 124 8781824;
    "98" = hotkey false 47 44 1179648;
    "118" = hotkey false 65535 18 262144;
    "159" = hotkey false 65535 36 262144;
    "162" = hotkey false 65535 96 9961472;
    "164" = hotkey false 65535 65535 0;
    "175" = hotkey false 65535 65535 0;
    "190" = hotkey false 113 12 8388608;
    "215" = hotkey false 65535 65535 0;
    "216" = hotkey false 65535 65535 0;
    "217" = hotkey false 65535 65535 0;
    "218" = hotkey false 65535 65535 0;
    "219" = hotkey false 65535 65535 0;
    "222" = hotkey false 65535 65535 0;
    "223" = hotkey false 65535 65535 0;
    "224" = hotkey false 65535 65535 0;
    "225" = hotkey false 65535 65535 0;
    "226" = hotkey false 65535 65535 0;
    "227" = hotkey false 65535 65535 0;
    "228" = hotkey false 65535 65535 0;
    "229" = hotkey false 65535 65535 0;
    "230" = hotkey false 65535 65535 0;
    "231" = hotkey false 65535 65535 0;
    "232" = hotkey false 65535 65535 0;
    "233" = hotkey true 109 46 1048576;
    "235" = hotkey false 65535 65535 0;
    "237" = hotkey false 102 3 8650752;
    "238" = hotkey false 99 8 8650752;
    "239" = hotkey false 114 15 8650752;
    "240" = hotkey false 65535 123 8650752;
    "241" = hotkey false 65535 124 8650752;
    "242" = hotkey false 65535 126 8650752;
    "243" = hotkey false 65535 125 8650752;
    "244" = hotkey false 65535 65535 0;
    "245" = hotkey false 65535 65535 0;
    "246" = hotkey false 65535 65535 0;
    "247" = hotkey false 65535 65535 0;
    "248" = hotkey false 65535 123 8781824;
    "249" = hotkey false 65535 124 8781824;
    "250" = hotkey false 65535 126 8781824;
    "251" = hotkey false 65535 125 8781824;
    "256" = hotkey false 65535 65535 0;
    "257" = hotkey false 65535 65535 0;
    "258" = hotkey false 65535 65535 0;
    "260" = hotkey false 65535 53 1048576;
  };

  reservedChords = {
    "cmd+space" = "hammerspoon launcher";
    "cmd+tab" = "hammerspoon window switcher";
    "cmd+shift+tab" = "hammerspoon window switcher";
    "cmd+enter" = "claude desktop quick entry";
    "cmd+shift+enter" = "claude desktop quick entry dictation";
    "cmd+alt+enter" = "goose desktop quick launcher";
  };
}
