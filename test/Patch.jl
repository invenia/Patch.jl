using Patch
using Base.Test

# Test the concept of overwritten methods in Julia
let generic() = "foo"
    @test generic() == "foo"
    generic() = "bar"
    @test generic() == "bar"
end

# generic functions that only exist within a let block currently cannot be overwritten (yet)
let generic() = "foo"
    @test generic() == "foo"
    @test_throws UndefVarError Main.generic()

    @test_throws MethodError Patch.override(generic, () -> "bar") do
        @test generic() == "bar"  # Note: Never executed
    end

    @test generic() == "foo"
    @test_throws UndefVarError Main.generic()
end

# Non-generic functions can be overridden no matter where they are defined
let anonymous = () -> "foo"
    @test anonymous() == "foo"
    Patch.override(anonymous, () -> "bar") do
        @test anonymous() == "bar"
    end
    @test anonymous() == "foo"
end

# Generic functions can be overwritten if they are defined globally within the module
let open = Base.open
    @test_throws SystemError open("foo")

    replacement = (name) -> name == "foo" ? "bar" : Original.open(name)
    @test_throws ErrorException Patch.patch(open, replacement) do nothing end

    @test_throws SystemError open("foo")

    replacement = (name::AbstractString) -> name == "foo" ? IOBuffer("bar") : Original.open(name)
    Patch.patch(open, replacement) do
        @test readall(open("foo")) == "bar"
        @test readall("foo") == "bar"  # patch doesn't overload internal calls
        @test isa(open(tempdir()), IOStream)
    end

    @test_throws SystemError open("foo")
end

# Let blocks seem more forgiving
@test_throws SystemError open("foobar.txt")

mock_open = (name::AbstractString) -> name == "foobar.txt" ? IOBuffer("Hello Julia") : Original.open(name)

patch(open, mock_open) do
    @test readall(open("foobar.txt")) == "Hello Julia"
    @test readall("foobar.txt") == "Hello Julia"  # patch doesn't overload internal calls
    @test isa(open(tempdir()), IOStream)
end

@test_throws SystemError open("foobar.txt")
