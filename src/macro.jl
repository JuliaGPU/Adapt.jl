"""
    Adapt.@adapt_structure T

Define a method `adapt_structure(to, obj::T)` which calls `adapt_structure` on each field
of `obj` and constructs a new instance of `T` using the default constuctor `T(...)`.
"""
macro adapt_structure(T)
    quote
        @generated function $Adapt.adapt_structure($(esc(:to)), $(esc(:obj))::$(esc(T)))
            assignments = Any[:($$Adapt.adapt_structure(to, obj.$name)) for name in fieldnames($(esc(:obj)))]
            return Expr(:call, $(esc(T)), assignments...)
        end
    end
end
