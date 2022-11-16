function read_file_by_lines(filepath)
    f = open(filepath, "r")
    lines = readlines(f)
    close(f)
    return lines
end

function write_file(filepath, content)
    # f = open(filepath, "w")
    # write(file, content)
    # close(f)
    open(filepath, "w") do f
        write(f, content)
    end
end

# run(`pwd`)
# println(read_file_by_lines("src/odysseus.jl"))
