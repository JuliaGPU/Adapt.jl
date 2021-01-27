"""
    Adapt.@adapt_structure T

Define a method `adapt_structure(to, obj::T)` which calls `adapt_structure` on each field
of `obj` and constructs a new instance of `T` using the default constuctor `T(...)`.
"""
macro adapt_structure(T)
    names = fieldnames(Core.eval(__module__, T))
    quote
        function Adapt.adapt_structure(to, obj::$(esc(T)))
            $(esc(T))($([:(Adapt.adapt_structure(to, obj.$name)) for name in names]...))
        end
    end    
end
