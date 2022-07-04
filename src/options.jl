options = Dict(:holidays => false)


function set_option(option, value)
    options[option] = value;
end

function get_option(option)
    options[option]
end

