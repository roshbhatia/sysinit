{
  task-triage = {
    actionable = {
      type = "boolean";
      instructions = "Does the capture identify a concrete action someone can take?";
    };
    kind = {
      type = "choice";
      instructions = "Which category best describes this capture?";
      choices = {
        fix = "Correct an existing failure";
        feature = "Add behavior";
        maintenance = "Maintain or simplify existing systems";
        research = "Investigate an unanswered question";
        other = "None of these categories, or insufficient context";
      };
    };
  };
  log-triage = {
    failure = {
      type = "boolean";
      instructions = "Does this log contain evidence that the operation failed? A warning alone is not a failure.";
    };
    cause = {
      type = "choice";
      instructions = "Which cause is supported by the log? Choose unknown when there is insufficient evidence.";
      choices = {
        authentication = "Credentials or permissions rejected";
        capacity = "Resource or rate limit reached";
        network = "Connection, DNS, or transport failure";
        configuration = "Invalid or missing configuration";
        application = "Application logic failed";
        unknown = "No clear failure cause";
      };
    };
  };
  answer-review = {
    follows-request = {
      type = "boolean";
      instructions = "Does the answer satisfy the prompt in this generation envelope?";
    };
    supported = {
      type = "boolean";
      instructions = "Are the answer's factual claims supported by the envelope's input? Do not treat the answer itself as evidence.";
    };
    completeness = {
      type = "score";
      instructions = "How completely does the answer address the prompt?";
      levels = [
        "Does not address the request"
        "Addresses part of the request"
        "Addresses the whole request"
      ];
    };
  };
}
