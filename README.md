# Enforce numeric caller identity using SIP T&N scripting

Working on a Lua script to massage outgoing INVITE and UPDATE messages on UCM to ensure that RPID and From headers only +
have numeric identity. This is useful if the numeric identity gets updated somewhere in the call arc (inbound or 
outbound) to avoid user lookup issues in Jabber caused by conflicting numeric and alpha identity in blended identity 
caller id headers. 