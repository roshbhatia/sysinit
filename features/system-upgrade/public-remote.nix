{
  services.comin.remotes = [
    {
      name = "sysinit";
      url = "https://github.com/roshbhatia/sysinit.git";
      branches = {
        main.name = "stable";
        testing.name = "";
      };
    }
  ];
}
