module TestRecode
    using Base.Test
    using CategoricalArrays
    using CategoricalArrays: DefaultRefType

    # Temporary: needed until this is included in supported Julia releases.
    # Only needed for heterogeneous pair vectors (which are a corner case)
    Base.promote_rule{A1, B1, A2, B2}(::Type{Pair{A1, B1}}, ::Type{Pair{A2, B2}}) =
        Pair{promote_type(A1, A2), promote_type(B1, B2)}

    for x in (1:10, [1:10;], CategoricalArray(1:10))
        # Recoding from Int to Int
        y = @inferred recode(x, [1=>100, 2:4=>0, [5; 9:10]=>-1])
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        @test typeof(y) === CategoricalVector{Int, DefaultRefType}
        @test levels(y) == [6, 7, 8, 100, 0, -1]
        @test !isordered(y)

        # Recoding from Int to Int, with a first value being Float64
        y = @inferred recode(x, [1.0=>100, 2:4=>0, [5; 9:10]=>-1])
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        @test typeof(y) === CategoricalVector{Int, DefaultRefType}
        @test levels(y) == [6, 7, 8, 100, 0, -1]
        @test !isordered(y)

        # Recoding from Int to Float64 due to a second value being Float64
        y = @inferred recode(x, [1=>100.0, 2:4=>0, [5; 9:10]=>-1])
        @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
        @test typeof(y) === CategoricalVector{Float64, DefaultRefType}
        @test levels(y) == [6, 7, 8, 100, 0, -1]
        @test !isordered(y)

        # Recoding from Int to Int, with default
        y = @inferred recode(x, [1=>100, 2:4=>0, [5; 9:10]=>-1], -10)
        @test y == [100, 0, 0, 0, -1, -10, -10, -10, -1, -1]
        @test typeof(y) === CategoricalVector{Int, DefaultRefType}
        @test levels(y) == [100, 0, -1, -10]
        @test !isordered(y)

        # Recoding from Int to Float64, with Float64 default and all other values Int
        y = @inferred recode(x, [1=>100, 2:4=>0, [5; 9:10]=>-1], -10.0)
        @test typeof(y) === CategoricalVector{Float64, DefaultRefType}
        @test levels(y) == [100, 0, -1, -10]
        @test !isordered(y)

        # Recoding from Int to Any, with more than one second value (corner case)
        y = @inferred recode(x, [1=>(100, 101), 2:4=>0, [5; 9:10]=>-1])
        @test y == [(100, 101), 0, 0, 0, -1, 6, 7, 8, -1, -1]
        @test typeof(y) === CategoricalVector{Any, DefaultRefType}
        @test levels(y) == [6, 7, 8, (100, 101), 0, -1]
        @test !isordered(y)

        # Recoding from Int to String, with String default
        y = @inferred recode(x, [1=>"a", 2:4=>"b", [5; 9:10]=>"c"], "d")
        @test y == ["a", "b", "b", "b", "c", "d", "d", "d", "c", "c"]
        @test typeof(y) === CategoricalVector{String, DefaultRefType}
        @test levels(y) == ["a", "b", "c", "d"]
        @test !isordered(y)

        # Recoding from Int to String, with all original levels recoded
        y = @inferred recode(x, [1=>"a", 2:4=>"b", [5; 9:10]=>"c", 6:8=>"d"])
        @test y == ["a", "b", "b", "b", "c", "d", "d", "d", "c", "c"]
        @test typeof(y) === CategoricalVector{String, DefaultRefType}
        @test levels(y) == ["a", "b", "c", "d"]
        @test !isordered(y)

        # Recoding from Int to Int/String (i.e. Any), with default String and other values Int
        y = @inferred recode(x, [1=>100, 2:4=>0, [5; 9:10]=>-1], "x")
        @test typeof(y) === CategoricalVector{Any, DefaultRefType}
        @test levels(y) == [100, 0, -1, "x"]
        @test !isordered(y)

        # Recoding from Int to Int/String, without any Int value in pairs
        # and keeping some original Int levels
        # This must fail since we cannot take into account original eltype (whether original levels
        # are kept is only known at compile time)
        res = @test_throws ArgumentError recode(x, [1=>"a", 2:4=>"b", [5; 9:10]=>"c"])
        @test sprint(showerror, res.value) == "ArgumentError: cannot `convert` value 6 (of type Int64) to type of recoded levels (String). This will happen when not all original levels are recoded (i.e. some are preserved) and their type is incompatible with that of recoded levels."
    end

    for x in (["a", "c", "b", "a"], CategoricalArray(["a", "c", "b", "a"]))
        # Recoding from String to String
        y = @inferred recode(x, ["c"=>"x", "b"=>"y", "a"=>"z"])
        @test y == ["z", "x", "y", "z"]
        @test typeof(y) === CategoricalVector{String, DefaultRefType}
        @test levels(y) == ["x", "y", "z"]
        @test !isordered(y)
    end

    for x in (['a' 'c'; 'b' 'a'], CategoricalArray(['a' 'c'; 'b' 'a']))
        # Recoding a Matrix
        y = @inferred recode(x, ['c'=>'x', 'b'=>'y', 'a'=>'z'])
        @test y == ['z' 'x'; 'y' 'z']
        @test typeof(y) === CategoricalMatrix{Char, DefaultRefType}
        @test levels(y) == ['x', 'y', 'z']
        @test !isordered(y)
    end

    for x in (10:-1:1, CategoricalArray(10:-1:1))
        # Recoding from Int to Int/String (i.e. Any), with index and levels in different orders
        y = @inferred recode(x, [1=>"a", 2:4=>"c", [5; 9:10]=>"b"], 0)
        @test y == ["b", "b", 0, 0, 0, "b", "c", "c", "c", "a"]
        @test typeof(y) === CategoricalVector{Any, DefaultRefType}
        @test levels(y) == ["a", "c", "b", 0]
        @test !isordered(y)

        # Recoding from Int to String via default, with index and levels in different orders
        y = @inferred recode(x, [1=>"a", 2:4=>"c", [5; 9:10]=>"b"], "x")
        @test y == ["b", "b", "x", "x", "x", "b", "c", "c", "c", "a"]
        @test typeof(y) === CategoricalVector{String, DefaultRefType}
        @test levels(y) == ["a", "c", "b", "x"]
        @test !isordered(y)
    end

    # Recoding CategoricalArray with custom reftype
    x = CategoricalVector{Int, UInt8}(1:10)
    y = @inferred recode(x, [1=>100, 2:4=>0, [5; 9:10]=>-1])
    @test y == [100, 0, 0, 0, -1, 6, 7, 8, -1, -1]
    @test typeof(y) === CategoricalVector{Int, UInt8}
    @test levels(y) == [6, 7, 8, 100, 0, -1]
    @test !isordered(y)

    # Recoding ordered CategoricalArray and merging two categories
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, ["c"=>"a"])
    @test y == ["a", "a", "b", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["a", "b"]
    @test isordered(y)

    # Recoding ordered CategoricalArray and merging one category into another (contd.)
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, ["b"=>"c"])
    @test y == ["a", "c", "c", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["a", "c"]
    @test isordered(y)

    # Recoding ordered CategoricalArray and breaking orderedness
    x = CategoricalArray(["a", "c", "b", "a"])
    ordered!(x, true)
    y = @inferred recode(x, ["b"=>"d"])
    @test y == ["a", "c", "d", "a"]
    @test typeof(y) === CategoricalVector{String, DefaultRefType}
    @test levels(y) == ["a", "c", "d"]
    @test !isordered(y)

    # TODO: test overlapping pairs, and pairs with no matches
    # fix recode!(CategoricalArray(x), CategoricalArray(x), 1, [1:1=>100, 4:4=>0, 5:6=>-1])
    # recode!(CategoricalArray(x), CategoricalArray(x), 1, [1=>100, 4=>0, 5:6=>-1])
end
