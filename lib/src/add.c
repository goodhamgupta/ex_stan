#include <erl_nif.h>

int add (int a, int b)
{
    return a + b;
}

ERL_NIF_TERM add_nif(ErlNifEnv* env, int argc, 
    const ERL_NIF_TERM argv[])
{
    int a = 0;
    int b = 0;
    
    if (!enif_get_int(env, argv[0], &a)) {
        return enif_make_badarg(env);
    }
    if (!enif_get_int(env, argv[1], &b)) {
        return enif_make_badarg(env);
    }
    
    int result = add(a, b);
    return enif_make_int(env, result);
}

ErlNifFunc nif_funcs[] = 
{
    {"add", 2, add_nif},
};

ERL_NIF_INIT(Elixir.ExStan, nif_funcs, NULL, NULL, NULL, NULL);
