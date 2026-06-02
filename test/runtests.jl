using Test
using Normaliz
using CxxWrap

@testset "basic NmzMatrix tests" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])

  xx = Normaliz.NmzMatrix{Normaliz.NmzInteger}([1 2 ; 3 5])

  xx = Normaliz.NmzMatrix{Int}([1 2 ; 3 5])
end

@testset "BigInt scalar conversions" begin
  integer = big(2)^100 + 123
  nmz_integer = convert(Normaliz.NmzInteger, integer)
  @test nmz_integer isa Normaliz.NmzInteger
  @test convert(BigInt, nmz_integer) == integer
  @test convert(BigInt, convert(Normaliz.NmzInteger, -integer)) == -integer
  @test convert(BigInt, convert(Normaliz.NmzInteger, big(0))) == 0

  rational = integer // (big(2)^80 + 5)
  nmz_rational = convert(Normaliz.NmzRational, rational)
  @test nmz_rational isa Normaliz.NmzRational
  @test numerator(nmz_rational) isa Normaliz.NmzInteger
  @test denominator(nmz_rational) isa Normaliz.NmzInteger
  @test convert(BigInt, numerator(nmz_rational)) == numerator(rational)
  @test convert(BigInt, denominator(nmz_rational)) == denominator(rational)
  @test convert(Rational{BigInt}, nmz_rational) == rational

  nmz_num = convert(Normaliz.NmzInteger, numerator(rational))
  nmz_den = convert(Normaliz.NmzInteger, denominator(rational))
  @test convert(Rational{BigInt}, Normaliz.NmzRational(nmz_num, nmz_den)) == rational
  @test convert(Rational{BigInt}, nmz_num // nmz_den) == rational
end

@testset "BigInt matrix conversions" begin
  integer = big(2)^100 + 123
  integers = BigInt[integer 2; 3 4]
  nmz_integers = Normaliz.NmzMatrix{Normaliz.NmzInteger}(integers)
  @test Matrix{BigInt}(nmz_integers) == integers

  rationals = Rational{BigInt}[integer//3 2//5; 7//11 13//17]
  nmz_rationals = Normaliz.NmzMatrix{Normaliz.NmzRational}(rationals)
  @test Matrix{Rational{BigInt}}(nmz_rationals) == rationals
end

@testset "cone input normalization" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1//2 2 ; 3 5])
  gg = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 1])
  input_keys, input_matrices = Normaliz._normaliz_input(Dict(:cone => xx, :grading => gg))
  input_key_strings = collect(input_keys)

  @test input_keys isa CxxWrap.StdLib.StdVector{CxxWrap.StdLib.StdString}
  @test Set(input_key_strings) == Set(["cone", "grading"])
  @test length(input_matrices) == 2

  cone_index = findfirst(==("cone"), input_key_strings)
  grading_index = findfirst(==("grading"), input_key_strings)
  @test size(input_matrices[cone_index][]) == (2, 2)
  @test string(input_matrices[cone_index][][1, 1]) == "1/2"
  @test size(input_matrices[grading_index][]) == (1, 2)

  input_keys, input_matrices = Normaliz._normaliz_input(
      Dict(:cone => [1//2 2 ; 3 5], :grading => [1 1]))
  input_key_strings = collect(input_keys)
  cone_index = findfirst(==("cone"), input_key_strings)
  grading_index = findfirst(==("grading"), input_key_strings)
  @test input_matrices[cone_index][] isa Normaliz.NmzMatrix{Normaliz.NmzRational}
  @test string(input_matrices[cone_index][][1, 1]) == "1/2"
  @test size(input_matrices[grading_index][]) == (1, 2)

  large_integer = big(2)^80 + 1
  input_keys, input_matrices = Normaliz._normaliz_input(
      Dict(:cone => BigInt[large_integer 2; 3 4]))
  @test string(input_matrices[1][][1, 1]) == string(large_integer)

  integer_matrix = Normaliz.NmzMatrix{Normaliz.NmzInteger}([1 2 ; 3 4])
  input_keys, input_matrices = Normaliz._normaliz_input(Dict(:cone => integer_matrix))
  @test input_matrices[1][] isa Normaliz.NmzMatrix{Normaliz.NmzRational}
  @test string(input_matrices[1][][1, 1]) == "1"

  yy = Normaliz.LongLongCone(Dict(:cone => [1//2 2 ; 3 5], :grading => [1 1]))
  @test yy isa Normaliz.Cone

  err = @test_throws ArgumentError Normaliz._normaliz_input(Dict(:cone => "not a matrix"))
  @test occursin("cone", err.value.msg)
  @test occursin("Normaliz cone input values", err.value.msg)

  err = @test_throws ArgumentError Normaliz._normaliz_input(Dict(:cone => ["x" ;;]))
  @test occursin("NmzRational", err.value.msg)

  mismatched_keys = CxxWrap.StdLib.StdVector{CxxWrap.StdLib.StdString}(["cone", "grading"])
  err = @test_throws ErrorException Normaliz._LongLongCone(mismatched_keys, input_matrices[1:1])
  @test err.value.msg == "Normaliz cone input keys and matrices must have the same length"
end

@testset "Second LongLongCone test" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1//2 2 ; 3 5])
  gg = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 1])
  yy = Normaliz.LongLongCone( Dict( :cone => xx, :grading => gg ) )
  @test yy isa Normaliz.Cone
  Normaliz.get_rational_cone_property(yy, "Multiplicity")
  Normaliz.get_boolean_cone_property(yy, "IsIntegrallyClosed")
  Normaliz.get_vector_cone_property( yy, "Grading" )
  Normaliz.get_matrix_cone_property( yy, "Deg1Elements" )
  Normaliz.get_matrix_cone_property( yy, "HilbertBasis" )
  Normaliz.get_matrix_cone_property( yy, "ModuleGeneratorsOverOriginalMonoid" )
  Normaliz.get_matrix_cone_property( yy, "MaximalSubspace" )
#  Normaliz.get_matrix_cone_property( yy, "MarkovBasis" )
  Normaliz.get_vector_cone_property( yy, "WitnessNotIntegrallyClosed" )
  Normaliz.get_integer_cone_property( yy, "TriangulationDetSum" )
  Normaliz.get_gmp_integer_cone_property( yy, "ExternalIndex" )
  Normaliz.get_float_cone_property( yy, "EuclideanVolume" )
  Normaliz.get_machine_integer_cone_property( yy, "EmbeddingDim" )
  Normaliz.get_boolean_cone_property(yy, "IsDeg1HilbertBasis")
end

@testset "basic IntCone test" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1//2 2 ; 3 5])
  gg = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 1])
  yy = Normaliz.LongLongCone( Dict( :cone => xx, :grading => gg ) )
  Normaliz.get_rational_cone_property(yy, "Multiplicity")
  Normaliz.get_boolean_cone_property(yy, "IsIntegrallyClosed")
  Normaliz.get_vector_cone_property( yy, "Grading" )
  Normaliz.get_matrix_cone_property( yy, "Deg1Elements" )
  Normaliz.get_matrix_cone_property( yy, "HilbertBasis" )
  Normaliz.get_matrix_cone_property( yy, "ModuleGeneratorsOverOriginalMonoid" )
  Normaliz.get_matrix_cone_property( yy, "MaximalSubspace" )
#  Normaliz.get_matrix_cone_property( yy, "MarkovBasis" )
  Normaliz.get_vector_cone_property( yy, "WitnessNotIntegrallyClosed" )
  Normaliz.get_integer_cone_property( yy, "TriangulationDetSum" )
  Normaliz.get_gmp_integer_cone_property( yy, "ExternalIndex" )
  Normaliz.get_float_cone_property( yy, "EuclideanVolume" )
  Normaliz.get_machine_integer_cone_property( yy, "EmbeddingDim" )
  Normaliz.get_boolean_cone_property(yy, "IsDeg1HilbertBasis")
end

@testset "basic GMPCone test" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])
  yy = Normaliz.GMPCone( Dict( :cone => xx ) )
  Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
  Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
end

@testset "cone property queries" begin
  known_properties = Normaliz.known_cone_properties()
  @test known_properties isa Vector{String}
  @test "ExtremeRays" in known_properties
  @test "Multiplicity" in known_properties
  @test "IsPointed" in known_properties
  @test !("DefaultMode" in known_properties)

  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])
  yy = Normaliz.GMPCone( Dict( :cone => xx ) )

  @test !Normaliz.is_computed(yy, :ExtremeRays)
  Normaliz.get_matrix_cone_property(yy, :ExtremeRays)
  computed_properties = Normaliz.computed_cone_properties(yy)
  @test computed_properties isa Vector{String}
  @test "ExtremeRays" in computed_properties
  @test Normaliz.is_computed(yy, "ExtremeRays")
  @test Normaliz.is_computed(yy, :ExtremeRays)
end

@testset "cone properties accept symbols" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1//2 2 ; 3 5])
  gg = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 1])
  yy = Normaliz.LongLongCone( Dict( :cone => xx, :grading => gg ) )

  @test Normaliz.get_boolean_cone_property(yy, :IsPointed) ==
        Normaliz.get_boolean_cone_property(yy, "IsPointed")
  @test Normaliz.get_integer_cone_property(yy, :TriangulationDetSum) ==
        Normaliz.get_integer_cone_property(yy, "TriangulationDetSum")
  @test string(Normaliz.get_gmp_integer_cone_property(yy, :ExternalIndex)) ==
        string(Normaliz.get_gmp_integer_cone_property(yy, "ExternalIndex"))
  @test string(Normaliz.get_rational_cone_property(yy, :Multiplicity)) ==
        string(Normaliz.get_rational_cone_property(yy, "Multiplicity"))
  @test Normaliz.get_float_cone_property(yy, :EuclideanVolume) ==
        Normaliz.get_float_cone_property(yy, "EuclideanVolume")
  @test Normaliz.get_machine_integer_cone_property(yy, :EmbeddingDim) ==
        Normaliz.get_machine_integer_cone_property(yy, "EmbeddingDim")

  grading_from_symbol = Normaliz.get_vector_cone_property(yy, :Grading)
  grading_from_string = Normaliz.get_vector_cone_property(yy, "Grading")
  @test typeof(grading_from_symbol) == typeof(grading_from_string)

  matrix_from_symbol = Normaliz.get_matrix_cone_property(yy, :HilbertBasis)
  matrix_from_string = Normaliz.get_matrix_cone_property(yy, "HilbertBasis")
  @test size(matrix_from_symbol) == size(matrix_from_string)
  @test string(matrix_from_symbol[1, 1]) == string(matrix_from_string[1, 1])
end

@testset "generic cone property getter" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1//2 2 ; 3 5])
  gg = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 1])
  yy = Normaliz.LongLongCone( Dict( :cone => xx, :grading => gg ) )

  matrix_from_generic = Normaliz.cone_property(yy, :HilbertBasis)
  matrix_from_typed = Normaliz.get_matrix_cone_property(yy, "HilbertBasis")
  @test size(matrix_from_generic) == size(matrix_from_typed)
  @test string(matrix_from_generic[1, 1]) == string(matrix_from_typed[1, 1])

  @test typeof(Normaliz.cone_property(yy, :Grading)) ==
        typeof(Normaliz.get_vector_cone_property(yy, "Grading"))
  @test Normaliz.cone_property(yy, :TriangulationDetSum) ==
        Normaliz.get_integer_cone_property(yy, "TriangulationDetSum")
  @test string(Normaliz.cone_property(yy, :ExternalIndex)) ==
        string(Normaliz.get_gmp_integer_cone_property(yy, "ExternalIndex"))
  @test string(Normaliz.cone_property(yy, :Multiplicity)) ==
        string(Normaliz.get_rational_cone_property(yy, "Multiplicity"))
  @test Normaliz.cone_property(yy, :EuclideanVolume) ==
        Normaliz.get_float_cone_property(yy, "EuclideanVolume")
  @test Normaliz.cone_property(yy, "EmbeddingDim") ==
        Normaliz.get_machine_integer_cone_property(yy, "EmbeddingDim")
  @test Normaliz.cone_property(yy, :IsPointed) ==
        Normaliz.get_boolean_cone_property(yy, "IsPointed")

  err = @test_throws ArgumentError Normaliz.cone_property(yy, :Triangulation)
  @test occursin("Triangulation", err.value.msg)
  @test occursin("Complex", err.value.msg)
end

# TODO: reactivate these tests once Renf support is back
#@testset "basic renf test" begin
#  r = Normaliz.RenfClass("a4-5a2+5", "a", "1.9021+/-0.01")
#  xx = Normaliz.NmzMatrix{Normaliz.Renf}(r,[1 2 ; 3 5])
#  yy = Normaliz.RenfCone( Dict( :cone => xx ) )
#  Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
#  Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
#end
