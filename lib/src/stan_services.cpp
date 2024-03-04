#include <erl_nif.h>
#include <stan/callbacks/interrupt.hpp>
#include <stan/callbacks/stream_logger.hpp>
#include <stan/callbacks/writer.hpp>
#include <stan/io/array_var_context.hpp>
#include <stan/io/var_context.hpp>
#include <stan/model/model_base.hpp>
#include <stan/services/sample/fixed_param.hpp>
#include <stan/services/sample/hmc_nuts_diag_e_adapt.hpp>

int add(int a, int b)
{
    return a + b;
}

ERL_NIF_TERM add_nif(ErlNifEnv *env, int argc,
                     const ERL_NIF_TERM argv[])
{
    int a = 0;
    int b = 0;

    if (!enif_get_int(env, argv[0], &a))
    {
        return enif_make_badarg(env);
    }
    if (!enif_get_int(env, argv[1], &b))
    {
        return enif_make_badarg(env);
    }

    int result = add(a, b);
    return enif_make_int(env, result);
}

// stan::model::model_base &new_model(stan::io::var_context &tream))unsigned int seed, std::ostream *msg_streamge   int model_id = next_model_id++;
//     models[model_id] = &model;

ERL_NIF_TERM new_model_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 3)
    {
        return enif_make_badarg(env);
    }
    // stan::io::var_context vc;
    // stan::model::model_base *model = new stan::model::model_base(vc);

    unsigned int seed;
    seed = 42;

    // if (!enif_get_uint(env, argv[1], &seed)) {
    //   return enif_make_badarg(env);
    // }

    return enif_make_int(env, seed);
}

ERL_NIF_TERM new_array_var_context_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1)
    {
        return enif_make_badarg(env);
    }
    unsigned int len;
    if (!enif_get_list_length(env, argv[0], &len))
    {
        return enif_make_badarg(env);
    }
    return enif_make_int(env, len);
}

ErlNifFunc nif_funcs[] =
    {
        {"add", 2, add_nif},
        {"new_model", 3, new_model_nif},
        {"new_array_var_context", 6, new_array_var_context_nif}};

ERL_NIF_INIT(Elixir.ExStan, nif_funcs, NULL, NULL, NULL, NULL);
