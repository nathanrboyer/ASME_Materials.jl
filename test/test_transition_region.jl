using ASME_Materials, GLMakie

user_input1 = (spec_no = "SA-723",
                type_grade = "3",
                class_condition_temper = "2a",
                tableKM620_material_category = "Ferritic steel",
                num_output_stress_points = 50,
                overwrite_yield = true,
                proportional_limit = 1.0e-5,
                input_file_path = "S:\\Material Properties\\Section II-D Tables.xlsx",
                output_file_path = "S:\\Material Properties\\Excel Material Data\\AIP Q&T Steels\\SA-723-3-2a.xlsx",
                output_folder = "S:\\Material Properties\\Excel Material Data\\AIP Q&T Steels",
                plot_folder = "S:\\Material Properties\\Excel Material Data\\AIP Q&T Steels\\Plots",
                material_string = "SA-723-3-2a",
                material_dict = Dict("Spec. No." => x -> x .== "SA-723",
                                    "Type/Grade" => x -> x .== "3",
                                    "Class/Condition/Temper" => x -> x .== "2a"))

user_input2 = (spec_no = "SA-723",
                type_grade = "3",
                class_condition_temper = "2a",
                tableKM620_material_category = "Ferritic steel",
                num_output_stress_points = 50,
                overwrite_yield = false,
                proportional_limit = 2.0e-3,
                input_file_path = "S:\\Material Properties\\Section II-D Tables.xlsx",
                output_file_path = "S:\\Material Properties\\Excel Material Data\\AIP Q&T Steels\\SA-723-3-2a.xlsx",
                output_folder = "S:\\Material Properties\\Excel Material Data\\AIP Q&T Steels",
                plot_folder = "S:\\Material Properties\\Excel Material Data\\AIP Q&T Steels\\Plots",
                material_string = "SA-723-3-2a",
                material_dict = Dict("Spec. No." => x -> x .== "SA-723",
                                    "Type/Grade" => x -> x .== "3",
                                    "Class/Condition/Temper" => x -> x .== "2a"))

data1 = main(user_input1)
data2 = main(user_input2)

temperature = 100

ti1 = findfirst(data1.ANSYS_tables["Stress-Strain"].T .== temperature)
??1 = data1.ANSYS_tables["Stress-Strain"].??_t[ti1]
??1 = data1.ANSYS_tables["Stress-Strain"].??_ts[ti1]
??p1 = data1.ANSYS_tables["Stress-Strain"].??_total[ti1]
??last1 = findfirst(??p1 .> 0.002)
E1 = data1.ANSYS_tables["Stress-Strain"].E_y[ti1]
??1 = ??1[1:??last1]
??1 = ??1[1:??last1]
??1[1] = ??1[1] / E1

ti2 = findfirst(data2.ANSYS_tables["Stress-Strain"].T .== temperature)
??2 = data2.ANSYS_tables["Stress-Strain"].??_t[ti2]
??2 = data2.ANSYS_tables["Stress-Strain"].??_ts[ti2]
??p2 = data2.ANSYS_tables["Stress-Strain"].??_total[ti2]
??last2 = findfirst(??p2 .> 0.002)

E2 = data2.ANSYS_tables["Stress-Strain"].E_y[ti2]
icrossover = findlast(first(??2) .> ??1)
??2_elastic = ??1[1:icrossover]
??2_elastic = ??2_elastic ./ E2
??2 = vcat(??2_elastic, first(??2)/E2 , ??2[2:??last2])
??2 = vcat(??2_elastic, ??2[1:??last2])


cd(raw"S:\Material Properties\ANSYS Material Data\Testing")
fig = Figure(resolution = (1900, 1000))
axis = Axis(fig[1,1],
            title = "Stress-Strain of $(data1.user_input.material_string) at $(temperature)??F",
            xlabel = "Total Strain (in in^-1)",
            ylabel = "Stress (ksi)")
scatterlines!(??1[1:??last1], ??1[1:??last1]./1000, label = "1E-5 in/in")
scatterlines!(??2, ??2./1000, label = "2E-3 in/in")
leg = Legend(fig[1,2], axis, "Proportional Limit")
save("Stress-Strain Transition Region.png", fig)
display(fig)