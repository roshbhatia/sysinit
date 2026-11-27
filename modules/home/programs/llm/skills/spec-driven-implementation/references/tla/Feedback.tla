------------------------------ MODULE Feedback ------------------------------
EXTENDS Naturals
CONSTANT Guarded
VARIABLES intent, candidate, inflight, evidence, accepted
vars == <<intent, candidate, inflight, evidence, accepted>>
None == <<2, 2>>
Current == <<intent, candidate>>

Init == /\ intent = 0
        /\ candidate = 0
        /\ inflight = None
        /\ evidence = None
        /\ accepted = <<None, None>>

Revise == /\ intent = 0
          /\ intent' = 1
          /\ UNCHANGED <<candidate, inflight, evidence, accepted>>
Apply == /\ candidate = 0
         /\ candidate' = 1
         /\ UNCHANGED <<intent, inflight, evidence, accepted>>
StartCheck == /\ inflight = None
              /\ inflight' = Current
              /\ UNCHANGED <<intent, candidate, evidence, accepted>>
ReceivePass == /\ inflight # None
               /\ evidence' = inflight
               /\ inflight' = None
               /\ UNCHANGED <<intent, candidate, accepted>>
Accept == /\ evidence # None
          /\ IF Guarded THEN evidence = Current ELSE evidence[2] = candidate
          /\ accepted' = <<Current, evidence>>
          /\ UNCHANGED <<intent, candidate, inflight, evidence>>

Next == Revise \/ Apply \/ StartCheck \/ ReceivePass \/ Accept
Spec == Init /\ [][Next]_vars
EvidenceMatches == accepted[1] = accepted[2]
FairSpec == Spec /\ WF_vars(StartCheck) /\ WF_vars(ReceivePass) /\ WF_vars(Accept)
Reconciles == <>[](accepted[1] = Current)
=============================================================================
