# This file is a part of Julia. License is MIT: https://julialang.org/license

module APITests

using Pkg, Test

include("utils.jl")

@testset "API should accept `AbstractString` arguments" begin
    temp_pkg_dir() do project_path
        with_temp_env() do
            Pkg.add(strip("  Example  "))
            Pkg.rm(strip("  Example "))
        end
    end
end

@testset "Pkg.activate" begin
    temp_pkg_dir() do project_path
        cd_tempdir() do tmp
            path = pwd()
            Pkg.activate(".")
            mkdir("Foo")
            cd(mkdir("modules")) do
                Pkg.generate("Foo")
            end
            Pkg.develop(Pkg.Types.PackageSpec(path="modules/Foo")) # to avoid issue #542
            Pkg.activate("Foo") # activate path Foo over deps Foo
            @test Base.active_project() == joinpath(path, "Foo", "Project.toml")
            Pkg.activate(".")
            rm("Foo"; force=true, recursive=true)
            Pkg.activate("Foo") # activate path from developed Foo
            @test Base.active_project() == joinpath(path, "modules", "Foo", "Project.toml")
            Pkg.activate(".")
            Pkg.activate("./Foo") # activate empty directory Foo (sidestep the developed Foo)
            @test Base.active_project() == joinpath(path, "Foo", "Project.toml")
            Pkg.activate(".")
            Pkg.activate("Bar") # activate empty directory Bar
            @test Base.active_project() == joinpath(path, "Bar", "Project.toml")
            Pkg.activate(".")
            Pkg.add("Example") # non-deved deps should not be activated
            Pkg.activate("Example")
            @test Base.active_project() == joinpath(path, "Example", "Project.toml")
            Pkg.activate(".")
            cd(mkdir("tests"))
            Pkg.activate("Foo") # activate developed Foo from another directory
            @test Base.active_project() == joinpath(path, "modules", "Foo", "Project.toml")
            Pkg.activate() # activate home project
            @test Base.ACTIVE_PROJECT[] === nothing
        end
    end
end

@testset "Pkg.status" begin
    temp_pkg_dir() do project_path
        Pkg.add(["Example", "Random"])
        Pkg.status()
        Pkg.status("Example")
        Pkg.status(["Example", "Random"])
        Pkg.status(PackageSpec("Example"))
        Pkg.status(PackageSpec(uuid = "7876af07-990d-54b4-ab0e-23690620f79a"))
        Pkg.status(PackageSpec.(["Example", "Random"]))
        Pkg.status(; mode=PKGMODE_MANIFEST)
        Pkg.status("Example"; mode=PKGMODE_MANIFEST)
        @test_deprecated Pkg.status(PKGMODE_MANIFEST)
    end
end

end # module APITests
