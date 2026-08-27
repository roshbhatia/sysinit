// Parse actions as a fixed group and subcommand grammar. Free text belongs only
// to commands that declare an argument, so a misspelling cannot invoke another
// operation with an accidental argument.
globalThis.actionRows = function actionRows(query, available, cap) {
  const value = query.slice(1);
  const groupEnd = value.search(/\s/);
  const groupName = (groupEnd < 0 ? value : value.slice(0, groupEnd)).toLowerCase();
  const groupRow = (group) => ({
    title: "+" + group.name,
    sub: group.detail || "",
    kind: group.label || "Action",
    glyph: group.glyph || "command",
    completion: "+" + group.name + " ",
  });

  if (groupEnd < 0) {
    return available
      .filter((group) => group.name.startsWith(groupName))
      .slice(0, cap)
      .map(groupRow);
  }

  const group = available.find((candidate) => candidate.name === groupName);
  if (!group) {
    return [];
  }

  const tail = value.slice(groupEnd).trimStart();
  const commandEnd = tail.search(/\s/);
  const commandName = (commandEnd < 0 ? tail : tail.slice(0, commandEnd)).toLowerCase();
  const commands = Array.isArray(group.commands) ? group.commands : [];
  const commandRow = (command) => {
    const prefix = "+" + group.name + " " + command.name;
    const row = {
      title: prefix,
      sub: command.detail || "",
      kind: group.label || "Run",
      glyph: group.glyph || "command",
    };
    if (command.argument) {
      row.completion = prefix + " ";
      row.sub = row.sub + (row.sub === "" ? "" : " · ") + "Requires <" + command.argument + ">";
    } else {
      row.action = group.name;
      row.command = command.name;
      row.arg = "";
    }
    return row;
  };

  if (commandEnd < 0) {
    return commands
      .filter((command) => command.name.startsWith(commandName))
      .slice(0, cap)
      .map(commandRow);
  }

  const command = commands.find((candidate) => candidate.name === commandName);
  if (!command) {
    return [];
  }
  const arg = tail.slice(commandEnd).trim();
  if (!command.argument) {
    return arg === "" ? [commandRow(command)] : [];
  }
  if (arg === "") {
    return [commandRow(command)];
  }
  return [
    {
      title: "+" + group.name + " " + command.name + " " + arg,
      sub: command.detail || "",
      kind: group.label || "Run",
      glyph: group.glyph || "command",
      action: group.name,
      command: command.name,
      arg: arg,
    },
  ];
};
