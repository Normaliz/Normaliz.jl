#include <string>
using std::string;

#include <iostream>
using std::cerr;
using std::endl;

#include "jlcxx/jlcxx.hpp"

#include <libnormaliz/cone.h>
#include <libnormaliz/map_operations.h>
#include <libnormaliz/vector_operations.h>
using libnormaliz::Cone;
// using libnormaliz::ConeProperty;
using libnormaliz::ConeProperties;
using libnormaliz::Sublattice_Representation;
using libnormaliz::Type::InputType;
#include <libnormaliz/matrix.h>
using libnormaliz::Matrix;

#include <vector>
using std::map;
using std::pair;
using std::vector;

template <typename T>
using libnormaliz_input_map =
    std::map<libnormaliz::Type::InputType, vector<vector<T>>>;

template <typename T> using vectorallocator = std::allocator<vector<T>>;

template <typename T>
using vecmatallocator = std::allocator<vector<vector<T>>>;

template <typename T> using nmzvecmat = vector<vector<T>>;


template <typename T>
map<libnormaliz::Type::InputType, Matrix<T>>
to_normaliz_matrix(jl_value_t* input_dict)
{
    if (!jl_isa(input_dict, jl_eval_string("Dict"))) {
        jl_type_error("to_normaliz_matrix", jl_eval_string("Dict"),
                      jl_typeof(input_dict));
        return map<libnormaliz::Type::InputType, Matrix<T>>();
    }
    jl_array_t* keys =
        reinterpret_cast<jl_array_t*>(jl_get_field(input_dict, "keys"));
    jl_array_t* value =
        reinterpret_cast<jl_array_t*>(jl_get_field(input_dict, "vals"));
    size_t                                       len = jl_array_len(keys);
    map<libnormaliz::Type::InputType, Matrix<T>> input_map;
    for (size_t i = 0; i < len; i++) {
        if (!jl_array_isassigned(keys, i)) {
            continue;
        }
        // We assume the matrix has the right type
        Matrix<T>* mat = reinterpret_cast<Matrix<T>*>(
            *reinterpret_cast<void**>(jl_arrayref(value, i)));
        string key = string(jl_symbol_name(
            reinterpret_cast<jl_sym_t*>(jl_arrayref(keys, i))));
        input_map[libnormaliz::to_type(key)] = Matrix<T>(*mat);
    }
    return input_map;
}

string write_renf(renf_class& renf)
{

    string output = "Real embedded number field: ";
    double a_double = renf.gen().get_d();
    char * res, *res1;
    res = fmpq_poly_get_str_pretty(renf.get_renf()->nf->pol, "a");
    res1 = arb_get_str(renf.get_renf()->emb, 64, 0);
    output = output + "min_poly (" + res + ") embedding " + res1;
    flint_free(res);
    flint_free(res1);
    return output;
}


JLCXX_MODULE define_module_normaliz(jlcxx::Module& normaliz)
{

    normaliz.add_type<mpq_class>("NmzRational")
        .constructor<int32_t, int32_t>()
        .constructor<int64_t, int64_t>()
        .method("to_string", [](mpq_class& i) { return i.get_str(); });
    normaliz.add_type<mpz_class>("NmzInteger")
        .constructor<int32_t>()
        .constructor<int64_t>()
        .method("to_string", [](mpz_class& i) { return i.get_str(); });
    normaliz.add_type<renf_elem_class>("Renf")
        .constructor<renf_class>()
        .method("to_string", [](renf_elem_class& e) { return e.get_str(); })
        .method("renf_construct",[](renf_class& nf, vector<mpq_class> v){
            return renf_elem_class(nf,v);
        })
        .method("renf_construct",[](renf_class& nf, string s){
            return renf_elem_class(nf, s);
        })
        .method("renf_construct_fmpq_poly", [](renf_class& nf, void* poly ){
            renf_elem_class p(nf);
            p = *reinterpret_cast<fmpq_poly_t*>(poly);
            return p;
        });

    normaliz.add_type<renf_class>("RenfClass")
        .constructor<string, string, string>()
        .method("to_string", [](renf_class& f) { return write_renf(f); });

    normaliz.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("StdAllocator")
        .apply<std::allocator<mpz_class>, std::allocator<mpq_class>,
               std::allocator<long long>, std::allocator<renf_elem_class>>(
            [](auto wrapped) {});

    normaliz
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "NmzVector", jlcxx::julia_type("AbstractVector", "Base"))
        .apply<vector<mpq_class>, vector<mpz_class>, vector<long long>,
               vector<renf_elem_class>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef typename decltype(wrapped)::type::value_type elemType;
            wrapped.template constructor<int64_t>();
            wrapped.template constructor<int32_t>();
            wrapped.method("_getindex",
                           [](WrappedT& v, int64_t i) { return v[i - 1]; });
            wrapped.method("_setindex!", [](WrappedT& v, elemType r,
                                            int64_t i) { v[i - 1] = r; });
            wrapped.method("length", [](WrappedT& v) { return v.size(); });
        });

    normaliz.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("StdAllocator2")
        .apply<vectorallocator<mpz_class>, vectorallocator<mpq_class>,
               vectorallocator<long long>, vectorallocator<renf_elem_class>>(
            [](auto wrapped) {});

    normaliz
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "NmzMatrix", jlcxx::julia_type("AbstractMatrix", "Base"))
        .apply<Matrix<mpq_class>, Matrix<mpz_class>, Matrix<renf_elem_class>,
               Matrix<long long>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type            WrappedT;
            typedef typename decltype(wrapped)::type::elem_type elemType;

            wrapped.template constructor<int64_t, int64_t>();
            wrapped.template constructor<int32_t, int32_t>();
            wrapped.method("_getindex",
                           [](WrappedT& mat, int64_t i, int64_t j) {
                               return mat[i - 1][j - 1];
                           });
            wrapped.method("_setindex!",
                           [](WrappedT& M, elemType r, int64_t i, int64_t j) {
                               M[i - 1][j - 1] = r;
                           });
            wrapped.method("rows",
                           [](WrappedT& mat) { return mat.nr_of_rows(); });
            wrapped.method("cols",
                           [](WrappedT& mat) { return mat.nr_of_columns(); });
        });

    normaliz.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("NmzVecMat")
        .apply<nmzvecmat<mpq_class>, nmzvecmat<mpz_class>,
               nmzvecmat<renf_elem_class>, nmzvecmat<long long>>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type WrappedT;
                typedef typename decltype(
                    wrapped)::type::value_type::value_type elemType;
                wrapped.method("_getindex",
                               [](WrappedT& mat, int64_t i, int64_t j) {
                                   return mat[i - 1][j - 1];
                               });
                wrapped.method("_setindex!",
                               [](WrappedT& M, elemType r, int64_t i,
                                  int64_t j) { M[i - 1][j - 1] = r; });
                wrapped.method("rows",
                               [](WrappedT& mat) { return mat.size(); });
                wrapped.method("cols", [](WrappedT& mat) {
                    return mat.size() > 0 ? mat[0].size() : 0;
                });
            });

    normaliz.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("Cone")
        .apply<Cone<mpz_class>, Cone<renf_elem_class>, Cone<long long>>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type WrappedT;
                wrapped.method("get_matrix_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getMatrixConePropertyMatrix(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_vector_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getVectorConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_integer_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getIntegerConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_gmp_integer_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getGMPIntegerConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_rational_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getRationalConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_float_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getFloatConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_machine_integer_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getMachineIntegerConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_boolean_cone_property",
                               [](WrappedT& C, string s) {
                                   return C.getBooleanConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
            });

    normaliz.method("IntCone", [](jl_value_t* input_dict) {
        return Cone<mpz_class>(to_normaliz_matrix<mpq_class>(input_dict));
    });
    normaliz.method("LongCone", [](jl_value_t* input_dict) {
        return Cone<long long>(to_normaliz_matrix<mpq_class>(input_dict));
    });
    normaliz.method("RenfCone", [](jl_value_t* input_dict) {
        return Cone<renf_elem_class>(to_normaliz_matrix<renf_elem_class>(input_dict));
    });
}
