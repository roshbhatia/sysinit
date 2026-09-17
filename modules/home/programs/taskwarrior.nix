{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.tasks;
  taskContext = pkgs.sysinit.writeShellApplication {
    name = "task-context";
    runtimeInputs = [ pkgs.git ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.xdg-utils ];
    text = ''exec ${pkgs.sysinit-gotools}/bin/task-context --task ${lib.getExe pkgs.taskwarrior-cli} --directory ${lib.escapeShellArg "${config.xdg.stateHome}/task-backups"} --keep ${toString cfg.backup.keep} "$@"'';
  };
  actionable = "+PENDING -WAITING -BLOCKED -blocked -backlog -inbox ( kind:task or kind.none: )";
  report = description: filter: {
    inherit description;
    filter = "${filter} limit:page";
    columns = lib.mkDefault "id,project,priority,due.relative,description";
    labels = lib.mkDefault "ID,Project,Pri,Due,Description";
    sort = "urgency-,due+,entry+";
  };
  colors = {
    active = "bold blue";
    alternate = "";
    blocked = "magenta";
    blocking = "bold yellow";
    "burndown.done" = "on green";
    "burndown.pending" = "on red";
    "burndown.started" = "on blue";
    "calendar.due" = "yellow";
    "calendar.due.today" = "bold yellow";
    "calendar.holiday" = "magenta";
    "calendar.overdue" = "bold red";
    "calendar.scheduled" = "cyan";
    "calendar.today" = "bold blue";
    "calendar.weekend" = "";
    "calendar.weeknumber" = "cyan";
    completed = "green";
    debug = "cyan";
    deleted = "color8";
    due = "yellow";
    "due.today" = "bold yellow";
    error = "bold red";
    footnote = "cyan";
    header = "bold blue";
    "history.add" = "on blue";
    "history.delete" = "on red";
    "history.done" = "on green";
    label = "blue";
    "label.sort" = "bold blue";
    overdue = "bold red";
    "project.none" = "";
    recurring = "magenta";
    scheduled = "cyan";
    "summary.background" = "";
    "summary.bar" = "on blue";
    "sync.added" = "green";
    "sync.changed" = "yellow";
    "sync.rejected" = "red";
    "tag.next" = "bold blue";
    "tag.blocked" = "magenta";
    "tag.inbox" = "cyan";
    "tag.none" = "";
    tagged = "";
    "uda.priority.H" = "red";
    "uda.priority.M" = "yellow";
    "uda.priority.L" = "cyan";
    "uda.kind.idea" = "magenta";
    "uda.kind.note" = "cyan";
    "undo.after" = "green";
    "undo.before" = "red";
    until = "";
    warning = "bold yellow";
  };
in
{
  options.sysinit.tasks = {
    extraFocusFilter = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Taskwarrior filter terms for actionable work.";
    };
    urlAttribute = lib.mkOption {
      type = lib.types.str;
      default = "url";
      description = "Task attribute containing the external source URL.";
    };
    backup = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Create daily private Taskwarrior export snapshots.";
      };
      keep = lib.mkOption {
        type = lib.types.ints.positive;
        default = 14;
        description = "Number of snapshots to retain.";
      };
    };
  };
  config = lib.mkMerge [
    {
      home.packages = [
        pkgs.taskwarrior-tui-private
        taskContext
      ];
      programs.taskwarrior = {
        enable = true;
        package = pkgs.taskwarrior-cli;
        config = {
          news.version = pkgs.taskwarrior3.version;
          default.command = "focus";
          weekstart = "monday";
          color = true;
          rule.color.merge = false;
          verbose = "affected,blank,context,edit,header,footnote,label,new-id,news,project,special,sync,recur";
          urgency = {
            age.coefficient = 0.2;
            annotations.coefficient = 0;
            tags.coefficient = 0;
            project.coefficient = 0;
          };
          context = {
            tasks.read = "( kind:task or kind.none: )";
            capture.read = "( kind:idea or kind:note or +inbox )";
            capture.rc.default.command = "review";
          };
          report = {
            focus = report "Actionable work" (
              lib.concatStringsSep " " (
                [ actionable ] ++ lib.optional (cfg.extraFocusFilter != "") cfg.extraFocusFilter
              )
            );
            working = (report "Work in progress" "+PENDING +ACTIVE") // {
              columns = "id,project,agent,start.age,description";
              labels = "ID,Project,Agent,Started,Description";
              sort = "start+,urgency-";
            };
            stalled =
              (report "Blocked or waiting work" "( +PENDING or +WAITING ) ( +BLOCKED or +blocked or +WAITING )")
              // {
                columns = "id,project,depends,wait.remaining,description";
                labels = "ID,Project,Depends,Wait,Description";
              };
            inbox = report "Unprocessed captures" "+PENDING +inbox";
            ideas = report "Captured ideas" "+PENDING kind:idea";
            notes = report "Reference notes" "+PENDING kind:note";
            review = (report "All unfinished work" "( +PENDING or +WAITING )") // {
              columns = "id,entry.age,modified.age,project,kind,tags,description";
              labels = "ID,Age,Updated,Project,Kind,Tags,Description";
              sort = "modified+,entry+";
            };
          };
          uda = {
            taskwarrior-tui = {
              shortcuts = {
                "1" = toString (
                  pkgs.sysinit.writeShellScript "task-open-url" ''exec ${taskContext}/bin/task-context --field ${lib.escapeShellArg cfg.urlAttribute} open-url "$@"''
                );
                "2" = toString (
                  pkgs.sysinit.writeShellScript "task-open-repo" ''exec ${taskContext}/bin/task-context --field repo open-repo "$@"''
                );
              };
              task-report = {
                next.filter = lib.removeSuffix " limit:page" config.programs.taskwarrior.config.report.focus.filter;
                use-alternate-style = false;
                info-location = "auto";
                prompt-on-done = true;
                prompt-on-delete = true;
                prompt-on-undo = true;
              };
              selection.indicator = "> ";
              mark.indicator = "* ";
              mark-selection.indicator = "*>";
              unmark-selection.indicator = "> ";
              style = {
                title = "bold blue";
                "title.border" = "color8";
                navbar = "black on blue";
                command = "blue";
                "command.error" = "bold red";
                "help.gauge" = "blue";
                "report.selection" = "black on blue";
                "report-menu.active" = "black on blue";
                "context.active" = "black on blue";
                "calendar.title" = "bold blue";
                "calendar.today" = "black on blue";
                "report.scrollbar" = "blue";
                "report.scrollbar.area" = "color8";
                "report.completion-pane" = "white on black";
                "report.completion-pane-highlight" = "black on blue";
              };
            };
            kind = {
              type = "string";
              label = "Kind";
              values = "task,idea,note";
              default = "task";
            };
            repo = {
              type = "string";
              label = "Repository";
            };
            agent = {
              type = "string";
              label = "Agent session";
            };
          };
        }
        // lib.mapAttrs' (name: value: lib.nameValuePair "color.${name}" value) colors;
      };
      home.sessionVariables.TASKRC = "${config.xdg.configHome}/task/taskrc";
    }
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.taskwarrior-backup = lib.mkIf cfg.backup.enable {
        enable = true;
        config = {
          ProgramArguments = [
            "${taskContext}/bin/task-context"
            "backup"
          ];
          EnvironmentVariables.TASKRC = "${config.xdg.configHome}/task/taskrc";
          StartInterval = 86400;
          RunAtLoad = true;
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/taskwarrior-backup.log";
        };
      };
    })
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.taskwarrior-backup = lib.mkIf cfg.backup.enable {
        Unit.Description = "Private Taskwarrior export snapshot";
        Service = {
          Type = "oneshot";
          ExecStart = "${taskContext}/bin/task-context backup";
          Environment = "TASKRC=${config.xdg.configHome}/task/taskrc";
        };
      };
      systemd.user.timers.taskwarrior-backup = lib.mkIf cfg.backup.enable {
        Unit.Description = "Daily Taskwarrior backup";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })
  ];
}
