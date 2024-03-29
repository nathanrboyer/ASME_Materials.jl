"""
    info_table()

Create an informational table from relevant user inputs.
"""
function make_info_table(;
        num_output_stress_points,
        KM620_coefficients_table_material_category,
        _...,
    )
    info_table = DataFrame("Variable" => [], "Value" => [], "Description" => [])
    push!(
        info_table,
        (
            "num_output_stress_points",
            num_output_stress_points,
            "Number of Plastic Stress-Strain Data Points",
        ),
    )
    push!(
        info_table,
        (
            "KM620_coefficients_table_material_category",
            KM620_coefficients_table_material_category,
            "Table KM-620 Material Category",
        ),
    )
    return info_table
end

"""
    write_ANSYS_tables(tables::Dict{String, DataFrame}, filepath::String)

Writes ANSYS `tables` to an Excel file.
Path to output Excel file (including file name) is specified by `filepath`.
"""
function write_ANSYS_tables(tables::Dict{String, DataFrame}, filepath::String)
    XLSX.openxlsx(filepath, mode="w") do file
        sheet = file[1]
        XLSX.rename!(sheet, "Yield Strength (Info)")
        XLSX.writetable!(sheet, tables["Yield Strength"])
        sheet = XLSX.addsheet!(file, "Ultimate Strength (Info)")
        XLSX.writetable!(sheet, tables["Ultimate Strength"])
        sheet = XLSX.addsheet!(file, "Density")
        XLSX.writetable!(sheet, tables["Density"])
        sheet = XLSX.addsheet!(file, "Iso Inst Coef Thermal Expansion")
        XLSX.writetable!(sheet, tables["Thermal Expansion"])
        sheet = XLSX.addsheet!(file, "Isotropic Elasticity")
        XLSX.writetable!(sheet, tables["Elasticity"])
        sheet = XLSX.addsheet!(file, "Multilinear Kinematic Hardening")
        XLSX.writetable!(sheet, tables["Temperature"])
        for (i, temp) in enumerate(tables["Temperature"][:,1])
            sheet[1,3*i] = "Temperature = $(temp)°F"
            XLSX.writetable!(sheet, tables["Hardening $(temp)°F"], anchor_cell=XLSX.CellRef(2,3*i))
        end
        sheet = XLSX.addsheet!(file, "Iso Thermal Conductivity")
        XLSX.writetable!(sheet, tables["Thermal Conductivity"])
        sheet = XLSX.addsheet!(file, "Perfectly Plastic Hardening")
        sheet["A1"] = "To create an Elastic Perfectly-Plastic (EPP) material model, \
            duplicate the material and replace the Multilinear Kinematic Hardening data \
            with the data below."
        sheet["A2"] = "Use only the first datapoint at each temperature for a pure EPP material. \
            Use both datapoints at each temperature for a stabilized EPP material. \
            Stabilization is the maximum amount allowed by KM-610."
        XLSX.writetable!(sheet, tables["EPP"], anchor_cell=XLSX.CellRef("A4"))
    end
end

"""
    write_ANSYS_tables(tables::Dict{String, DataFrame}, user_input::NamedTuple)

Writes ANSYS `tables` to an Excel file using information specified in `user_input`.
`output_file_path`, `proportional_limit`, `num_output_stress_points`,
and `KM620_coefficients_table_material_category` must be present in `user_input`.
"""
function write_ANSYS_tables(tables::Dict{String, DataFrame}, user_input::NamedTuple)
    XLSX.openxlsx(user_input.output_file_path, mode="w") do file
        sheet = file[1]
        XLSX.rename!(sheet, "Overview (Info)")
        sheet["A1"] = "The ASME_Materials Julia package created this Excel file \
            using the user inputs below."
        sheet["A2"] = "All sheets, except those with \"(Info)\", should be copied directly \
            into ANSYS to create the elastic-plastic material models."
        XLSX.writetable!(sheet, make_info_table(; user_input...), anchor_cell=XLSX.CellRef("A4"))
        sheet = XLSX.addsheet!(file, "Yield Strength (Info)")
        XLSX.writetable!(sheet, tables["Yield Strength"])
        sheet = XLSX.addsheet!(file, "Ultimate Strength (Info)")
        XLSX.writetable!(sheet, tables["Ultimate Strength"])
        sheet = XLSX.addsheet!(file, "Density")
        XLSX.writetable!(sheet, tables["Density"])
        sheet = XLSX.addsheet!(file, "Iso Inst Coef Thermal Expansion")
        XLSX.writetable!(sheet, tables["Thermal Expansion"])
        sheet = XLSX.addsheet!(file, "Isotropic Elasticity")
        XLSX.writetable!(sheet, tables["Elasticity"])
        sheet = XLSX.addsheet!(file, "Multilinear Kinematic Hardening")
        XLSX.writetable!(sheet, tables["Temperature"])
        for (i, temp) in enumerate(tables["Temperature"][:,1])
            sheet[1,3*i] = "Temperature = $(temp)°F"
            XLSX.writetable!(sheet, tables["Hardening $(temp)°F"], anchor_cell=XLSX.CellRef(2,3*i))
        end
        sheet = XLSX.addsheet!(file, "Iso Thermal Conductivity")
        XLSX.writetable!(sheet, tables["Thermal Conductivity"])
        sheet = XLSX.addsheet!(file, "Perfectly Plastic Hardening")
        sheet["A1"] = "To create an Elastic Perfectly-Plastic (EPP) material model, \
            duplicate the material and replace the Multilinear Kinematic Hardening data \
            with the data below."
        sheet["A2"] = "Use only the first datapoint at each temperature for a pure EPP material. \
            Use both datapoints at each temperature for a stabilized EPP material. \
            Stabilization is the maximum amount allowed by KM-610."
        XLSX.writetable!(sheet, tables["EPP"], anchor_cell=XLSX.CellRef("A4"))
    end
end
