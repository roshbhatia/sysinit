def --wrapped main [...arguments: string] {
    (([$env.EXTERN_TEST_COMMAND] | append $arguments | to json --raw) + "\n") | save --append $env.EXTERN_ARGV

    if ($env.EXTERN_FAIL? | default '') != '' {
        print --stderr 'extern fixture failure'

        exit 7
    }

    if ($env.EXTERN_BAD_JSON? | default '') != '' {
        print 'invalid JSON'
    } else if ($env.EXTERN_EMPTY? | default '') != '' {
        return
    } else if ([--json --format --format-version --style -o] | any {|flag| $flag in $arguments}) or 'inspect' in $arguments {
        print $env.EXTERN_DATA
    } else {
        print 'native text'
    }
}
