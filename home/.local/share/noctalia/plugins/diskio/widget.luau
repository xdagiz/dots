local dev = "sda"

function update()
  noctalia.setUpdateInterval(2000)
  noctalia.runAsync("iostat -d -m -o JSON 1 2", function(res)
    if res.timedOut or res.exitCode ~= 0 then
      barWidget.setText("disk n/a")
      return
    end
    local data = noctalia.json.decode(res.stdout)
    local disks = data and data.sysstat and data.sysstat.hosts and data.sysstat.hosts[1] and data.sysstat.hosts[1].statistics and data.sysstat.hosts[1].statistics[2] and data.sysstat.hosts[1].statistics[2].disk
    if disks == nil then
      barWidget.setText("disk n/a")
      return
    end
    local r = "0"
    local w = "0"
    for _, d in ipairs(disks) do
      if d.disk_device == dev then
        r = tostring(d["MB_read/s"])
        w = tostring(d["MB_wrtn/s"])
      end
    end
    barWidget.setText("R " .. r .. " MB/s W " .. w .. " MB/s")
  end, 10000)
end

function onClick()
  noctalia.runInTerminal("btop")
end
