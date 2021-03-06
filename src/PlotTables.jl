"""
    fig_tc, fig_te, fig_ym, fig_ps, fig_epp = plot_ANSYS_tables(tables::Dict, material_string::String[, output_folder::String = pwd()])

Plots ANSYS `tables`, titles figures with `material_string`, and saves figures to `output_folder`.

# Figures
- `fig_tc`: Thermal Conductivity
- `fig_te`: Coefficient of Thermal Expansion Young's Modulus
- `fig_ym`: Young's Modulus
- `fig_ps`: Plastic Strain
- `fig_epp`: Elastic Perfectly Plastic Stress-Strain Curves with Stabilization
"""
function plot_ANSYS_tables(tables::Dict, material_string::String, output_folder::String = pwd())
    mkpath(output_folder)

    # Isotropic Thermal Conductivity
    fig1 = Figure()
    axis1 = Axis(fig1[1,1],
                title = "Thermal Conductivity of $material_string",
                xlabel = "Temperature (°F)",
                ylabel = "Thermal Conductivity (Btu s^-1 in ^-1 °F^-1)")
    scatterlines!(tables["Thermal Conductivity"]."Temperature (°F)",
                    tables["Thermal Conductivity"]."TC (Btu s^-1 in ^-1 °F^-1)")
    display(fig1)
    save(joinpath(output_folder,string(material_string,"-ThermalConductivity",".png")), fig1)

    # Isotropic Instantaneous Coefficient of Thermal Expansion
    fig2 = Figure()
    axis2 = Axis(fig2[1,1],
                title = "Thermal Expansion of $material_string",
                xlabel = "Temperature (°F)",
                ylabel = "Instantaneous Thermal Expansion Coefficient (°F^-1)")
    scatterlines!(tables["Thermal Expansion"]."Temperature (°F)",
                    tables["Thermal Expansion"]."Coefficient of Thermal Expansion (°F^-1)")
    display(fig2)
    save(joinpath(output_folder,string(material_string,"-ThermalExpansion",".png")), fig2)

    # Isotropic Elasticity
    fig3 = Figure()
    axis3 = Axis(fig3[1,1],
                title = "Elasticity of $material_string",
                xlabel = "Temperature (°F)",
                ylabel = "Young's Modulus (psi)")
    scatterlines!(tables["Elasticity"]."Temperature (°F)",
                    tables["Elasticity"]."Young's Modulus (psi)")
    display(fig3)
    save(joinpath(output_folder,string(material_string,"-Elasticity",".png")), fig3)

    # Multilinear Kinematic Hardening
    fig4 = Figure()
    axis4 = Axis(fig4[1,1],
                title = "Stress-Strain Curves of $material_string",
                xlabel = "Plastic Strain (in in^-1)",
                ylabel = "Stress (psi)")
    for temp in tables["Temperature"][:,1]
        scatterlines!(tables["Hardening $(temp)°F"]."Plastic Strain (in in^-1)",
                        tables["Hardening $(temp)°F"]."Stress (psi)",
                        label = "$(temp)°F",
                        color=ColorSchemes.rainbow[temp/tables["Temperature"][end,1]])
    end
    Legend(fig4[1,2], axis4, "Temperature")
    display(fig4)
    save(joinpath(output_folder,string(material_string,"-PlasticStrain",".png")), fig4)

    # Perfectly Plastic Hardening
    fig5 = Figure()
    axis5 = Axis(fig5[1,1],
                title = "EPP Stress-Strain Curves of $material_string",
                xlabel = "Total Strain (in in^-1)",
                ylabel = "Stress (psi)")
    elasticity_interp = LinearInterpolation(tables["Elasticity"]."Temperature (°F)", tables["Elasticity"]."Young's Modulus (psi)", extrapolation_bc=Line())
    largest_temp = tables["EPP"][end-2,"Temperature (°F)"]
    for i in 1:Int(nrow(tables["EPP"])/3)
        local j = 3 * (i - 1) + 1
        local temp = tables["EPP"][j, "Temperature (°F)"]
        local yield_stress = tables["EPP"][j, "Stress (psi)"]
        local ultimate_stress = tables["EPP"][j+1, "Stress (psi)"]
        local yield_strain = yield_stress/elasticity_interp(temp) + tables["EPP"][j, "Plastic Strain (in in^-1)"]
        local ultimate_strain = ultimate_stress/elasticity_interp(temp) + tables["EPP"][j+1, "Plastic Strain (in in^-1)"]
        local x = [0, yield_strain, ultimate_strain]
        local y = [0, yield_stress, ultimate_stress]
        scatterlines!(x, y, label = "$(temp)°F", color=ColorSchemes.rainbow[temp/largest_temp])
    end
    Legend(fig5[1,2], axis5, "Temperature")
    display(fig5)
    save(joinpath(output_folder,string(material_string,"-EPPStabilized",".png")), fig5)

    return fig1, fig2, fig3, fig4, fig5
end

"""
    fig_tc, fig_te, fig_ym, fig_ps, fig_epp = plot_ANSYS_tables(tables::Dict, user_input::NamedTuple)

Plots ANSYS `tables`, titles figures with `user_input.material_string`, and saves figures to `user_input.plot_folder`.

# Figures
- `fig_tc`: Thermal Conductivity
- `fig_te`: Coefficient of Thermal Expansion Young's Modulus
- `fig_ym`: Young's Modulus
- `fig_ps`: Plastic Strain
- `fig_epp`: Elastic Perfectly Plastic Stress-Strain Curves with Stabilization
"""
function plot_ANSYS_tables(tables::Dict, user_input::NamedTuple)
    material_string = user_input.material_string
    output_folder = user_input.plot_folder
    plot_ANSYS_tables(tables::Dict, material_string::String, output_folder::String)
end