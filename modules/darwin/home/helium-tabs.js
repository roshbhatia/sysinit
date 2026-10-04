/* global Application */
globalThis.run = function (args) {
  const browser = Application("net.imput.helium");
  if (!browser.running()) return "[]";
  const windows = browser.windows();
  if (args[0] === "focus") {
    const win = windows.find((item) => String(item.id()) === args[1]);
    if (!win) throw new Error("Helium window no longer exists");
    const index = win.tabs().findIndex((item) => String(item.id()) === args[2]);
    if (index < 0) throw new Error("Helium tab no longer exists");
    win.activeTabIndex = index + 1;
    win.index = 1;
    browser.activate();
    return "";
  }
  return JSON.stringify(
    windows.flatMap((win) =>
      win.tabs().map((tab) => ({
        title: tab.title(),
        url: tab.url(),
        window_id: win.id(),
        tab_id: tab.id(),
      })),
    ),
  );
};
