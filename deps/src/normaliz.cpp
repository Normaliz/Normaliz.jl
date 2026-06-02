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
    jl_value_t* keys_iter = nullptr;
    jl_value_t* vals_iter = nullptr;
    jl_value_t* keys_array_value = nullptr;
    jl_value_t* vals_array_value = nullptr;
    jl_value_t* idx = nullptr;
    jl_value_t* key_value = nullptr;
    jl_value_t* mat_value = nullptr;
    JL_GC_PUSH7(&keys_iter, &vals_iter, &keys_array_value, &vals_array_value,
                &idx, &key_value, &mat_value);

    keys_iter = jl_call1(jl_get_function(jl_base_module, "keys"), input_dict);
    if (jl_exception_occurred()) {
        JL_GC_POP();
        return std::map<libnormaliz::Type::InputType, Matrix<T>>();
    }

    vals_iter = jl_call1(jl_get_function(jl_base_module, "values"), input_dict);
    if (jl_exception_occurred()) {
        JL_GC_POP();
        return std::map<libnormaliz::Type::InputType, Matrix<T>>();
    }

    keys_array_value =
        jl_call1(jl_get_function(jl_base_module, "collect"), keys_iter);
    if (jl_exception_occurred()) {
        JL_GC_POP();
        return std::map<libnormaliz::Type::InputType, Matrix<T>>();
    }
    vals_array_value =
        jl_call1(jl_get_function(jl_base_module, "collect"), vals_iter);
    if (jl_exception_occurred()) {
        JL_GC_POP();
        return std::map<libnormaliz::Type::InputType, Matrix<T>>();
    }
    if (!jl_is_array(keys_array_value) || !jl_is_array(vals_array_value)) {
        jl_value_t* actual_type =
            jl_typeof(jl_is_array(keys_array_value) ? vals_array_value
                                                    : keys_array_value);
        JL_GC_POP();
        jl_type_error("to_normaliz_matrix", jl_eval_string("Array"),
                      actual_type);
        return std::map<libnormaliz::Type::InputType, Matrix<T>>();
    }

    jl_array_t* keys = reinterpret_cast<jl_array_t*>(keys_array_value);
    jl_array_t* vals = reinterpret_cast<jl_array_t*>(vals_array_value);
    size_t                                       len = jl_array_len(keys);
    std::map<libnormaliz::Type::InputType, Matrix<T>> input_map;

    jl_function_t* getindex = jl_get_function(jl_base_module, "getindex");
    for (size_t i = 0; i < len; i++) {
        idx = jl_box_int64(static_cast<int64_t>(i + 1));
        key_value = jl_call2(getindex, keys_array_value, idx);
        if (jl_exception_occurred()) {
            JL_GC_POP();
            return std::map<libnormaliz::Type::InputType, Matrix<T>>();
        }
        mat_value = jl_call2(getindex, vals_array_value, idx);
        if (jl_exception_occurred()) {
            JL_GC_POP();
            return std::map<libnormaliz::Type::InputType, Matrix<T>>();
        }
        if (!jl_is_symbol(key_value)) {
            JL_GC_POP();
            jl_type_error("to_normaliz_matrix",
                          reinterpret_cast<jl_value_t*>(jl_symbol_type),
                          jl_typeof(key_value));
            return std::map<libnormaliz::Type::InputType, Matrix<T>>();
        }

        Matrix<T>* mat = jlcxx::unbox<Matrix<T>*>(mat_value);
        std::string key(
            jl_symbol_name(reinterpret_cast<jl_sym_t*>(key_value)));
        input_map[libnormaliz::to_type(key)] = Matrix<T>(*mat);
    }
    JL_GC_POP();
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

    normaliz.add_type<mpq_class>("NmzRational")
        .constructor<long, long>()
        .method("to_string", [](mpq_class& i) { return i.get_str(); });

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
                Matrix<long>,
                Matrix<long long>
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
                Cone<long long>
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

    normaliz.method("GMPCone", [](jl_value_t* input_dict) {
        return Cone<mpz_class>(to_normaliz_matrix<mpq_class>(input_dict));
    });
    normaliz.method("LongLongCone", [](jl_value_t* input_dict) {
        return Cone<long long>(to_normaliz_matrix<mpq_class>(input_dict));
    });
#ifdef ENFNORMALIZ
    normaliz.method("RenfCone", [](jl_value_t* input_dict) {
        return Cone<renf_elem_class>(to_normaliz_matrix<renf_elem_class>(input_dict));
    });
#endif
}
