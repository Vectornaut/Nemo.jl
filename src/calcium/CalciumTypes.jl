###############################################################################
#
#   CalciumTypes.jl : Parent and object types for Calcium
#
###############################################################################

export CalciumQQBarField, qqbar, CalciumField, ca, options

################################################################################
#
#  Structs for shallow operations
#
################################################################################

mutable struct qqbar_struct
  coeffs::Ptr{Nothing}
  alloc::Int
  length::Int
  real_mid_exp::Int     # fmpz
  real_mid_size::UInt # mp_size_t
  real_mid_d1::UInt    # mantissa_struct
  real_mid_d2::UInt
  real_rad_exp::Int     # fmpz
  real_rad_man::UInt
  imag_mid_exp::Int     # fmpz
  imag_mid_size::UInt # mp_size_t
  imag_mid_d1::UInt    # mantissa_struct
  imag_mid_d2::UInt
  imag_rad_exp::Int     # fmpz
  imag_rad_man::UInt
end

mutable struct fexpr_struct
  data::Ptr{Nothing}
  alloc::Int
end

################################################################################
#
#  Types and memory management for QQBarField
#
################################################################################

mutable struct CalciumQQBarField <: Field
end

const CalciumQQBar = CalciumQQBarField()

mutable struct qqbar <: FieldElem
  coeffs::Ptr{Nothing}
  alloc::Int
  length::Int
  real_mid_exp::Int     # fmpz
  real_mid_size::UInt # mp_size_t
  real_mid_d1::UInt    # mantissa_struct
  real_mid_d2::UInt
  real_rad_exp::Int     # fmpz
  real_rad_man::UInt
  imag_mid_exp::Int     # fmpz
  imag_mid_size::UInt # mp_size_t
  imag_mid_d1::UInt    # mantissa_struct
  imag_mid_d2::UInt
  imag_rad_exp::Int     # fmpz
  imag_rad_man::UInt

  function qqbar()
    z = new()
    ccall((:qqbar_init, libcalcium), Nothing, (Ref{qqbar}, ), z)
    finalizer(_qqbar_clear_fn, z)
    return z
  end

end

function _qqbar_clear_fn(a::qqbar)
   ccall((:qqbar_clear, libcalcium), Nothing, (Ref{qqbar},), a)
end

################################################################################
#
#  Types and memory management for CalciumField
#
################################################################################

ca_ctx_options = [
    :verbose,
    :print_flags,
    :mpoly_ord,
    :prec_limit,
    :qqbar_deg_limit,
    :low_prec,
    :smooth_limit,
    :lll_prec,
    :pow_limit,
    :use_gb,
    :gb_length_limit,
    :gb_poly_length_limit,
    :gb_poly_bits_limit,
    :vieta_limit,
    :trig_form]

mutable struct CalciumField <: Field
   ext_cache_items::Ptr{Nothing}
   ext_cache_length::Int
   ext_cache_alloc::Int
   ext_cache_hash_size::Int
   ext_cache_hash_table::Ptr{Nothing}
   field_cache_items::Ptr{Nothing}
   field_cache_length::Int
   field_cache_alloc::Int
   field_cache_hash_size::Int
   field_cache_hash_table::Ptr{Nothing}
   field_qq::Ptr{Nothing}
   field_qq_i::Ptr{Nothing}
   mctx::Ptr{Nothing}
   mctx_len::Int
   options::Ptr{Int}

   extended::Bool

   function CalciumField(; extended::Bool=false, options::Dict{Symbol,Int}=Dict{Symbol,Int}())
      C = new()
      ccall((:ca_ctx_init, libcalcium), Nothing, (Ref{CalciumField}, ), C)
      finalizer(_CalciumField_clear_fn, C)
      C.extended = extended

      for (opt, value) in options
         i = findfirst(isequal(opt), ca_ctx_options)
         (i == nothing) && error("unknown option ", opt)
         ccall((:ca_ctx_set_option, libcalcium), Nothing, (Ref{CalciumField}, Int, Int), C, i - 1, value)
      end

      return C
   end
end

function options(C::CalciumField)
   d = Dict{Symbol,Int}()
   for i=1:length(ca_ctx_options)
      d[ca_ctx_options[i]] = ccall((:ca_ctx_get_option, libcalcium), Int, (Ref{CalciumField}, Int), C, i - 1)
   end
   return d
end

function _CalciumField_clear_fn(C::CalciumField)
   ccall((:ca_ctx_clear, libcalcium), Nothing, (Ref{CalciumField},), C)
end

mutable struct ca <: FieldElem
   field::Int
   data0::UInt
   data1::UInt
   data2::UInt
   data3::UInt
   # end C struct

   parent::CalciumField

   function ca(ctx::CalciumField)
      z = new()
      ccall((:ca_init, libcalcium), Nothing,
                (Ref{ca}, Ref{CalciumField}), z, ctx)
      z.parent = ctx
      finalizer(_ca_clear_fn, z)
      return z
   end

end

function _ca_clear_fn(a::ca)
   ccall((:ca_clear, libcalcium),
        Nothing, (Ref{ca}, Ref{CalciumField}), a, parent(a))
end

