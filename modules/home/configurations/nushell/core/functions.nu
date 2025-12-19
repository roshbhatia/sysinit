def knu [...args: string] {
  kubecolor --kuberc=off ...$args -o json | from json
}

def "knu get" [...args: string] { knu get ...$args }
def "knu describe" [...args: string] { knu describe ...$args }
def "knu logs" [...args: string] { kubecolor logs ...$args }
