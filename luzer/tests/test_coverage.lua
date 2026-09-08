local luzer = require("luzer")

-- Four single-byte comparisons, nested so each one is a separate branch.
--
-- With coverage feedback libFuzzer solves them one byte at a time: each
-- correct prefix is a new edge, the input is kept, and the next byte is
-- brute-forced from there. Without feedback every input is independent
-- and the whole 4-byte prefix has to land at once.
--
-- That gap is the test. test_e2e.lua compares a SINGLE byte, so it passes
-- either way and cannot detect a broken coverage pipeline.
local function TestOneInput(buf)
    if #buf < 4 then return end
    if buf:sub(1, 1) ~= "l" then return end
    if buf:sub(2, 2) ~= "u" then return end
    if buf:sub(3, 3) ~= "z" then return end
    if buf:sub(4, 4) ~= "r" then return end
    assert(nil, "coverage feedback reached the guarded branch")
end

-- The execution budget is the bound, pinned to a seed. With feedback the
-- prefix is found after a few tens of thousands of executions under PUC
-- Lua and a few hundred thousand under LuaJIT, so the budget leaves an
-- order of magnitude of headroom. Without feedback it is exhausted in a
-- few seconds at over a million executions per second, and the test
-- fails. The CTest TIMEOUT is only a backstop.
local opts = {
    max_len = 64,
    seed = 1,
    runs = 4000000,
}
luzer.Fuzz(TestOneInput, nil, opts)
