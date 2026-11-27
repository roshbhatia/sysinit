#compdef worker
_arguments -S \
  '(-w --wait)'{-w,--wait}'[Wait for exit; zero waits without timeout]:seconds:' \
  '(-b --wait-blocked)'{-b,--wait-blocked}'[Wait for exit or input]:seconds:' \
  '(-t --tail)'{-t,--tail}'[Log lines after waiting]:lines:' \
  '(-n --name)'{-n,--name}'[Run name]:name:' \
  '--status[Show the workspace worker]' \
  '--close[Close the worker pane]' \
  '--release[Release a run name]:name:' \
  '--force[Force release]' \
  '(-h --help)'{-h,--help}'[Show usage]' \
  '*::command: _normal'
