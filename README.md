# ASME_Materials.jl

Code to convert American Society of Mechanical Engineers (ASME) Boiler and Pressure Vessel Code (BPVC) Section II-D material data tables through Section VIII Division 3 Part KM-620 into material data tables compatible with ANSYS Finite Element Analysis (FEA) software.

## Julia Language Installation

The Julia programming language can be installed for free from your operating system's native store (Microsoft Store, Mac App Store, Ubuntu Software Center, etc.). Just search for `Julia`.

## Prerequisites

The Div3.jl package must be installed from GitHub before this package can be installed.
It defines the Division 3 equations required to transform the data.
Please download and install it first.
https://github.com/nathanrboyer/Div3.jl

## Package Installation

1. Download and extract this package from Github with any available method.
   (This might already be done.)
   ![Github Download](https://sites.northwestern.edu/researchcomputing/files/2021/05/github.png)
2. Search for and open the Julia program.
   ![Julia REPL](https://data-science-with-julia.gitlab.io/images/julia_repl.png)
3. You should see a flashing cursor next to the word `julia>`.
4. Type the close bracket character `]` to enter Pkg mode.
5. You should now see `pkg>` instead of `julia>`.
6. Type `add` followed by the path to the folder you downloaded inside quotation marks.
   Example 1: `add "C:\Users\username\Downloads\ASME_Materials.jl-master"`
   Example 2: `add "S:\Julia\ASME_Materials"`
7. Type Backspace to return to the normal `julia>` prompt.

## Package Usage

The above installation steps will only need to be performed once. Now that Julia and the ASME_Materials package are installed. Just...

1. Open the Julia program.
2. Type `using ASME_Materials`.
3. Follow the instructions.
