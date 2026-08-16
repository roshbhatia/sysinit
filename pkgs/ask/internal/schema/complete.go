package schema

import "strings"

// offered are the types the completion puts in front of you, each with what it
// holds. typeOf parses more spellings than these (str, text, integer, float),
// but one spelling per type is what makes the list readable.
var offered = []struct {
	kind string
	says string
}{
	{"string", "any text"},
	{"int", "a whole number"},
	{"number", "a number, whole or not"},
	{"bool", "true or false"},
	{"object", "a nested object"},
	{"any", "anything at all"},
	{"[]string", "a list of text"},
	{"[]int", "a list of whole numbers"},
	{"[]number", "a list of numbers"},
	{"[]bool", "a list of true or false"},
	{"[]object", "a list of objects"},
}

// starters are whole specs to begin from, for the spec nobody has typed yet.
var starters = []struct {
	spec string
	says string
}{
	{"ok:bool, reason:string", "did it work, and why not"},
	{"files:[]string", "a list of paths"},
	{"level:error|warn|info, message:string", "a bar makes an enum"},
	{"name:string, count:int?", "a trailing ? makes a field optional"},
}

// Complete offers the rest of a --schema spec.
//
// The spec is a comma-separated list of name:type. A name is free text, so the
// type is the only half worth offering, and an empty spec gets a whole example
// to start from. The second answer says the shell should complete a path
// instead, which is what @ asks for.
func Complete(typed string) (offer []string, paths bool) {
	if strings.HasPrefix(typed, "@") {
		return nil, true
	}
	if strings.TrimSpace(typed) == "" {
		for _, one := range starters {
			offer = append(offer, one.spec+"\t"+one.says)
		}
		return offer, false
	}

	head, last := lastField(typed)
	name, partial, typing := strings.Cut(last, ":")
	if !typing {
		return nil, false
	}

	for _, one := range offered {
		if strings.HasPrefix(one.kind, partial) {
			offer = append(offer, head+name+":"+one.kind+"\t"+one.says)
		}
	}
	return offer, false
}

// lastField cuts the spec at the last comma, so only the field being typed is
// completed and the ones already written are carried through unchanged.
func lastField(typed string) (head string, last string) {
	at := strings.LastIndex(typed, ",")
	if at < 0 {
		return "", typed
	}
	return typed[:at+1], typed[at+1:]
}
