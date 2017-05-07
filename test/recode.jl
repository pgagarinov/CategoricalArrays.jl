module TestRecode
    using Base.Test
    using CategoricalArrays
    using CategoricalArrays: DefaultRefType, CatArray, CatVector
    using NullableArrays


    ## Test recode!, used by recode

    # Test both recoding into x itself and into an uninitialized vector
    # (since for CategoricalVectors possible bugs can happen when working in-place)

    # Recoding from Int to Int
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test y === z
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [6, 7, 8, 100, 0, -1]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int with duplicate recoded values
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 1=>100, 2:4=>100, [5; 9:10]=>-1)
        @test y === z
        @test y == [100, 100, 100, 100, -1, 6, 7, 8, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [6, 7, 8, 100, -1]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int with unused level
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 1=>100, 2:4=>0, [5; 9:10]=>-1, 100=>1)
        @test y === z
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [6, 7, 8, 100, 0, -1, 1]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int with duplicate default
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 100, 1=>100, 2:4=>100, [5; 9:10]=>-1)
        @test y === z
        @test y == [100, 100, 100, 100, -1, 100, 100, 100, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [100, -1]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int, with default
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, -10, 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test y === z
        @test y == [100, 0, 0, 0, -1, -10, -10, -10, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [100, 0, -1, -10]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int, with a first value being Float64
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 1.0=>100, 2:4=>0, [5; 9:10]=>-1)
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [6, 7, 8, 100, 0, -1]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int with overlapping pairs
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 1=>100, 2:4=>0, [5; 9:10]=>-1, 1:10=>0)
        @test y === z
        @test y == [100, 0, 0, 0, -1, 0, 0, 0, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [100, 0, -1]
            @test !isordered(y)
        end
    end

    # Recoding from Int to Int, with changes to levels order
    for x in ([1:10;], CategoricalArray(1:10)),
        (y, z) in ((x, similar(x)), (x, Array{Int}(copy(x))), (x, CategoricalArray(copy(x)), (x, x)))
        y = @inferred recode!(z, x, 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test y === z
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        if isa(y, CategoricalArray)
            @test levels(y) == [6, 7, 8, 100, 0, -1]
            @test !isordered(y)
        end
    end

    ## Test promotion

    for x in (1:10, [1:10;], CategoricalArray(1:10))
        # Recoding from Int to Float64 due to a second value being Float64
        y = @inferred recode(x, 1=>100.0, 2:4=>0, [5; 9:10]=>-1)
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        if isa(x, CatArray)
            @test isa(y, CatVector{Float64, DefaultRefType})
            @test levels(y) == [6, 7, 8, 100, 0, -1]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{Float64}
        end

        # Recoding from Int to Float64, with Float64 default and all other values Int
        y = @inferred recode(x, -10.0, 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test y == [100, 0, 0, 0, -1, -10, -10, -10, -1, -1]
        if isa(x, CatArray)
            @test isa(y, CatVector{Float64, DefaultRefType})
            @test levels(y) == [100, 0, -1, -10]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{Float64}
        end

        # Recoding from Int to Any
        y = @inferred recode(x, 1=>"a", 2:4=>0, [5; 9:10]=>-1)
        @test y == ["a", 0, 0, 0, -1, 6, 7, 8, -1, -1]
        if isa(x, CatArray)
            @test isa(y, CatVector{Any, DefaultRefType})
            @test levels(y) == [6, 7, 8, "a", 0, -1]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{Any}
        end

        # Recoding from Int to String, with String default
        y = @inferred recode(x, "d", 1=>"a", 2:4=>"b", [5; 9:10]=>"c")
        @test y == ["a", "b", "b", "b", "c", "d", "d", "d", "c", "c"]
        if isa(x, CatArray)
            @test isa(y, CatVector{String, DefaultRefType})
            @test levels(y) == ["a", "b", "c", "d"]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{String}
        end

        # Recoding from Int to String, with all original levels recoded
        y = @inferred recode(x, 1=>"a", 2:4=>"b", [5; 9:10]=>"c", 6:8=>"d")
        @test y == ["a", "b", "b", "b", "c", "d", "d", "d", "c", "c"]
        if isa(x, CatArray)
            @test isa(y, CatVector{String, DefaultRefType})
            @test levels(y) == ["a", "b", "c", "d"]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{String}
        end

        # Recoding from Int to Int/String (i.e. Any), with default String and other values Int
        y = @inferred recode(x, "x", 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test y == [100, 0, 0, 0, -1, "x", "x", "x", -1, -1]
        if isa(x, CatArray)
            @test isa(y, CatVector{Any, DefaultRefType})
            @test levels(y) == [100, 0, -1, "x"]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{Any}
        end

        # Recoding from Int to Int/String, without any Int value in pairs
        # and keeping some original Int levels
        # This must fail since we cannot take into account original eltype (whether original
        # levels are kept is only known at run time)
        res = @test_throws ArgumentError recode(x, 1=>"a", 2:4=>"b", [5; 9:10]=>"c")
        @test sprint(showerror, res.value) == "ArgumentError: cannot `convert` value 6 (of type Int64) to type of recoded levels (String). This will happen when not all original levels are recoded (i.e. some are preserved) and their type is incompatible with that of recoded levels."

        # Recoding from Int to Nullable{Int} with null default
        y = @inferred recode(x, Nullable(), 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test isequal(y, [100, 0, 0, 0, -1, Nullable(), Nullable(), Nullable(), -1, -1])
        if isa(x, CatArray)
            @test isa(y, NullableCategoricalVector{Int, DefaultRefType})
            @test levels(y) == [100, 0, -1]
            @test !isordered(y)
        else
            @test typeof(y) === NullableVector{Int}
        end

        # Recoding from Int to Nullable{Int} with nullable non-null default
        y = @inferred recode(x, Nullable(1), 1=>100, 2:4=>0, [5; 9:10]=>-1)
        @test isequal(y, Nullable{Int}[100, 0, 0, 0, -1, 1, 1, 1, -1, -1])
        if isa(x, CatArray)
            @test isa(y, NullableCategoricalVector{Int, DefaultRefType})
            @test levels(y) == [100, 0, -1, 1]
            @test !isordered(y)
        else
            @test typeof(y) === NullableVector{Int}
        end

        # Recoding from Int to Nullable{Float64} with nullable value and mixed types
        y = @inferred recode(x, 1=>Nullable(100), 2:4=>0, [5; 9:10]=>-1.0)
        @test isequal(y, Nullable{Float64}[100, 0, 0, 0, -1, 6, 7, 8, -1, -1])
        if isa(x, CatArray)
            @test isa(y, NullableCategoricalVector{Float64, DefaultRefType})
            @test levels(y) == [6, 7, 8, 100, 0, -1]
            @test !isordered(y)
        else
            @test typeof(y) === NullableVector{Float64}
        end
    end

    for x in (["a", "c", "b", "a"], CategoricalArray(["a", "c", "b", "a"]))
        # Recoding from String to String
        y = @inferred recode(x, "c"=>"x", "b"=>"y", "a"=>"z")
        @test y == ["z", "x", "y", "z"]
        if isa(x, CatArray)
            @test typeof(y) === CategoricalVector{String, DefaultRefType}
            @test levels(y) == ["x", "y", "z"]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{String}
        end
    end

    for x in (['a' 'c'; 'b' 'a'], CategoricalArray(['a' 'c'; 'b' 'a']))
        # Recoding a Matrix
        y = @inferred recode(x, 'c'=>'x', 'b'=>'y', 'a'=>'z')
        @test y == ['z' 'x'; 'y' 'z']
        if isa(x, CatArray)
            @test typeof(y) === CategoricalMatrix{Char, DefaultRefType}
            @test levels(y) == ['x', 'y', 'z']
            @test !isordered(y)
        else
            @test typeof(y) === Matrix{Char}
        end
    end

    for x in (10:-1:1, CategoricalArray(10:-1:1))
        # Recoding from Int to Int/String (i.e. Any), with index and levels in different orders
        y = @inferred recode(x, 0, 1=>"a", 2:4=>"c", [5; 9:10]=>"b")
        @test y == ["b", "b", 0, 0, 0, "b", "c", "c", "c", "a"]
        if isa(x, CatArray)
            @test typeof(y) === CategoricalVector{Any, DefaultRefType}
            @test levels(y) == ["a", "c", "b", 0]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{Any}
        end

        # Recoding from Int to String via default, with index and levels in different orders
        y = @inferred recode(x, "x", 1=>"a", 2:4=>"c", [5; 9:10]=>"b")
        @test y == ["b", "b", "x", "x", "x", "b", "c", "c", "c", "a"]
        if isa(x, CatArray)
            @test typeof(y) === CategoricalVector{String, DefaultRefType}
            @test levels(y) == ["a", "c", "b", "x"]
            @test !isordered(y)
        else
            @test typeof(y) === Vector{String}
        end
    end

    # Recoding CategoricalArray with custom reftype
    x = CategoricalVector{Int, UInt8}(1:10)
    y = @inferred recode(x, 1=>100, 2:4=>0, [5; 9:10]=>-1)
    @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
    @test typeof(y) === CategoricalVector{Int, UInt8}
    @test levels(y) == [6, 7, 8, 100, 0, -1]
    @test !isordered(y)

    # Recoding ordered CategoricalArray and merging two categories
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, "c"=>"a")
    @test y == ["a", "a", "b", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["a", "b"]
    @test isordered(y)

    # Recoding ordered CategoricalArray and merging one category into another (contd.)
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, "b"=>"c")
    @test y == ["a", "c", "c", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["a", "c"]
    @test isordered(y)

    # Recoding ordered CategoricalArray with new level which cannot be ordered
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, "b"=>"d")
    @test y == ["a", "c", "d", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["a", "c", "d"]
    @test !isordered(y)

    # Recoding ordered CategoricalArray with conflicting orders
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, "b"=>"b", "a"=>"a")
    @test y == ["a", "c", "b", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["c", "b", "a"]
    @test !isordered(y)

    # Recoding ordered CategoricalArray with default already in levels
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, "a", "c"=>"b")
    @test y == ["a", "b", "a", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["b", "a"]
    @test !isordered(y)

    # Recoding ordered CategoricalArray with default not in levels
    x = CategoricalArray(["d", "c", "b", "d"])
    ordered!(x, true)
    y = @inferred recode(x, "a", "c"=>"b")
    @test y == ["a", "b", "a", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["b", "a"]
    @test !isordered(y)
    

    # test with NullableArray/NullableCategoricalArray input
end
