# Compare Stress-Strain Data to Michael's
σ_michael_200 = [125000
126000
127000
128000
129000
130000
130300
131000
132000
133000
134000
135000
135100
136000
137000
138000
139000
139300
140000
141000
142000
142700
143000
144000
145000
145727
146000
147000
148000
149000
150000
151000
151704
152000
153000
154000
154285
155000
156000
156682
157000
157511
]

ϵ_michael_200 = [0.001936769
0.002519284
0.00329659
0.00432703
0.005630837
0.007112586
0.007560789
0.008561405
0.009821935
0.010913902
0.01194655
0.013012404
0.013123087
0.014162773
0.015421618
0.016800388
0.018306288
0.018783822
0.019945922
0.021726634
0.023656903
0.025102198
0.025746374
0.028005793
0.030446936
0.032342971
0.033082564
0.035926405
0.038993152
0.042298492
0.045859138
0.049692872
0.052565796
0.0538186
0.058256406
0.063027614
0.064451581
0.068154855
0.073662138
0.077649075
0.079574921
0.082761556
]

user_input = let
    # Material Data
    spec_no = "SA-723"
    type_grade = "3"
    class_condition_temper = "2a"
    KM620_coefficients_table_material_category = "Ferritic steel"
    AIP_material_category = "Q&T Steels"
    num_plastic_points = 20

    # Derived Data
    material_string = make_material_string(spec_no, type_grade, class_condition_temper)
    material_dict = make_material_dict(spec_no, type_grade, class_condition_temper)
    input_file_path = "S:\\Material Properties\\Excel Material Data\\Section II-D Tables.xlsx"
    output_file_path = joinpath(dirname(input_file_path), AIP_material_category, "$material_string.xlsx")
    plot_folder = joinpath(dirname(output_file_path), "Plots")
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
end
ASME_tables, ASME_groups = read_ASME_tables(user_input)
ANSYS_tables, master_table = transform_ASME_tables(ASME_tables, ASME_groups, user_input)

fig = Figure()
axis = Axis(
    fig[1,1],
    title = "SA-723 Grade 3 Class 2a at 200°F",
    xlabel = "Plastic Strain (in in^-1)",
    ylabel = "Stress (psi)",
)
scatterlines!(
    axis,
    ANSYS_tables["Hardening 200°F"]."Plastic Strain (in in^-1)",
    ANSYS_tables["Hardening 200°F"]."Stress (psi)",
    label = "Nathan",
)
scatterlines!(axis, ϵ_michael_200, σ_michael_200, label = "Michael")
Legend(fig[1,2], axis, "Author")
display(fig)
save(joinpath(user_input.plot_folder,"Verification.png"), fig)
save(joinpath(pwd(), "Verification.png"), fig)
