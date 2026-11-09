-- Deliberately strict own-format JSON: no generic decoder or arbitrary payload.
local M={name='shell-probe-marker.json',limit=2048}
local Config=require('config')
local events={load=true,tap=true,leave=true,trial_selected=true,save=true}
local function trial_known(value)
  for _,id in ipairs(Config.trials) do if value==id then return true end end
  return false
end
local function integer(n) return type(n)=='number' and n>=0 and n<=999999999 and n==math.floor(n) end
function M.encode(s)
  assert(integer(s.sequence) and integer(s.load_count) and integer(s.tap_count) and integer(s.leave_count))
  assert(events[s.last_event] and trial_known(s.selected_trial))
  return string.format('{"schema_version":1,"app_id":"xteinkshellprobe","selected_trial":"%s","sequence":%d,"load_count":%d,"tap_count":%d,"leave_count":%d,"last_event":"%s","write_status":"ok"}',s.selected_trial,s.sequence,s.load_count,s.tap_count,s.leave_count,s.last_event)
end
function M.decode(raw)
  if type(raw)~='string' or #raw>M.limit then return nil end
  local trial,seq,loads,taps,leaves,event=raw:match('^{"schema_version":1,"app_id":"xteinkshellprobe","selected_trial":"([%w_]+)","sequence":(%d+),"load_count":(%d+),"tap_count":(%d+),"leave_count":(%d+),"last_event":"([%w_]+)","write_status":"ok"}$')
  if not trial or not trial_known(trial) or not events[event] then return nil end
  local s={selected_trial=trial,sequence=tonumber(seq),load_count=tonumber(loads),tap_count=tonumber(taps),leave_count=tonumber(leaves),last_event=event}
  for _,k in ipairs({'sequence','load_count','tap_count','leave_count'}) do if not integer(s[k]) then return nil end end
  if M.encode(s)~=raw then return nil end
  return s
end
return M
