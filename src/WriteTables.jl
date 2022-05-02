# Write to File
mkpath(outputdir)

XLSX.openxlsx(joinpath(outputdir,outputfile), mode="w") do file
    XLSX.rename!(file[1], "Iso Thermal Conductivity")
    XLSX.writetable!(file[1], conductivity_table)
    XLSX.addsheet!(file, "Density")
    XLSX.writetable!(file[2], density_table)
    XLSX.addsheet!(file, "Iso Inst Coef Thermal Expansion")
    XLSX.writetable!(file[3], expansion_table)
    XLSX.addsheet!(file, "Isotropic Elasticity")
    XLSX.writetable!(file[4], elasticity_table)
    XLSX.addsheet!(file, "Multilinear Kinematic Hardening")
    XLSX.writetable!(file[5], temp_table)
    for i in 1:nrow(temp_table)
        file[5][1,3*i] = "Temperature"
        file[5][1,3*i+1] = " = $(temp_table[i,1])°F"
        XLSX.writetable!(file[5], hardening_tables[i], anchor_cell=XLSX.CellRef(2,3*i))
    end
end