function read_file_by_lines(filepath)
    f = open(filepath, "r")
    lines = readlines(f)
    close(f)
    return lines
end

# run(`pwd`)
# println(read_file_by_lines("src/odysseus.jl"))
