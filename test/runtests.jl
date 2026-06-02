using Test
using Normaliz
using CxxWrap

@testset "basic NmzMatrix tests" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])

  xx = Normaliz.NmzMatrix{Normaliz.NmzInteger}([1 2 ; 3 5])

  xx = Normaliz.NmzMatrix{Int}([1 2 ; 3 5])
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

# TODO: reactivate these tests once Renf support is back
#@testset "basic renf test" begin
#  r = Normaliz.RenfClass("a4-5a2+5", "a", "1.9021+/-0.01")
#  xx = Normaliz.NmzMatrix{Normaliz.Renf}(r,[1 2 ; 3 5])
#  yy = Normaliz.RenfCone( Dict( :cone => xx ) )
#  Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
#  Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
#end
