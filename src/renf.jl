import Nemo: fmpq_poly

Base.show(io::IO,x::Renf) = print(io,to_string(x))
Base.show(io::IO,x::RenfClass) = print(io,to_string(x))

function NmzMatrix{Renf}(f::RenfClass,x::Matrix{S}) where S
   s = size(x)
   mat = NmzMatrix{Renf}(s[1],s[2])
   for i in 1:s[1], j in 1:s[2]
       mat[i,j] = Renf(f,x[i,j])
   end
   return mat
end

#function Renf(f::RenfClass,v::NmzVector{NmzRational})
#   # TODO: make this work (again) without NmzVector
#   return renf_construct(f,v)
#end

#function Renf(f::RenfClass,v::Int64)
#   # TODO: make this work (again) without NmzVector
#   return renf_construct(f, NmzVector{NmzRational}([v]))
#end

function Renf(f::RenfClass,p::fmpq_poly)
   # TODO: make this work (again)
   return renf_construct_fmpq_poly(f,reinterpret(Ptr{Cvoid},pointer_from_objref(p)))
end

function RenfClass(minpoly::String, gen::String, emb::String, prec::Int = 64)
  # TODO: make this work
  return renf_class_construct(minpoly, gen, emb, prec)
end

Cone{Renf}(args...)       = RenfCone(args...)
