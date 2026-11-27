{ personal, remoteBuild }:

{
  arrakis = import ./arrakis { inherit personal remoteBuild; };
  lv426 = import ./lv426 { inherit personal; };
  urth = import ./urth { inherit personal; };
}
