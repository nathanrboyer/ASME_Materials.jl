user_input = (
    spec_no = "SA-723",
    type_grade = "3",
    class_condition_temper = "2a",
    KM620_coefficients_table_material_category = "Ferritic steel",
    num_output_stress_points = 50,
    overwrite_yield = true,
    proportional_limit = 2.0e-5,
    input_file_path = "S:\\Material Properties\\Excel Material Data\\Section II-D Tables.xlsx",
    output_file_path = "S:\\Material Properties\\Excel Material Data\\Q&T Steels\\SA-723-3-2a.xlsx",
    output_folder = "S:\\Material Properties\\Excel Material Data\\Q&T Steels",
    plot_folder = "S:\\Material Properties\\Excel Material Data\\Q&T Steels\\Plots",
    material_string = "SA-723-3-2a",
    material_dict = Dict(
        "Spec. No." => x -> x .== "SA-723",
        "Type/Grade" => x -> x .== "3",
        "Class/Condition/Temper" => x -> x .== "2a"
    )
)
ASME_tables, ASME_groups = read_ASME_tables(user_input)
ANSYS_tables = transform_ASME_tables(ASME_tables, ASME_groups, user_input)

write_ANSYS_tables(ANSYS_tables, user_input)
write_ANSYS_tables(ANSYS_tables, user_input.output_file_path)
