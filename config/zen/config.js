// Enable userChrome.css / userContent.css (Zen only auto-sets this once,
// during profile migration, so it never picks up files added afterward).
try {
  Services.prefs.setBoolPref(
    "toolkit.legacyUserProfileCustomizations.stylesheets",
    true
  );
} catch (err) {
  Components.utils.reportError(err);
}

// Default font for web page content (pages that don't set their own font).
try {
  const group = "x-western";
  Services.prefs.setCharPref(`font.default.${group}`, "monospace");
  for (const generic of ["serif", "sans-serif", "monospace", "cursive", "fantasy"]) {
    Services.prefs.setCharPref(`font.name.${generic}.${group}`, "Hurmit Nerd Font");
  }
} catch (err) {
  Components.utils.reportError(err);
}

// Autoconfig: Alt+9 selects tab 9 (instead of the last tab).
// Alt+Shift+[0-9] selects tabs 10-19 (Alt+Shift+0 = tab 10 ... Alt+Shift+9 = tab 19).
try {
  Services.obs.addObserver(win => {
    win.addEventListener("keydown", e => {
      if (!e.altKey || e.ctrlKey || e.metaKey) return;
      const m = /^Digit(\d)$/.exec(e.code);
      if (!m) return;
      let index;
      if (e.shiftKey) index = 9 + Number(m[1]);
      else if (m[1] === "9") index = 8;
      else return;
      e.preventDefault();
      e.stopPropagation();
      win.gBrowser.selectTabAtIndex(index);
    }, true);
  }, "browser-delayed-startup-finished");
} catch (err) {
  Components.utils.reportError(err);
}
