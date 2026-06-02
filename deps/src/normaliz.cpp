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


mpz_srcptr julia_bigint_data(jl_value_t* value)
{
    return reinterpret_cast<mpz_srcptr>(jl_data_ptr(value));
}

mpz_ptr julia_bigint_data_mutable(jl_value_t* value)
{
    return reinterpret_cast<mpz_ptr>(jl_data_ptr(value));
}

void require_julia_bigint(jl_value_t* value)
{
    jl_value_t* bigint_type = jl_get_global(jl_base_module, jl_symbol("BigInt"));
    if (jl_typeof(value) != bigint_type) {
        throw std::invalid_argument("expected a Julia BigInt");
    }
}

mpz_class nmzinteger_from_bigint(jl_value_t* value)
{
    require_julia_bigint(value);
    mpz_class result;
    mpz_set(result.get_mpz_t(), julia_bigint_data(value));
    return result;
}

void set_bigint_from_nmzinteger(jl_value_t* result, mpz_class& value)
{
    require_julia_bigint(result);
    mpz_set(julia_bigint_data_mutable(result), value.get_mpz_t());
}

std::vector<std::string> cone_property_names(const libnormaliz::ConeProperties& properties)
{
    std::vector<std::string> names;
    for (int i = 0; i < libnormaliz::ConeProperty::EnumSize; ++i) {
        auto property = static_cast<libnormaliz::ConeProperty::Enum>(i);
        if (properties.test(property) &&
            libnormaliz::output_type(property) != libnormaliz::OutputType::Void) {
            names.push_back(libnormaliz::toString(property));
        }
    }
    return names;
}

std::string cone_property_output_type(const std::string& name)
{
    switch (libnormaliz::output_type(libnormaliz::toConeProperty(name))) {
    case libnormaliz::OutputType::Matrix:
        return "Matrix";
    case libnormaliz::OutputType::MatrixFloat:
        return "MatrixFloat";
    case libnormaliz::OutputType::Vector:
        return "Vector";
    case libnormaliz::OutputType::Integer:
        return "Integer";
    case libnormaliz::OutputType::GMPInteger:
        return "GMPInteger";
    case libnormaliz::OutputType::Rational:
        return "Rational";
    case libnormaliz::OutputType::FieldElem:
        return "FieldElem";
    case libnormaliz::OutputType::Float:
        return "Float";
    case libnormaliz::OutputType::MachineInteger:
        return "MachineInteger";
    case libnormaliz::OutputType::Bool:
        return "Bool";
    case libnormaliz::OutputType::Complex:
        return "Complex";
    case libnormaliz::OutputType::Void:
        return "Void";
    }
    return "Unknown";
}

template <typename T>
std::map<libnormaliz::Type::InputType, Matrix<T>>
to_normaliz_matrix(std::vector<std::string> input_keys,
                   jlcxx::ArrayRef<Matrix<T>> input_matrices)
{
    size_t len = input_keys.size();
    if (len != input_matrices.size()) {
        throw std::runtime_error(
            "Normaliz cone input keys and matrices must have the same length");
    }
    std::map<libnormaliz::Type::InputType, Matrix<T>> input_map;

    for (size_t i = 0; i < len; i++) {
        input_map[libnormaliz::to_type(input_keys[i])] =
            Matrix<T>(input_matrices[i]);
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
        .constructor<std::string>()
        .method("to_string", [](mpz_class& i) { return i.get_str(); });

    normaliz.method("_NmzInteger_from_bigint", nmzinteger_from_bigint);
    normaliz.method("_set_bigint!", set_bigint_from_nmzinteger);

    normaliz.add_type<mpq_class>("NmzRational")
        .constructor<long, long>()
        .constructor<mpz_class, mpz_class>()
        .constructor<std::string>()
        .method("to_string", [](mpq_class& i) { return i.get_str(); })
        .method("_numerator", [](mpq_class& i) { return i.get_num(); })
        .method("_denominator", [](mpq_class& i) { return i.get_den(); });

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
                wrapped.method("_computed_cone_properties", [](WrappedT& C) {
                    return cone_property_names(C.getIsComputed());
                });
                wrapped.method("_is_computed", [](WrappedT& C,
                                                  const std::string& s) {
                    return C.isComputed(libnormaliz::toConeProperty(s));
                });
            });

    normaliz.method("_known_cone_properties", []() {
        return cone_property_names(libnormaliz::all_goals());
    });
    normaliz.method("_cone_property_output_type", cone_property_output_type);

    normaliz.method("_GMPCone", [](std::vector<std::string> input_keys,
                                   jlcxx::ArrayRef<Matrix<mpq_class>>
                                       input_matrices) {
        return Cone<mpz_class>(
            to_normaliz_matrix<mpq_class>(input_keys, input_matrices));
    });
    normaliz.method("_LongLongCone", [](std::vector<std::string> input_keys,
                                        jlcxx::ArrayRef<Matrix<mpq_class>>
                                            input_matrices) {
        return Cone<long long>(
            to_normaliz_matrix<mpq_class>(input_keys, input_matrices));
    });
#ifdef ENFNORMALIZ
    normaliz.method("_RenfCone", [](std::vector<std::string> input_keys,
                                    jlcxx::ArrayRef<Matrix<renf_elem_class>>
                                        input_matrices) {
        return Cone<renf_elem_class>(
            to_normaliz_matrix<renf_elem_class>(input_keys, input_matrices));
    });
#endif
}
