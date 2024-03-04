# Makefile for ex_stan
#
# This Makefile generates code and builds the libraries used by ex_stan
#
# Code generation rules appear in this Makefile. One ex_stan-specific library
# is built using rules defined in this Makefile. Other libraries used by all
# Stan interfaces are built using rules defined in `Makefile.libraries`.  This
# Makefile calls `make` to run `Makefile.libraries`. Note that some rules in
# this Makefile copy libraries built by the other Makefile into their
# ex_stan-specific directories.

RAPIDJSON_VERSION := 1.1.0
STAN_VERSION := 2.33.0
STANC_VERSION := 2.33.1
MATH_VERSION := 4.7.0
# NOTE: boost, eigen, sundials, and tbb versions must match those found in Stan Math
BOOST_VERSION := 1.78.0
EIGEN_VERSION := 3.4.0
SUNDIALS_VERSION := 6.1.1
TBB_VERSION := 2020.3
RAPIDJSON_ARCHIVE := _build/archives/rapidjson-$(RAPIDJSON_VERSION).tar.gz

STAN_ARCHIVE := _build/archives/stan-v$(STAN_VERSION).tar.gz
MATH_ARCHIVE := _build/archives/math-v$(MATH_VERSION).tar.gz
HTTP_ARCHIVES := $(STAN_ARCHIVE) $(MATH_ARCHIVE) $(RAPIDJSON_ARCHIVE)
HTTP_ARCHIVES_EXPANDED := _build/stan-$(STAN_VERSION) _build/math-$(MATH_VERSION) _build/rapidjson-$(RAPIDJSON_VERSION)

SUNDIALS_LIBRARIES := lib/src/lib/libsundials_nvecserial.a lib/src/lib/libsundials_cvodes.a lib/src/lib/libsundials_idas.a lib/src/lib/libsundials_kinsol.a
TBB_LIBRARIES := lib/src/lib/libtbb.so
ifeq ($(shell uname -s),Darwin)
  TBB_LIBRARIES += lib/src/lib/libtbbmalloc.so lib/src/lib/libtbbmalloc_proxy.so
endif
STAN_LIBRARIES := $(SUNDIALS_LIBRARIES) $(TBB_LIBRARIES)
LIBRARIES := $(STAN_LIBRARIES)
INCLUDES_STAN_MATH_LIBS := lib/src/include/boost lib/src/include/Eigen lib/src/include/sundials lib/src/include/tbb
INCLUDES_STAN := lib/src/include/stan lib/src/include/stan/math $(INCLUDES_STAN_MATH_LIBS)
INCLUDES := lib/src/include/rapidjson $(INCLUDES_STAN)
STANC := lib/src/stanc
# PRECOMPILED_OBJECTS = ex_stan/stan_services.o

default: $(LIBRARIES) $(INCLUDES) $(STANC) # $(PRECOMPILED_OBJECTS)


###############################################################################
# Download archives via HTTP and extract them
###############################################################################
_build/archives:
	@mkdir -p _build/archives

$(RAPIDJSON_ARCHIVE): | _build/archives
	@echo downloading $@
	@curl --silent --location https://github.com/Tencent/rapidjson/archive/v$(RAPIDJSON_VERSION).tar.gz -o $@

$(STAN_ARCHIVE): | _build/archives
	@echo downloading $@
	@curl --silent --location https://github.com/stan-dev/stan/archive/v$(STAN_VERSION).tar.gz -o $@

$(MATH_ARCHIVE): | _build/archives
	@echo downloading $@
	@curl --silent --location https://github.com/stan-dev/math/archive/v$(MATH_VERSION).tar.gz -o $@

_build/rapidjson-$(RAPIDJSON_VERSION): $(RAPIDJSON_ARCHIVE)
_build/stan-$(STAN_VERSION): $(STAN_ARCHIVE)
_build/math-$(MATH_VERSION): $(MATH_ARCHIVE)

$(HTTP_ARCHIVES_EXPANDED):
	@echo extracting archive $<
	tar -C _build -zxf $<
	touch $@

###############################################################################
# Download and install stanc
###############################################################################
ifeq ($(shell uname -s),Darwin)
_build/stanc:
	curl --location https://github.com/stan-dev/stanc3/releases/download/v$(STANC_VERSION)/mac-stanc -o $@ --retry 5 --fail
else
_build/stanc:
	curl --location https://github.com/stan-dev/stanc3/releases/download/v$(STANC_VERSION)/linux-stanc -o $@ --retry 5 --fail
endif

$(STANC): _build/stanc
	rm -f $@ && cp -r $< $@ && chmod u+x $@

###############################################################################
# rapidjson
###############################################################################
lib/src/include/rapidjson: _build/rapidjson-$(RAPIDJSON_VERSION)/include/rapidjson | _build/rapidjson-$(RAPIDJSON_VERSION)
	@mkdir -p lib/src/include
	@rm -rf $@
	cp -r $< $@

_build/rapidjson-$(RAPIDJSON_VERSION)/include/rapidjson: | _build/rapidjson-$(RAPIDJSON_VERSION)

###############################################################################
# Make local copies of C++ source code used by Stan
###############################################################################

lib/src/include/stan: | _build/stan-$(STAN_VERSION)
	@mkdir -p lib/src/include
	@rm -rf $@
	cp -r _build/stan-$(STAN_VERSION)/src/stan $@

lib/src/include/stan/math: | _build/math-$(MATH_VERSION)
	@mkdir -p lib/src/include/stan
	@rm -rf $@ lib/src/include/stan/math.hpp lib/src/include/stan/math
	cp _build/math-$(MATH_VERSION)/stan/math.hpp lib/src/include/stan
	cp -r _build/math-$(MATH_VERSION)/stan/math lib/src/include/stan

lib/src/include/boost: | _build/math-$(MATH_VERSION)
	@mkdir -p lib/src/include
	@echo $@
	@rm -rf $@
	cp -r _build/math-$(MATH_VERSION)/lib/boost_$(BOOST_VERSION)/boost $@

EIGEN_INCLUDES := Eigen unsupported
lib/src/include/Eigen: | _build/math-$(MATH_VERSION)
	@mkdir -p lib/src/include
	@rm -rf $(addprefix lib/src/include/,$(EIGEN_INCLUDES))
	cp -r $(addprefix _build/math-$(MATH_VERSION)/lib/eigen_$(EIGEN_VERSION)/,$(EIGEN_INCLUDES)) lib/src/include

SUNDIALS_INCLUDES := cvodes idas kinsol nvector sundials sunlinsol sunmatrix sunmemory sunnonlinsol stan_sundials_printf_override.hpp sundials_debug.h
lib/src/include/sundials: | _build/math-$(MATH_VERSION)
	@mkdir -p lib/src/include
	@rm -rf $(addprefix lib/src/include/,$(SUNDIALS_INCLUDES))
	cp -r $(addprefix _build/math-$(MATH_VERSION)/lib/sundials_$(SUNDIALS_VERSION)/include/,$(SUNDIALS_INCLUDES)) lib/src/include

lib/src/include/tbb: | _build/math-$(MATH_VERSION)
	@mkdir -p lib/src/include
	@rm -rf tbb
	cp -r _build/math-$(MATH_VERSION)/lib/tbb_$(TBB_VERSION)/include/tbb lib/src/include

###############################################################################
# Make local copies of shared libraries built by Stan Math's Makefile rules
###############################################################################

lib/src/lib/%: _build/math-$(MATH_VERSION)/lib/sundials_$(SUNDIALS_VERSION)/lib/%
	mkdir -p lib/src/lib
	cp $< $@

# Stan Math builds a library with suffix .so.2 by default. Python prefers .so.
# Do not use symlinks since these will be ignored by Python wheel builders
# WISHLIST: Understand why Python needs both .so and .so.2.
ifeq ($(shell uname -s),Darwin)
lib/src/lib/libtbb.so: _build/math-$(MATH_VERSION)/lib/tbb/libtbb.dylib
	cp $< lib/src/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)

lib/src/lib/libtbb%.so: _build/math-$(MATH_VERSION)/lib/tbb/libtbb%.dylib
	cp $< lib/src/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)
else
lib/src/lib/libtbb.so: _build/math-$(MATH_VERSION)/lib/tbb/libtbb.so.2
	cp $< lib/src/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)

lib/src/lib/libtbb%.so: _build/math-$(MATH_VERSION)/lib/tbb/libtbb%.so.2
	cp $< lib/src/lib/$(notdir $<)
	@rm -f $@
	cd $(dir $@) && cp $(notdir $<) $(notdir $@)
endif

###############################################################################
# Build Stan-related shared libraries using Stan Math's Makefile rules
###############################################################################
# The file `Makefile.libraries` is a trimmed version of Stan Math's `makefile`,
# which uses the `include` directive to add rules from the `make/libraries`
# file (in Stan Math). `make/libraries` has all the rules required to build
# libsundials, libtbb, etc.
export MATH_VERSION

# locations where Stan Math's Makefile expects to output the shared libraries
SUNDIALS_LIBRARIES_BUILD_LOCATIONS := $(addprefix _build/math-$(MATH_VERSION)/lib/sundials_$(SUNDIALS_VERSION)/lib/,$(notdir $(SUNDIALS_LIBRARIES)))
ifeq ($(shell uname -s),Darwin)
  TBB_LIBRARIES_BUILD_LOCATIONS := _build/math-$(MATH_VERSION)/lib/tbb/libtbb.dylib _build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc.dylib _build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc_proxy.dylib
else
  TBB_LIBRARIES_BUILD_LOCATIONS := _build/math-$(MATH_VERSION)/lib/tbb/libtbb.so.2 _build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc.so.2 _build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc_proxy.so.2
endif

$(TBB_LIBRARIES_BUILD_LOCATIONS) $(SUNDIALS_LIBRARIES_BUILD_LOCATIONS): | _build/math-$(MATH_VERSION)
	$(MAKE) -f Makefile.libraries $@

# the following rule is required for parallel make
_build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc_proxy.dylib: _build/math-$(MATH_VERSION)/lib/tbb/libtbbmalloc.dylib

# the following variables should match those in ex_stan/models.py
# One include directory is absent: `model_directory_path` as this only
# exists when the extension module is ready to be linked
# EX_STAN_EXTRA_COMPILE_ARGS ?= -O3 -std=c++14
# EX_STAN_MACROS = -DBOOST_DISABLE_ASSERTS -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION -DSTAN_THREADS -D_REENTRANT -D_GLIBCXX_USE_CXX11_ABI=0
# EX_STAN_INCLUDE_DIRS = -Iex_stan -Ilib/src/include

# ex_stan/stan_services.o: ex_stan/stan_services.cpp ex_stan/socket_logger.hpp ex_stan/socket_writer.hpp | $(INCLUDES)
# 
# ex_stan/stan_services.o:
# 	$(CXX) \
# 		$(EX_STAN_MACROS) \
# 		$(EX_STAN_INCLUDE_DIRS) \
# 		-c $< -o $@ \
# 		$(EX_STAN_EXTRA_COMPILE_ARGS)
