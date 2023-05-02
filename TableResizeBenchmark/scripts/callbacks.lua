
--- @param gre#context mapargs
function CBInit(mapargs)
  local var_path = "Layer.Table.cell_text"
  local data = {}
  local table_data = gre.get_table_attrs("Layer.Table", "rows", "cols")
  local rows = table_data.rows
  local cols = table_data.cols
  for r=1,rows do
    for c=1,cols do
      local label = string.format("%d.%d", r, c)
      local var = string.format("%s.%s", var_path, label)
      data[var] = label
    end
  end
  
  gre.set_data(data)
end

local gTests = {
  {name = "Incremental Row", row_delta = 1, col_delta = 0},
  {name = "Decremental Row", row_delta = -1, col_delta = 0},
  {name = "Incremental Column", row_delta = 0, col_delta = 1},
  {name = "Decremental Column", row_delta = 0, col_delta = -1},
  {name = "Incremental Row Column", row_delta = 1, col_delta = 1},
  {name = "Decremental Row Column", row_delta = -1, col_delta = -1},
  {name = "Jump Down", row_delta = -150, col_delta = 0},
  {name = "Jump Up", row_delta = 150, col_delta = 0}
}
local gCurTest = 0
--- @param gre#context mapargs
function CBRunTest(mapargs)
  gCurTest = gCurTest + 1
  local test = gTests[gCurTest]
  if (test == nil) then
    gre.send_event("gre.quit")
    return
  end
  
  local table_attrs = gre.get_table_attrs("Layer.Table", "rows", "cols")
  table_attrs.rows = table_attrs.rows + test.row_delta
  table_attrs.cols = table_attrs.cols + test.col_delta
  local start_time = gre.mstime()
  gre.set_table_attrs("Layer.Table", table_attrs)
  local end_time = gre.mstime()
  gre.log_perf_stat("TableResizeBenchmark", test.name, end_time - start_time, "ms")
  gre.send_event("next_test")
end
