# `M.setup` locals and what each one reads

Produced by task 1.2 against `ui.lua` at 1,867 lines. One row per
declaration at depth 1 inside `M.setup`, in file order.

Method, and its two known limits. A function's body ends at its matching
`  end`; a value's body ends at the next declaration, so a value row may
sweep in trailing statements. Comments and string literals are stripped,
and an identifier preceded by `.` or `:` is a field rather than a read.
Both filters were added after a first pass reported `touch_workspace`
reading `workspace_last_active`, which is the GLOBAL field of that name,
and `pane_badge_color` reading `lantern`, which is a statement between two
declarations. Neither is a read. A map with those in it would have moved
two functions across a boundary for no reason.

| line | name | lines | kind | reads |
| ---: | --- | ---: | --- | --- |
| 10 | `config_data` | 1 | val | nothing |
| 11 | `font` | 66 | val | `config_data` |
| 77 | `locked_indicator` | 6 | fn | nothing |
| 84 | `agent_deck_ok`, `agent_deck` | 141 | val | nothing |
| 225 | `nf` | 1 | val | nothing |
| 226 | `agent_state_icons` | 6 | val | `nf` |
| 232 | `agent_state_rank` | 6 | val | nothing |
| 238 | `agent_state_labels` | 6 | val | nothing |
| 244 | `SUPPRESSED_REASONS` | 2 | val | nothing |
| 246 | `status_color` | 7 | fn | nothing |
| 254 | `format_status_label` | 9 | fn | `SUPPRESSED_REASONS`, `agent_state_labels` |
| 264 | `format_age` | 11 | fn | nothing |
| 276 | `pane_repo` | 17 | fn | nothing |
| 304 | `read_pane_record` | 14 | fn | nothing |
| 319 | `smart_path` | 20 | fn | `home` |
| 344 | `pane_agent_state` | 19 | fn | `agent_state_rank` |
| 364 | `compute_agent_session_states` | 84 | fn | `agent_deck`, `agent_deck_ok`, `agent_state_rank`, `pane_agent_state`, `pane_repo`, `read_pane_record` |
| 449 | `rollup_cache` | 1 | val | nothing |
| 450 | `agent_session_states` | 8 | fn | `compute_agent_session_states`, `rollup_cache` |
| 459 | `gui_window_for_workspace` | 23 | fn | nothing |
| 483 | `switch_to_workspace` | 21 | fn | `gui_window_for_workspace` |
| 505 | `activate_agent_pane` | 31 | fn | `switch_to_workspace` |
| 537 | `normalize_proc` | 4 | fn | nothing |
| 542 | `pane_proc` | 17 | fn | `normalize_proc` |
| 560 | `tab_label` | 15 | fn | `pane_proc` |
| 576 | `seshy_session_names` | 28 | fn | `sy_bin` |
| 605 | `home` | 1 | val | nothing |
| 606 | `seshy_dir` | 1 | val | nothing |
| 607 | `sy_bin` | 14 | val | `home` |
| 621 | `seshy_cache` | 1 | val | nothing |
| 622 | `seshy_names_cached` | 12 | fn | `seshy_cache`, `seshy_session_names`, `sy_bin` |
| 635 | `active_session_names` | 13 | fn | nothing |
| 649 | `DEFAULT_WORKSPACE` | 1 | val | nothing |
| 650 | `DEFAULT_SLOT` | 1 | val | nothing |
| 651 | `MAX_SLOT` | 2 | val | nothing |
| 653 | `compute_session_slots` | 71 | fn | `DEFAULT_SLOT`, `DEFAULT_WORKSPACE`, `MAX_SLOT`, `active_session_names` |
| 725 | `slots_cache` | 1 | val | nothing |
| 726 | `session_slots` | 7 | fn | `compute_session_slots`, `slots_cache` |
| 734 | `touch_throttle` | 1 | val | nothing |
| 735 | `touch_workspace` | 13 | fn | `touch_throttle` |
| 749 | `workspace_last_active` | 4 | fn | nothing |
| 765 | `session_tree` | 98 | fn | `agent_deck`, `agent_deck_ok`, `agent_state_rank`, `pane_agent_state`, `pane_proc`, `pane_repo`, `read_pane_record`, `seshy_names_cached`, `tab_label`, `workspace_last_active` |
| 864 | `tree_colors` | 24 | fn | `config_data` |
| 889 | `agent_status` | 26 | fn | `agent_session_states`, `agent_state_icons`, `agent_state_rank` |
| 916 | `CHIP_NAME_MAX` | 1 | val | nothing |
| 917 | `CHIP_SESSIONS_MAX` | 6 | val | nothing |
| 923 | `chip_sessions` | 14 | fn | `CHIP_SESSIONS_MAX` |
| 938 | `session_chips` | 58 | fn | `CHIP_NAME_MAX`, `agent_session_states`, `agent_state_icons`, `agent_state_rank`, `chip_sessions`, `session_slots`, `status_color`, `tree_colors` |
| 1034 | `tabline_ok`, `tabline` | 67 | val | `agent_status`, `locked_indicator`, `session_chips` |
| 1101 | `ribbon_ok`, `ribbon` | 4 | val | nothing |
| 1105 | `sigil_ok`, `sigil` | 23 | val | `nf` |
| 1128 | `tree_icons` | 9 | val | `nf`, `sigil`, `sigil_ok` |
| 1137 | `BADGE_NAMES` | 39 | val | nothing |
| 1176 | `pane_badge` | 4 | fn | `BADGE_NAMES` |
| 1181 | `pane_badge_color` | 11 | fn | nothing |
| 1195 | `lantern_ok`, `lantern` | 62 | val | `config_data` |
| 1257 | `SHELLS` | 70 | val | `agent_state_icons`, `home`, `nf`, `normalize_proc`, `pane_badge`, `pane_badge_color`, `ribbon`, `ribbon_ok`, `sigil`, `sigil_ok` |
| 1327 | `hyperlink_rules` | 22 | val | nothing |
| 1349 | `wm_ok`, `wm` | 519 | val | `activate_agent_pane`, `agent_session_states`, `agent_state_icons`, `agent_state_labels`, `agent_state_rank`, `format_age`, `format_status_label`, `gui_window_for_workspace`, `home`, `pane_badge`, `pane_badge_color`, `ribbon`, `seshy_dir`, `seshy_session_names`, `session_tree`, `sigil`, `sigil_ok`, `smart_path`, `status_color`, `switch_to_workspace`, `sy_bin`, `tree_colors`, `tree_icons` |
