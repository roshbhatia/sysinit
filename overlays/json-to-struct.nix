{ ... }:

final: _prev: {
  json-to-struct = final.buildGoModule rec {
    pname = "json-to-struct";
    version = "unstable-2023-06-02";

    src = final.fetchFromGitHub {
      owner = "tmc";
      repo = "json-to-struct";
      rev = "340a931e614adf8e0af591cab1fed7a2ad3afe81";
      hash = "sha256-7zvWUVo0w+eXyNLP1mnoLMWnyfc3xQIMgK+eD/yCSeU=";
    };

    vendorHash = "sha256-2bS+KKrvCkPw6SJnrpaph/ijT0VHKO+pHbRCECKwxcs=";

    meta = with final.lib; {
      description = "Generate Go struct definitions from JSON";
      homepage = "https://github.com/tmc/json-to-struct";
      license = licenses.mit;
      mainProgram = "json-to-struct";
    };
  };
}
