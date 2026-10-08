# Email

Run `email --personal` or `email --work` for the terminal Emacs client.
Run `email` to restore the last account. Nix installs Emacs, Evil, notmuch,
Lieer, and the mail interface. Account addresses, tokens, mail, and sync state
stay in local files outside Nix.

## Navigation and menus

Press Space and pause for WhichKey. `Space Space` opens the command picker.

| Menu | Actions |
| --- | --- |
| `Space c` | Gmail categories |
| `Space f` | Search, clear search, switch buffers |
| `Space m` | Compose, reply, archive, read/unread, labels, sync, images |
| `Space v` | List/tree, all mail, unread |
| `Space q` | Quit |

Escape clears Vim search highlighting. After a mail search, it also returns to
the category you selected. `Space f c` does the same. Escape cancels a picker;
Ctrl-j/Ctrl-k moves through its choices. Empty mail queries reset the search.
`Ctrl-u`/`Ctrl-d` scroll half a page up/down. Numeric Vim counts remain available; `g1`–`g5` are category aliases.

Catppuccin follows the terminal's light/dark mode. Emacs leaves its terminal
background unset so WezTerm controls transparency. Pickers and WhichKey use
resizable bottom windows. Chafa redraws when its preview pane changes size.

## Bulk actions

Use `V`, then `j`/`k`, to select a range of rows. `Ctrl-a` selects all results
in the current view. Press `e` to archive, or `t` to toggle read status.
If any selected message is unread, the toggle marks the selection read;
otherwise it marks the selection unread. `,r` always marks read; `,u` marks unread.

The `Space m` menu stays available during selection. It includes select rows,
select all, archive, toggle read/unread, and explicit read/unread actions.
Selections apply only to the current account and query. Escape cancels selection.

## Daily use

| Key | Action |
| --- | --- |
| `Space cA` | All inbox categories (excludes archived mail) |
| `Space cp` | Primary (default on launch and account switch) |
| `Space cr` | Promotions |
| `Space cs` | Social |
| `Space cu` | Updates |
| `g5` | Forums |
| `Space a` | Switch account |
| `Space v t` | Thread tree for the current view |
| Enter, Tab in tree | Message preview, fold/unfold |
| `Space m i` in a message | Preview an attached image with Chafa |
| `gi`, `gu`, `ga` | Selected account: inbox, unread, all mail |
| `j`, `k`, Enter, `q` | Move, open, return |
| `Space f g`, `s` | Search the selected account |
| `Space m s`, `Space m l` | Sync, sync log |
| `gg`, `G`, `Ctrl-u`, `Ctrl-d` | First, last, half-page up/down |
| `/`, `n`, `N` | Find text in the view |
| `Space f b`, `Ctrl-h/j/k/l` | Buffer picker, window navigation |
| `V`, then `j`/`k` | Select rows |
| `,v` | Select all results |
| `,r`, `,u` | Mark selection read or unread |
| `e` | Archive selection |
| `,U` | Add the existing Unsubscribe label |
| `c`, `r`, `R` | Compose, reply, reply all |
| `Space ?`, `Q` | Help, quit |

The header shows the selected account. Every saved view and search uses that
account. Switching closes old mail views and preserves drafts. New messages use
the selected sender. The last account is stored in `~/.local/state/email/account`.

Space is the leader, and comma owns local mail actions, matching Neovim.
Compose with Vim insert/normal modes. `C-c C-c` sends; `C-c C-k` cancels.
Reading a message does not mark it read automatically. Use `,r` explicitly.
Bulk actions affect matching messages, including when a thread also contains
messages outside the search. Archiving removes `inbox` and preserves read status.

Signed-in accounts sync at startup, after tag changes and every minute while the
client runs. `mail-sync` also works outside Emacs. Changes stay local until a
successful sync. Sync failures appear in `*mail-sync*`.

The Unsubscribe action only applies the label. Existing unsubscribe automation
must process it; the client does not submit unsubscribe requests.

## Local account setup

The launcher reads `~/.config/email/accounts.json`:

```json
[
  { "name": "personal", "address": "you@gmail.com", "path": "/absolute/path/Mail/personal" },
  { "name": "work", "address": "you@company.example", "path": "/absolute/path/Mail/work" }
]
```

Create `~/.config/notmuch/default/config` with `notmuch setup`, using
`NOTMUCH_CONFIG` to select that path. Set the database path to the parent Mail
directory, list both email addresses, and set these values:

```ini
[new]
tags=
ignore=/.*[.](json|lock|bak)$/;
[search]
exclude_tags=spam;trash;
[maildir]
synchronize_flags=false
```

Run `notmuch new`, then initialize each account with Lieer's native commands:

```sh
gmi init --no-auth --path /absolute/path/Mail/personal you@gmail.com
gmi set --path /absolute/path/Mail/personal --ignore-tags-remote ''
mail-auth personal
```

Repeat for `work`. Select the matching account in Google's browser picker.
Lieer includes its OAuth client registration; your organization must allow it.
Run `gmi pull --path /absolute/path/Mail/personal` for the first download, then
`email`. Keep the account directories private: Lieer stores OAuth tokens there.
Category synchronization must remain enabled (`ignore_remote_labels: []`).

## Thread and image views

The thread tree keeps the current account and category filter. Hidden messages
from other categories or accounts stay out of the tree. Visual selection and
read/archive actions also work in the tree.

Chafa displays attached and MIME-inline images in a WezTerm split using its
image protocol. Press Enter in that split to close it. Outside WezTerm, Chafa
renders colored characters in an Emacs buffer. Preview files are private and
are removed when the preview closes. Remote HTML images are not downloaded.
Chafa renders images; it does not render complete HTML emails.

## Configuration structure

`default.nix` owns packaging and local configuration paths. `packages.nix`
declares the shared editor packages used by the client and tests.

`emacs/sysinit-mail.el` loads the feature modules: core settings, accounts,
actions, views, images, UI, keys, and sync. The key module contains one leader
action registry for bindings, WhichKey labels, and help. This follows the
core/feature/context split in `sysinit.nvim` without sharing editor-specific code.
