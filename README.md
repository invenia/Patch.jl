Mocking
=======

[![Build Status](https://travis-ci.org/invenia/Mocking.jl.svg?branch=master)](https://travis-ci.org/invenia/Mocking.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/la041r86v6p5k24x?svg=true)](https://ci.appveyor.com/project/omus/mocking-jl)
[![codecov.io](http://codecov.io/github/invenia/Mocking.jl/coverage.svg?branch=master)](http://codecov.io/github/invenia/Mocking.jl?branch=master)

Allows Julia function calls to be temporarily overloaded for purpose of testing.

Contents
--------

- [Usage](#usage)
- [Gotchas](#gotchas)
- [Notes](#notes)

Usage
-----

Suppose you wrote the function `randdev` (UNIX only). How would you go about writing tests
for it?

```julia
function randdev(n::Integer)
    open("/dev/urandom") do fp
        reverse(read(fp, n))
    end
end
```

The non-deterministic behaviour of this function makes it hard to test but we can write some
tests dealing with the deterministic properties of the function:

```julia
using Base.Test
import ...: randdev

n = 10
result = randdev(n)
@test eltype(result) == UInt8
@test length(result) == n
```

How could we create a test that shows the output of the function is reversed?
 Mocking.jl provides a mechanism which allows package developers to temporarily overload a
specific calls in their package. In this example we will mock the `open` call
in `randdev`.
No changes are required at the call site.


We just need to write a testcase which allows
us to demonstrate the reversing behaviour within the `randdev` function.
This is done using the `@patch` macro, to define a patch,
which is applied to a block of code using the `apply` function.
As shown in the example below:

```julia
using Mocking

using Base.Test
import ...: randdev

...

# Produces a string with sequential UInt8 values from 1:n
data = unsafe_string(pointer(convert(Array{UInt8}, 1:n)))

# Generate a alternative method of `open` which call we wish to mock
patch = @patch open(fn::Function, f::AbstractString) = fn(IOBuffer(data))

# Apply the patch which will modify the behaviour for our test
apply(patch) do
    @test randdev(n) == convert(Array{UInt8}, n:-1:1)
end

# Outside of the scope of the patched environment behavour is
# as it was before
@test randdev(n) != convert(Array{UInt8}, n:-1:1)
```

Gotchas
-------

 - Remember to `using`/`import` functions before you `@patch` them.
 - You can not mock a method that does not exist.

Mocking.jl relies heavily on [Cassette.jl](https://github.com/jrevels/Cassette.jl).
Many issues that affect Cassette.jl will also affect Mocking.jl.


License
-------

Mocking.jl is provided under the [MIT "Expat" License](LICENSE.md).
