# Email

Run `email` for the terminal Emacs client. Nix installs Emacs, Evil, notmuch,
Lieer, and the mail interface. Account addresses, tokens, mail, and sync state
stay in local files outside Nix.

## Daily use

| Key | Action |
| --- | --- |
| `1`–`5` | Personal Primary, Promotions, Social, Updates, Forums |
| `gi`, `gw`, `ga` | Combined inbox, work inbox, all mail |
| `j`, `k`, Enter, `q` | Move, open, return |
| `s`, `G` | Search, sync |
| `V`, then `j`/`k` | Select rows |
| `,v` | Select all results |
| `,r`, `,u` | Mark selection read or unread |
| `e` | Archive selection |
| `,U` | Add the existing Unsubscribe label |
| `c`, `r`, `R` | Compose, reply, reply all |
| `?`, `Q` | Help, quit |

Compose with Vim insert/normal modes. `C-c C-c` sends; `C-c C-k` cancels.
Reading a message does not mark it read automatically. Use `,r` explicitly.
Bulk actions affect matching messages, including when a thread also contains
messages outside the search. Archiving removes `inbox` and preserves read status.

Signed-in accounts sync after tag changes and every five minutes while the
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
