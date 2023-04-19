// STL headers
#include <string>
#include <iostream>
#include <vector>

// CxxWrap headers
#include "jlcxx/jlcxx.hpp"
#include "jlcxx/stl.hpp"

// Normaliz headers
#include <libnormaliz/cone.h>
#include <libnormaliz/list_and_map_operations.h>
#include <libnormaliz/vector_operations.h>
#include <libnormaliz/matrix.h>

using libnormaliz::Cone;
using libnormaliz::Matrix;

#ifdef ENFNORMALIZ
using libnormaliz::renf_class;
using libnormaliz::renf_elem_class;
#endif

// template <typename T> using nmzvecmat = std::vector<std::vector<T>>;


template <typename T>
std::map<libnormaliz::Type::InputType, Matrix<T>>
to_normaliz_matrix(jl_value_t* input_dict)
{
    if (!jl_isa(input_dict, jl_eval_string("Dict"))) {
        jl_type_error("to_normaliz_matrix", jl_eval_string("Dict"),
                      jl_typeof(input_dict));
        return std::map<libnormaliz::Type::InputType, Matrix<T>>();
    }
    jl_array_t* keys =
        reinterpret_cast<jl_array_t*>(jl_get_field(input_dict, "keys"));
    jl_array_t* value =
        reinterpret_cast<jl_array_t*>(jl_get_field(input_dict, "vals"));
    size_t                                       len = jl_array_len(keys);
    std::map<libnormaliz::Type::InputType, Matrix<T>> input_map;
    for (size_t i = 0; i < len; i++) {
        if (!jl_array_isassigned(keys, i)) {
            continue;
        }
        // We assume the matrix has the right type
        Matrix<T>* mat = reinterpret_cast<Matrix<T>*>(
            *reinterpret_cast<void**>(jl_arrayref(value, i)));
        std::string key(jl_symbol_name(
            reinterpret_cast<jl_sym_t*>(jl_arrayref(keys, i))));
        input_map[libnormaliz::to_type(key)] = Matrix<T>(*mat);
    }
    return input_map;
}

#ifdef ENFNORMALIZ
std::string write_renf(renf_class& renf)
{
    std::string output = "Real embedded number field: ";
    double a_double = static_cast<double>(renf.gen());
    char * res, *res1;
    res = fmpq_poly_get_str_pretty(renf.get_renf()->nf->pol, "a");
    res1 = arb_get_str(renf.get_renf()->emb, 64, 0);
    output = output + "min_poly (" + res + ") embedding " + res1;
    flint_free(res);
    flint_free(res1);
    return output;
}
#endif

JLCXX_MODULE define_module_normaliz(jlcxx::Module& normaliz)
{
    normaliz.add_type<mpz_class>("NmzInteger")
        .constructor<long>()
        .method("to_string", [](mpz_class& i) { return i.get_str(); });

    jlcxx::stl::apply_stl<mpz_class>(normaliz);

    normaliz.add_type<mpq_class>("NmzRational")
        .constructor<long, long>()
        .method("to_string", [](mpq_class& i) { return i.get_str(); });

    jlcxx::stl::apply_stl<mpq_class>(normaliz);

#ifdef ENFNORMALIZ
    normaliz.add_type<renf_class>("RenfClass")
#if 0
        .method("renf_class_construct",[](const std::string & minpoly, const std::string & gen, const std::string &emb, int prec) {
            // TODO: make the following work; it returns a
            // boost::intrusive_ptr, so I am not 100% sure how to deal with it
            return renf_class::make(minpoly, gen, emb, prec);
        })
#endif
        .method("to_string", [](renf_class& f) { return write_renf(f); });

    auto Renf = normaliz.add_type<renf_elem_class>("Renf");
    Renf.method("to_string", [](renf_elem_class& e) { return e.to_string(); })
        .method("renf_construct",[](renf_class& nf, const std::vector<mpq_class> & v){
            return renf_elem_class(nf,v);
        })
        .method("renf_construct",[](renf_class& nf, const std::string &s){
            return renf_elem_class(nf, s);
        })
#if 0
        .method("renf_construct_fmpq_poly", [](renf_class& nf, void* poly ){
            // TODO: make this code work again... *if we need it
            // TODO: why are we passing the polynomial as a `void *`?
            renf_elem_class p(nf);
            p = *reinterpret_cast<fmpq_poly_t*>(poly);
            return p;
        })
#endif
        ;
#endif

    normaliz
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "NmzMatrix", jlcxx::julia_type("AbstractMatrix", "Base"))
        .apply<
                Matrix<mpq_class>,
                Matrix<mpz_class>,
#ifdef ENFNORMALIZ
                Matrix<renf_elem_class>,
#endif
                Matrix<int64_t>
            >([](auto wrapped) {
            typedef typename decltype(wrapped)::type            WrappedT;
            typedef typename decltype(wrapped)::type::elem_type elemType;

            wrapped.template constructor<int64_t, int64_t>();
            wrapped.method("_getindex",
                           [](WrappedT& mat, int64_t i, int64_t j) {
                               return mat[i - 1][j - 1];
                           });
            wrapped.method("_setindex!",
                           [](WrappedT& M, elemType r, int64_t i, int64_t j) {
                               M[i - 1][j - 1] = r;
                           });
            wrapped.method("nrows",
                           [](WrappedT& mat) { return mat.nr_of_rows(); });
            wrapped.method("ncols",
                           [](WrappedT& mat) { return mat.nr_of_columns(); });
        });

#if 0
    // TODO: should we enable the vector<vector<T>> interface? for now
    // I think it would be simpler if we just did all via Matrix<T>, but
    // perhaps there are things that require vector<vector<T>> ?
    normaliz.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("NmzVecMat")
        .apply<
                nmzvecmat<mpq_class>,
                nmzvecmat<mpz_class>,
#ifdef ENFNORMALIZ
                nmzvecmat<renf_elem_class>,
#endif
                nmzvecmat<int64_t>
            >(
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
                wrapped.method("nrows",
                               [](WrappedT& mat) { return mat.size(); });
                wrapped.method("ncols", [](WrappedT& mat) {
                    return mat.size() > 0 ? mat[0].size() : 0;
                });
            });
#endif

    normaliz.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("Cone")
        .apply<
                Cone<mpz_class>,
#ifdef ENFNORMALIZ
                Cone<renf_elem_class>,
#endif
                Cone<int64_t>
            >(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type WrappedT;
                wrapped.method("get_matrix_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getMatrixConePropertyMatrix(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_vector_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getVectorConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_integer_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getIntegerConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_gmp_integer_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getGMPIntegerConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_rational_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getRationalConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_float_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getFloatConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_machine_integer_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getMachineIntegerConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
                wrapped.method("get_boolean_cone_property",
                               [](WrappedT& C, const std::string &s) {
                                   return C.getBooleanConeProperty(
                                       libnormaliz::toConeProperty(s));
                               });
            });

    normaliz.method("IntCone", [](jl_value_t* input_dict) {
        return Cone<mpz_class>(to_normaliz_matrix<mpq_class>(input_dict));
    });
    normaliz.method("LongCone", [](jl_value_t* input_dict) {
        return Cone<int64_t>(to_normaliz_matrix<mpq_class>(input_dict));
    });
#ifdef ENFNORMALIZ
    normaliz.method("RenfCone", [](jl_value_t* input_dict) {
        return Cone<renf_elem_class>(to_normaliz_matrix<renf_elem_class>(input_dict));
    });
#endif
}
