"""
    numeric_headers::Vector{Int} = get_numeric_headers(table::DataFrame)

Return all `table` column headers that can can be converted to integers.
"""
function get_numeric_headers(table::DataFrame)
    numeric_headers = Int[]
    for col in names(table)
        try
            num = parse(Int, col)
            push!(numeric_headers, num)
        catch
            continue
        end
    end
    return numeric_headers
end

"""
    row_data::Vector = get_row_data(table::DataFrame, conditions::Dict, [returncolumns])

Returns the `table` row that meets all the provided `conditions`.
`conditions` is a `Dict` which maps column names to filtering functions
e.g. Dict("Column Name" => (x -> x .== cellvalue)).
`returncolumns` can optionally be provided to return only certain columns of the DataFrame.
`returncolumns` may be a single column index or a vector of column indices.
"""
function get_row_data(table::DataFrame, conditions::Dict, returncolumns)
    subset(table, conditions...)[:,string.(returncolumns)] |> only |> Vector
end
function get_row_data(table::DataFrame, conditions::Dict)
    subset(table, conditions...) |> only |> Vector
end

"""
    ANSYS_tables::Dict{String, DataFrame} = transform_ASME_tables(ASME_tables::Dict{String, DataFrame}, ASME_groups::Dict{String, DataFrame})

Create new tables in ANSYS format from the input ASME tables and groups.
"""
function transform_ASME_tables(ASME_tables, ASME_groups)
    # Create Output Table dictionary
    tables = Dict{String, DataFrame}()

    # Isotropic Thermal Conductivity
    tables["Thermal Conductivity"] = select(ASME_tables["TCD"], "Temperature (°F)", "TC (Btu/hr-ft-°F)" => ByRow(x -> x / 3600 / 12) => "TC (Btu s^-1 in ^-1 °F^-1)") |> dropmissing

    # Density
    ρ = ASME_tables["PRD"][ASME_tables["PRD"]."Material" .== ASME_groups["PRD"], "Density (lb/inch^3)"] |> only
    tables["Density"] = DataFrame("Temperature (°F)" => [""], "Density (lbm in^-3)" => [ρ])

    # Isotropic Instantaneous Coefficient of Thermal Expansion
    tables["Thermal Expansion"] = select(ASME_tables["TE"], "Temperature (°F)", "A (10^-6 inch/inch/°F)" => ByRow(x -> x*10^-6) => "Coefficient of Thermal Expansion (°F^-1)") |> dropmissing

    # Isotropic Elasticity
    ν = ASME_tables["PRD"][ASME_tables["PRD"]."Material" .== ASME_groups["PRD"], "Poisson's Ratio"] |> only
    tables["Elasticity"] = DataFrame("Temperature (°F)" => get_numeric_headers(ASME_tables["TM"]),
                                        "Young's Modulus (psi)" => get_row_data(ASME_tables["TM"], Dict("Materials" => x -> x.==ASME_groups["TM"]), get_numeric_headers(ASME_tables["TM"])) .* 10^6,
                                        "Poisson's Ratio" => fill(ν, ncol(ASME_tables["TM"]) - 1)
                                        ) |> dropmissing

    # Multilinear Kinematic Hardening
    ## Yield and Ultimate Strength Data
    yield_temps = get_numeric_headers(ASME_tables["Y"])
    yield_data = get_row_data(ASME_tables["Y"], material_dict, yield_temps) .* 1000
    yield_table =  DataFrame(T = yield_temps, σ_ys = yield_data) |> dropmissing
    ultimate_temps = get_numeric_headers(ASME_tables["U"])
    ultimate_data = get_row_data(ASME_tables["U"], material_dict, ultimate_temps) .* 1000
    ultimate_table =  DataFrame(T = ultimate_temps, σ_uts = ultimate_data) |> dropmissing

    ## Interpolation
    yield_interp = LinearInterpolation(yield_table.T, yield_table.σ_ys, extrapolation_bc=Line())
    ultimate_interp = LinearInterpolation(ultimate_table.T, ultimate_table.σ_uts, extrapolation_bc=Line())
    elasticity_interp = LinearInterpolation(tables["Elasticity"]."Temperature (°F)", tables["Elasticity"]."Young's Modulus (psi)", extrapolation_bc=Line())
    poisson_interp = LinearInterpolation(tables["Elasticity"]."Temperature (°F)", tables["Elasticity"]."Poisson's Ratio", extrapolation_bc=Line())

    ## Build Stress-Strain Table with Interpolated Data
    tables["Stress-Strain"] = outerjoin(yield_table, ultimate_table, on = :T) |> sort
    tables["Stress-Strain"].σ_ys = yield_interp.(tables["Stress-Strain"].T)
    tables["Stress-Strain"].σ_uts = ultimate_interp.(tables["Stress-Strain"].T)
    tables["Stress-Strain"].E_y = elasticity_interp.(tables["Stress-Strain"].T)
    tables["Stress-Strain"].ν = poisson_interp.(tables["Stress-Strain"].T)

    ## Apply KM620 to Stress-Strain Table
    tables["Stress-Strain"].R = R.(tables["Stress-Strain"].σ_ys, tables["Stress-Strain"].σ_uts)
    tables["Stress-Strain"].K = K.(tables["Stress-Strain"].R)
    tables["Stress-Strain"].ϵ_ys = fill(ϵ_ys(), nrow(tables["Stress-Strain"]))
    tables["Stress-Strain"].ϵ_p = fill(only(tableKM620[tableKM620."Material" .== tableKM620_material_category, "ϵₚ"]), nrow(tables["Stress-Strain"]))
    tables["Stress-Strain"].m_1 = m_1.(tables["Stress-Strain"].R, tables["Stress-Strain"].ϵ_p, tables["Stress-Strain"].ϵ_ys)
    tables["Stress-Strain"].m_2 = only(tableKM620[tableKM620."Material" .== tableKM620_material_category, "m₂"]).(tables["Stress-Strain"].R)
    tables["Stress-Strain"].A_1 = A_1.(tables["Stress-Strain"].σ_ys, tables["Stress-Strain"].ϵ_ys, tables["Stress-Strain"].m_1)
    tables["Stress-Strain"].A_2 = A_2.(tables["Stress-Strain"].σ_uts, tables["Stress-Strain"].m_2)
    tables["Stress-Strain"].σ_utst = σ_utst.(tables["Stress-Strain"].σ_uts, tables["Stress-Strain"].m_2)
    ### Fix this
    tables["Stress-Strain"].σ_t = [range(start = tables["Stress-Strain"].σ_ys[i], stop = tables["Stress-Strain"].σ_utst[i], length = num_output_stress_points) for i in 1:nrow(tables["Stress-Strain"])]
    ###
    tables["Stress-Strain"].H = H.(tables["Stress-Strain"].σ_t, tables["Stress-Strain"].σ_ys, tables["Stress-Strain"].σ_uts, tables["Stress-Strain"].K)
    tables["Stress-Strain"].ϵ_1 = ϵ_1.(tables["Stress-Strain"].σ_t, tables["Stress-Strain"].A_1, tables["Stress-Strain"].m_1)
    tables["Stress-Strain"].ϵ_2 = ϵ_2.(tables["Stress-Strain"].σ_t, tables["Stress-Strain"].A_2, tables["Stress-Strain"].m_2)
    tables["Stress-Strain"].γ_1 = γ_1.(tables["Stress-Strain"].ϵ_1, tables["Stress-Strain"].H)
    tables["Stress-Strain"].γ_2 = γ_2.(tables["Stress-Strain"].ϵ_2, tables["Stress-Strain"].H)
    tables["Stress-Strain"].γ_total = tables["Stress-Strain"].γ_1 .+ tables["Stress-Strain"].γ_2
    tables["Stress-Strain"].ϵ_ts = ϵ_ts.(tables["Stress-Strain"].σ_t, tables["Stress-Strain"].E_y, tables["Stress-Strain"].γ_1, tables["Stress-Strain"].γ_2)

    ## Build Temperature Table from Stress-Strain Table
    tables["Temperature"] = DataFrame("Temperature (°F)" => tables["Stress-Strain"].T)

    ## Build Hardening Tables from Stress-Strain Table
    for (i, temp) in enumerate(tables["Stress-Strain"].T)
        tables["Hardening $(temp)°F"] = DataFrame()
        tables["Hardening $(temp)°F"]."Plastic Strain (in in^-1)" = tables["Stress-Strain"][i,"γ_total"]
        tables["Hardening $(temp)°F"]."Stress (psi)" = tables["Stress-Strain"][i,"σ_t"]
    end

    return tables
end