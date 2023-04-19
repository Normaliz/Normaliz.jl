using Test
using Normaliz

@testset "basic NmzMatrix tests" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])

  xx = Normaliz.NmzMatrix{Normaliz.NmzInteger}([1 2 ; 3 5])

  xx = Normaliz.NmzMatrix{Int}([1 2 ; 3 5])
end

@testset "basic LongCone test" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 2 ; 3 5])
  yy = Normaliz.LongCone( Dict( :cone => xx ) )
  Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
  Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
end

@testset "Second LongCone test" begin
  xx = Normaliz.NmzMatrix{Normaliz.NmzRational}([1//2 2 ; 3 5])
  gg = Normaliz.NmzMatrix{Normaliz.NmzRational}([1 1])
  yy = Normaliz.LongCone( Dict( :cone => xx, :grading => gg ) )
  Normaliz.get_rational_cone_property(yy, "Multiplicity")
  Normaliz.get_boolean_cone_property(yy, "IsIntegrallyClosed")
  Normaliz.get_vector_cone_property( yy, "Grading" )
  Normaliz.get_matrix_cone_property( yy, "Deg1Elements" )
  Normaliz.get_matrix_cone_property( yy, "HilbertBasis" )
  Normaliz.get_matrix_cone_property( yy, "ModuleGeneratorsOverOriginalMonoid" )
  Normaliz.get_matrix_cone_property( yy, "MaximalSubspace" )
  Normaliz.get_matrix_cone_property( yy, "MarkovBasis" )
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
  yy = Normaliz.LongCone( Dict( :cone => xx, :grading => gg ) )
  Normaliz.get_rational_cone_property(yy, "Multiplicity")
  Normaliz.get_boolean_cone_property(yy, "IsIntegrallyClosed")
  Normaliz.get_vector_cone_property( yy, "Grading" )
  Normaliz.get_matrix_cone_property( yy, "Deg1Elements" )
  Normaliz.get_matrix_cone_property( yy, "HilbertBasis" )
  Normaliz.get_matrix_cone_property( yy, "ModuleGeneratorsOverOriginalMonoid" )
  Normaliz.get_matrix_cone_property( yy, "MaximalSubspace" )
  Normaliz.get_matrix_cone_property( yy, "MarkovBasis" )
  Normaliz.get_vector_cone_property( yy, "WitnessNotIntegrallyClosed" )
  Normaliz.get_integer_cone_property( yy, "TriangulationDetSum" )
  Normaliz.get_gmp_integer_cone_property( yy, "ExternalIndex" )
  Normaliz.get_float_cone_property( yy, "EuclideanVolume" )
  Normaliz.get_machine_integer_cone_property( yy, "EmbeddingDim" )
  Normaliz.get_boolean_cone_property(yy, "IsDeg1HilbertBasis")
end

# TODO: reactivate these tests once Renf support is back
#@testset "basic renf test" begin
#  r = Normaliz.RenfClass("a4-5a2+5", "a", "1.9021+/-0.01")
#  xx = Normaliz.NmzMatrix{Normaliz.Renf}(r,[1 2 ; 3 5])
#  yy = Normaliz.RenfCone( Dict( :cone => xx ) )
#  Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
#  Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
#end
