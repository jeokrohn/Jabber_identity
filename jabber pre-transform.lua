--[[
28 Aug 2023
THIS IS A PROOF OF CONCEPT SCRIPT AND SHOULD BE TESTED PRIOR TO DEPLOYMENT INTO A PRODUCTION ENVIRONMENT.
THIS SCRIPT IS NOT SUPPORTED BY TAC, CISCO SYSTEMS OR ANY OF ITS AFFILIATES.

If this script does not behave as expected,
1) check "Enable Trace" checkbox in the Normalization section in the device pool configuration page
2) reset the test device
3) place a couple of calls to the test device
4) collect a detailed the SDI trace file
5) mail the trace file, current script (if changes were made) and a description of the issue that includes
   the date, time, calling/called numbers and the result to Johannes Krohn or review

Johannes Krohn
jkrohn@cisco.com

Purpose:
This script removes URI identity from the RPID header sent to a device

Example SDL trace output:
45004207.002 |09:52:09.876 |AppInfo  |//SIPLua/Script/trace_output: RPID heeader: /"Amena Kirk" <sip:akirk@tmedemo.com;x-cisco-number=3121;x-cisco-callback-number=3121>;party=calling;screen=yes;privacy=off/
45004207.003 |09:52:09.876 |AppInfo  |//SIPLua/Script/getHeader: hvalue is "Amena Kirk" <sip:akirk@tmedemo.com;x-cisco-number=3121;x-cisco-callback-number=3121>;party=calling;screen=yes;privacy=off, value is "Amena Kirk" <sip:akirk@tmedemo.com;x-cisco-number=3121;x-cisco-callback-number=3121>;party=calling;screen=yes;privacy=off
45004207.004 |09:52:09.876 |AppInfo  |//SIPLua/Script/trace_output: x-cisco-number: /3121/
45004207.005 |09:52:09.876 |AppInfo  |//SIPLua/Script/trace_output: cleaned rpid header: /"Amena Kirk" <sip:akirk@tmedemo.com>;party=calling;screen=yes;privacy=off/
45004207.006 |09:52:09.876 |AppInfo  |//SIPLua/Script/trace_output: Final RPID header: /"Amena Kirk" <sip:3121@tmedemo.com>;party=calling;screen=yes;privacy=off/

"Amena Kirk" <sip:akirk@tmedemo.com;x-cisco-number=3121;x-cisco-callback-number=3121>;party=calling;screen=yes;privacy=off
"Amena Kirk" <sip:3121@tmedemo.com>;party=calling;screen=yes;privacy=off
--]]
M = {}
trace.enable()

function set_numeric_uri(h, s, num)
    s = s:gsub("sip:.+@", "sip:" .. num .. "@")
    trace.format("%s numeric URI /%s/", h, s)

    -- remove display name
    s = s:gsub(".*<(.+)>", "%1")
    trace.format("%s w/o display name /%s/", h, s)

    return s
end

function clean_rpid(msg)
    local rpid = msg:getHeader("Remote-Party-ID")
    -- check if we got a header
    if rpid ~= nil then
        trace.format("RPID header: /%s/", rpid)
        -- header is something like
        --  "Amena Kirk" <sip:akirk@tmedemo.com;x-cisco-number=3121;x-cisco-callback-number=3121>;party=calling;screen=yes;privacy=off

        -- extract x-cisco-callback-number
        local cisco_number = msg:getHeaderUriParameter("Remote-Party-ID", "x-cisco-callback-number")
        if cisco_number ~= nil then
            trace.format("x-cisco-number: /%s/", cisco_number)

            -- remove all x-cisco-...=;
            rpid = rpid:gsub(";x%-cisco%-[%a%-]+=[%+%d]+", "")
            trace.format("cleaned RPID: /%s/", rpid)

            rpid = set_numeric_uri("RPID", rpid, cisco_number)

            msg:modifyHeader("Remote-Party-ID", rpid)

            -- also clean up the From header
            local from = msg:getHeader("From")
            trace.format("From header: /%s/", from)

            from = set_numeric_uri("From", from, cisco_number)
            msg:modifyHeader("From", from)
        end
    end
    return msg
end

function M.outbound_INVITE(msg)
    msg = clean_rpid(msg)
end

function M.outbound_UPDATE(msg)
    msg = clean_rpid(msg)
end

return M