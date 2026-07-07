"""
    get_user_input()

Gather user input required to perform the table transformation into a named tuple.

# Fields
- `:spec_no`: material specification number from Section II-D
- `:type_grade`: material type or grade from Section II-D
- `:class_condition_temper`: material class, condition, or temper from Section II-D
- `:KM620_coefficients_table_material_category`: material category from Div. 3 Table KM-620
- `:num_plastic_points`: number of stress-strain points to compute on the plastic region for ANSYS
- `:input_file_path`: path to input Excel file `Section II-D Tables.xlsx`
- `:output_file_path`: path to output Excel file `<material_string>.xlsx`
- `:plot_folder`: path to folder in which to save output plots
- `:material_string`: string combining the `spec_no`, `type_grade`, and `class_condition_temper` with hyphens
- `:material_dict`: dictionary of functions used to filter ASME_tables
"""
function get_user_input()
    # Material Specification
    tprintln(@style "Material Information" underline cyan)
    tprintln(@style "Enter the following material information with no special characters or spaces, \
        or press Enter to accept the default value. \
        If a value does not exist, enter an underscore." dim)

    spec_no_default = "SA-723"
    tprint("Specification Number: {dim}(Default: $spec_no_default) {/dim}", highlight=false)
    spec_no = parse_input(String, spec_no_default)

    type_grade_default = "3"
    tprint("Type/Grade: {dim}(Default: $type_grade_default) {/dim}", highlight=false)
    type_grade = parse_input(String, type_grade_default)

    class_condition_temper_default = "2"
    tprint(
        "Class/Condition/Temper: {dim}(Default: $class_condition_temper_default) {/dim}",
        highlight=false,
    )
    class_condition_temper = parse_input(String, class_condition_temper_default)

    KM620_coefficients_table_material_category_number_default = 1
    tprintln("")
    tprint(tableKM620_options())
    tprint(
        "Table KM-620 Material Category: \
            {dim}(Default: $KM620_coefficients_table_material_category_number_default) {/dim}",
        highlight=false,
    )
    valid = false
    local KM620_coefficients_table_material_category
    local KM620_coefficients_table_material_category_number
    while valid == false
        try
            KM620_coefficients_table_material_category_number = parse_input(
                Int,
                KM620_coefficients_table_material_category_number_default
            )
            KM620_coefficients_table_material_category = KM6.coefficients_table."Material"[
                KM620_coefficients_table_material_category_number
            ]
            valid = true
        catch
            tprint(@style "Invalid option. \
                Please enter an integer number corresponding to one of the options above: " red)
        end
    end

    # Simulation Parameters
    tprintln(@style "\nSimulation Parameters" underline cyan)
    tprintln(@style "Enter the following simulation parameters with no special characters or spaces, \
        or press Enter to accept the default value." dim)
    num_output_stress_points_default = 20
    tprint("Number of Plastic Stress-Strain Points: \
        {dim}(Default: $num_output_stress_points_default) {/dim}", highlight=false)
    num_plastic_points = parse_input(Int, num_output_stress_points_default)

    # Files
    tprintln(@style "\nSelect the appropriate file location." underline cyan)
    input_file_path = raw"S:\Material Properties\Excel Material Data\Section II-D Tables.xlsx"
    if !isfile(input_file_path)
        println("Locate and select the input file `Section II-D Tables.xlsx`.")
        input_file_path = pick_file(filterlist="xlsx, XLSX")
    end
    println("Choose the correct material category folder \
        in which to save the output tables and figures (e.g. Q&T Steels).\n")
    output_folder = pick_folder(dirname(input_file_path))

    # Derived Quantities
    material_string = make_material_string(spec_no, type_grade, class_condition_temper)
    material_dict = make_material_dict(spec_no, type_grade, class_condition_temper)
    output_file_path = joinpath(output_folder, material_string*".xlsx")
    plot_folder = joinpath(output_folder, "Plots")

    # Collect into `NamedTuple`
    user_input = (;
        spec_no,
        type_grade,
        class_condition_temper,
        KM620_coefficients_table_material_category,
        num_plastic_points,
        input_file_path,
        output_file_path,
        plot_folder,
        material_string,
        material_dict,
    )
    return user_input
end
export get_user_input

"""
    parse_input(type, default)

Reads input from the REPL and converts it to the specified type.
If nothing is entered, the default value is used.
"""
function parse_input(type, default)
    input = readline()
    if length(input) == 0
        return default
    end
    if type == String
        return input
    end
    return parse(type, input)
end
export parse_input

"""
    tableKM620_options()

Returns a terminal panel with the material information from Table KM-620.
Call `print` or `println` on the result to diplay it.
"""
function tableKM620_options()
    table = select(KM6.coefficients_table, "Material")
    notes = join(values(metadata(KM6.coefficients_table)), "\n")
    panel = @nested_panels Panel(
        Term.Table(
            hcat(1:nrow(table), table."Material"),
            header = ["Category", "Material"],
            header_style = "cyan",
            columns_justify = [:center, :left],
            columns_style = "default",
            box = :ROUNDED,
            style = "cyan",
        ),
        Panel(
            @style(notes, "cyan dim italic"),
            style = "cyan dim italic",
            title = "Note",
            title_style = "cyan dim italic",
        ),
        title = "Table KM-620 Material Categories",
        title_style = "cyan",
        style = "cyan",
    )
    return panel
end

"""
    make_material_string(spec_no, type_grade, class_condition_temper)

Combine the material designations into a single hyphen-separated string.
"""
make_material_string(
    spec_no,
    type_grade,
    class_condition_temper,
) = string(spec_no,'-',type_grade,'-',class_condition_temper)
export make_material_string

"""
    make_material_dict(
        spec_no::String,
        type_grade::String,
        class_condition_temper::String
    ) -> material_dict::LittleDict{String, String}

Create dictionary to filter DataFrame material properties from material specifications.

Maps the Section II-D table header string to an anonymous function `input_value`.
"""
function make_material_dict(spec_no::String, type_grade::String, class_condition_temper::String)
    material_dict = LittleDict{String, String}(
        "Spec. No." => spec_no,
        "Type/Grade" => type_grade,
        "Class/Condition/Temper" => class_condition_temper,
    )
    return material_dict
end
export make_material_dict

"""
    save_user_input(user_input::NamedTuple)

Saves `user_input` data to the folder specified by `user_input.inputdir`.
Variable names and values are extracted from `user_input` as (key, value) pairs,
then written to file one pair per line.
"""
function save_user_input(filepath, user_input)
    mkpath(filepath)
    filepath = joinpath(filepath, user_input.material_string * ".csv")
    open(filepath, "w") do io
        for (key, value) in pairs(user_input)
            println(io, key, ',', value)
        end
    end
end
export save_user_input
