package opencode

import "testing"

func TestDecodeNormalizesOpenCodeExport(t *testing.T) {
	fixture := `{
  "info":{"id":"ses_one","directory":"/work/repo","agent":"build","model":{"id":"gpt-test","providerID":"openai"},"time":{"created":1000,"updated":9000}},
  "messages":[
    {"info":{"id":"msg_user","role":"user","time":{"created":1000}},"parts":[{"id":"prt_user","type":"text","text":"fix it"}]},
    {"info":{"id":"msg_model","role":"assistant","agent":"build","modelID":"gpt-test","providerID":"openai","finish":"tool-calls","time":{"created":2000,"completed":7000},"tokens":{"input":10,"output":2,"reasoning":1,"cache":{"read":4,"write":0}}},"parts":[
      {"id":"prt_reason","type":"reasoning","text":"checking"},
      {"id":"prt_edit","type":"tool","tool":"apply_patch","callID":"call_edit","state":{"status":"completed","input":{"patchText":"patch"},"output":"updated file.go","time":{"start":3000,"end":4000},"metadata":{"diff":"Index: /work/repo/file.go\n--- /work/repo/file.go\n+++ /work/repo/file.go\n@@ -1 +1 @@\n-old\n+new\n","files":[{"filePath":"/work/repo/file.go","relativePath":"file.go","patch":"Index: /work/repo/file.go\n--- /work/repo/file.go\n+++ /work/repo/file.go\n@@ -1 +1 @@\n-old\n+new\n","additions":1,"deletions":1}]}}}
    ]},
    {"info":{"id":"msg_final","role":"assistant","agent":"build","modelID":"gpt-test","finish":"stop","time":{"created":7001,"completed":8000}},"parts":[{"id":"prt_text","type":"text","text":"done"}]}
  ]
}`

	batch, err := Decode([]byte(fixture))
	if err != nil {
		t.Fatal(err)
	}
	if got, want := len(batch.Spans), 4; got != want {
		t.Fatalf("spans = %d, want %d", got, want)
	}
	if got, want := len(batch.Records), 4; got != want {
		t.Fatalf("records = %d, want %d", got, want)
	}

	spans := map[string]int{}
	for index, span := range batch.Spans {
		spans[span.SpanID] = index
		if span.Session != "ses_one" || span.Attrs["traces.view"] != "activity" {
			t.Errorf("span = %#v", span)
		}
	}
	turn := batch.Spans[spans["turn:msg_user"]]
	if turn.Name != "agent.turn" {
		t.Errorf("turn = %#v", turn)
	}
	model := batch.Spans[spans["msg_model"]]
	if model.ParentID != turn.SpanID || model.Attrs["stop_reason"] != "tool_use" {
		t.Errorf("model = %#v", model)
	}
	edit := batch.Spans[spans["prt_edit"]]
	if edit.Name != "agent.edit" || edit.ParentID != "msg_model" || edit.Attrs["traces.action"] != "edit" {
		t.Errorf("edit = %#v", edit)
	}
	if edit.Attrs["traces.patch"] == "" || edit.Attrs["lines_added"] != "1" || edit.Attrs["lines_removed"] != "1" {
		t.Errorf("edit attrs = %#v", edit.Attrs)
	}
	if batch.Records[0].Event != EventPrompt || batch.Records[0].Body != "fix it" {
		t.Errorf("prompt = %#v", batch.Records[0])
	}
}
