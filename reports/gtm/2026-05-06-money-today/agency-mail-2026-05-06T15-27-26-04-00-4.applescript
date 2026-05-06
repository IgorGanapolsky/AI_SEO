on run argv
  set emailAddress to "ian@byswitch.xyz"
  set subjectLine to "Quick n8n workflow teardown idea"
  set bodyText to "Hey Automated by Switch team," & return & "" & return & "I saw your public n8n/AI automation work and built a narrow $49 teardown for one broken workflow: n8n automation, restaurant call flow, lead handoff, or agent workflow." & return & "" & return & "It returns 3 concrete fixes and the next action. If useful, it can sit before a larger $499 diagnostic or be used as a partner/referral offer for clients who are not ready for a full build yet." & return & "" & return & "Offer page:" & return & "https://ai-seo-operator-stack.web.app/offers/ai-workflow-quick-teardown.html" & return & "" & return & "Checkout:" & return & "https://buy.stripe.com/6oU00jduQ3n03hDfSH3sI16" & return & "" & return & "Worth trying on one messy workflow?" & return & "" & return & "Igor Ganapolsky" & return & "AI Operator Stack" & return & "201 639 1534" & return & "" & return & "--" & return & "Ad/solicitation disclosure: I am reaching out about a paid workflow diagnostic." & return & "Opt out: reply \"no\" and I will not contact you again." & return & "Mailing address: 11909 Glenmore Dr, Coral Springs, FL 33071"
  with timeout of 180 seconds
    tell application "Mail"
      set newMessage to make new outgoing message with properties {subject:subjectLine, content:bodyText, visible:false}
      tell newMessage
        make new to recipient at end of to recipients with properties {address:emailAddress}
        send
      end tell
    end tell
  end timeout
  return "Automated by Switch" & "," & emailAddress
end run
