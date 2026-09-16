{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
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
        focus = report "Actionable work" actionable;
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
