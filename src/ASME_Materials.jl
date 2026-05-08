module ASME_Materials

# Load Packages
using ColorSchemes, DataFrames, GLMakie, Interpolations, NativeFileDialog, OrderedCollections,
        SimpleNonlinearSolve, Term, XLSX
import Div3.KM620

# Define Functions
include("Input.jl")
include("ReadTables.jl")
include("TransformTables.jl")
include("WriteTables.jl")
include("PlotTables.jl")

# KM-610 Ideally Elastic Plastic Stability Parameters
const increase_in_strength = 0.05 # 5%
const increase_in_plastic_strain = 0.20 # 20%

# Display Welcome Message When Package Loads
__init__() = println(welcome_message())

# Welcome Message
function welcome_message()
    message = "\n" *
        "You have just loaded the {cyan}ASME_Materials{/cyan} package!\n\n" *
        "Ensure the material you need has been added \
        to every sheet of the file {italic dim}Section II-D Tables.xlsx.{/italic dim} \
        Then type {cyan}main(){/cyan} next to the {green}julia>{/green} prompt and press Enter.\n"
    welcome_panel = Panel(
        message,
        title = "Julia Package Instructions",
        title_style = "bold",
        title_justify = :center,
        style = "cyan",
    )
    return welcome_panel
end
export welcome_message

# Goodbye Message
function goodbye_message(output_file_path=nothing)
    if output_file_path === nothing
        text = "the output Excel file"
    else
        text = "{italic dim}$output_file_path{/italic dim}"
    end
    message =
        """

        1. Open {cyan}Engineering Data{/cyan} in {cyan}ANSYS Workbench{/cyan}.
        2. Ensure {cyan}Units{/cyan} in the menu bar are set to {cyan}U.S. Customary{/cyan}.
        3. Click on {cyan}Engineering Data Sources{/cyan} under the {cyan}Engineering Data{/cyan} tab.
        4. Click the check box next to the appropriate {cyan}Data Source{/cyan} to edit it.
        5. Add and name a new material.
        6. For every sheet in $text:
          a. Add the property to the new ANSYS material that matches the Excel sheet name.
          b. Copy and paste the Excel sheet data into the matching empty ANSYS table.
        7. Click the {cyan}Save{/cyan} button next to the {cyan}Data Source{/cyan} checkbox.
        """
    goodbye_panel = Panel(
        message,
        title = "ANSYS Workbench Instructions",
        title_style = "bold",
        title_justify = :center,
        style = "cyan",
    )
    return goodbye_panel
end
export goodbye_message

# Output Struct
"""
    ASME_Materials_Data

Collection of all inputs and outputs from the `main` process.

# Fields
- `user_input::NamedTuple`: user input from the `get_user_input` function
    - :spec_no
    - :type_grade
    - :class_condition_temper
    - :KM620_coefficients_table_material_category
    - :num_plastic_points
    - :input_file_path
    - :output_file_path
    - :plot_folder
    - :material_string
    - :material_dict
- `ASME_tables::LittleDict`: collection of tables defined by ASME Section II-D;
    output from the `read_ASME_tables` function
    - "PRD"
    - "PRDkey"
    - "TCD"
    - "TCDkey"
    - "TE"
    - "TEkey"
    - "TM"
    - "TMkey"
    - "U"
    - "Y"
- `ASME_groups::LittleDict`: collection of material groups defined by ASME Section II-D;
    output from the `read_ASME_tables` function
    - "PRD"
    - "TCD"
    - "TE"
    - "TM"
- `ANSYS_tables::LittleDict`: collection of tables which define an ANSYS material;
    output of `transform_ASME_tables` function
    - "Density"
    - "Thermal Conductivity"
    - "Thermal Expansion"
    - "Elasticity"
    - "Yield Strength"
    - "Ultimate Strength"
    - "Temperature"
    - "Hardening <Temp>°F"
    - "EPP"
    - "EPP Stabilized"
- `ANSYS_figures::LittleDict`: collection of figures plotting ANSYS material properties vs. temperature;
    output of `plot_ANSYS_tables` function
    - "Thermal Conductivity"
    - "Thermal Expansion"
    - "Elasticity"
    - "Plasticity"
    - "Yield Strength"
    - "Ultimate Strength"
    - "EPP Stress-Strain"
    - "Total Stress-Strain"
- `master_table::DataFrame`: intermediate table of material data created using the KM-620 equations
"""
struct ASME_Materials_Data
    user_input::NamedTuple
    ASME_tables::LittleDict{String, DataFrame}
    ASME_groups::LittleDict{String, String}
    ANSYS_tables::LittleDict{String, DataFrame}
    ANSYS_figures::LittleDict{String, Figure}
    master_table::DataFrame
end
Base.show(
    io::IO,
    ::MIME"text/plain",
    x::ASME_Materials_Data
) = tprint(io, "{dim}   Output Fields: $(join(fieldnames(typeof(x)),", ")){/dim}")
export ASME_Materials_Data

# Full Program
"""
    main() -> results::ASME_Materials_Data
    main(user_input::NamedTuple) -> results::ASME_Materials_Data

The full program defined in this package.

Run the program to convert American Society of Mechanical Engineers (ASME)
Boiler and Pressure Vessel Code (BPVC) Section II-D material data tables
through Section VIII Division 3 Part KM-620 into material data tables
compatible with ANSYS Finite Element Analysis (FEA) software.
Ensure the material you need has been added to every sheet
of the file `Section II-D Tables.xlsx` before running.
`user_input` can optionally be provided as a `NamedTuple` to run the full
program at once rather than interactively supplying the input data.
"""
function main(user_input::NamedTuple)
    tprintln(@style "Reading input file ..." cyan italic)
    ASME_tables, ASME_groups = read_ASME_tables(user_input)

    tprintln(@style "Transforming input tables ..." cyan italic)
    ANSYS_tables, master_table = transform_ASME_tables(ASME_tables, ASME_groups, user_input)

    tprintln(@style "Writing output tables ..." cyan italic)
    write_ANSYS_tables(ANSYS_tables, user_input)

    tprintln(@style "Plotting results ..." cyan italic)
    ANSYS_figures = plot_ANSYS_tables(ANSYS_tables, user_input)

    print("\n", goodbye_message(user_input.output_file_path))

    return ASME_Materials_Data(
        user_input,
        ASME_tables,
        ASME_groups,
        ANSYS_tables,
        ANSYS_figures,
        master_table,
    )
end
main() = main(get_user_input())
export main

end # module
