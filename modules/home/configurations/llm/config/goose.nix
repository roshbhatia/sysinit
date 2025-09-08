{
  provider = "github_copilot";
  editMode = "vi";
  extensions = {
    computercontroller = {
      bundled = true;
      display_name = "Computer Controller";
      enabled = true;
      name = "computercontroller";
      timeout = 300;
      type = "builtin";
    };
    developer = {
      bundled = true;
      display_name = "Developer Tools";
      enabled = true;
      name = "developer";
      timeout = 300;
      type = "builtin";
      args = null;
    };
  };
}
