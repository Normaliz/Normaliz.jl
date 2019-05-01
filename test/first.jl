using Normaliz
r = Normaliz.RenfClass("a4-5a2+5", "a", "1.9021+/-0.01")
xx = Normaliz.NmzMatrix{Normaliz.Renf}(r,[1 2 ; 3 5])
yy = Normaliz.RenfCone( Dict( :cone => xx ) )
Normaliz.get_matrix_cone_property( yy, "ExtremeRays" )
Normaliz.get_matrix_cone_property( yy, "SupportHyperplanes" )
