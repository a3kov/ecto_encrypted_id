# About

The library provides an easy way to create deterministically encrypted 
integer id fields for Ecto schemas. The fields can be used to hide actual
integer PK values from the outside world by replacing them with encrypted
versions (for example, in URLs).


## Why

* Thanks to the library it's possible to prevent resource enumeration
attacks. See https://owasp.org/www-community/attacks/Forced_browsing

* Also, we may want to use URL as a secret to access a resource.
Yes, it's an example of "security by obscurity", but sometimes it's the
right solution.

* We may want to hide some business information. If I'm registering on 
your fresh website, and my user id is 5 - as a user I will instantly know
I'm one of the early adopters and your business is not as established
as it portrays itself!

Using encryption on-the-fly is a great alternative to UUID primary keys 
in your database - using CPU cycles of your application servers in most 
cases is much better than wasting storage and memory of the DB server. 
Also UUIDs spread like a virus through foreign keys, unless you create
a separate integer field for references, which is a waste too.

The library mostly targets Postgres and you can encrypt any integer 
column Postgres supports (normal and autoincrement, signed and unsigned).

When using the library resource URLs may look like this:
https://example.com/posts/GLWsqG8DwIUxd7MecoTzDPg0fSLDN74qEyYy9Dw82SInd77vSi2Ops


## Installation

The package can be installed by adding `ecto_encrypted_id` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_encrypted_id, "~> 0.1"}
  ]
end
```
Prepare a 32bit encryption key. If you are using Phoenix:
```shell
$ mix phx.gen.secret

```
By default the library will try to use secret key provided in the application
environment. You can configure it in `runtime.exs` like this, for example:
```elixir
config :ecto_encrypted_id, :settings,
  secret_key: System.fetch_env!("SECRET")
```
If you don't like to use application environment, you can inject a function
providing the key (we will discuss it later).


## Usage

For every Ecto schema that will use an encrypted id in your project you should 
consider creating a separate module. The name of the module doesn't matter, but
it's better to name your modules so it's easy to understand which Id module 
corresponds to which schema. Let's say you have a Post schema:
```elixir
defmodule MyProject.PostId do
  use EctoEncryptedId, salt: "my_salt"
end
```
Note the `salt` parameter: it must be a string that is unique between field modules,
so that different models (schemas) don't share the same encrypted ids.

If you prefer to provide secret key in a different way, not by using app 
environment, you can pass a function returning the key like this:
```elixir
use EctoEncryptedId, salt: "my_salt", secret_key_fn: &MyProject.Secret.key/0
```

After that, add the field as a primary key for the schema. This example
is using autoincrementing integer PK:
```elixir
defmodule MyProject.Post do
  use Ecto.Schema

  @primary_key {:id, MyProject.PostId, autogenerate: true}
  schema "posts" do
    field :title, :string
  end
end
```
Now, every time you load the schema instance from the DB, `id` field
will contain an instance of `MyProject.PostId.Id`. See the 
`EctoEncryptedId.ExampleField.Id` module docs to get an idea on how to use it.

Also, if you are using Phoenix, consider adding `Phoenix.Param` implementation,
to be able to use your id in URLs, same way like you could with integers.
If you want to use encrypted versions:
```elixir
defmodule MyProject.Post do
  ...
  defimpl Phoenix.Param, for: __MODULE__ do
    defdelegate to_param(term), to: EctoEncryptedId, as: :encrypted_param
  end
  ...
end
```
Or if you want to keep the unencryped versions (not that it makes much sense,
but anyway):
```elixir
defmodule MyProject.Post do
  ...
  defimpl Phoenix.Param, for: __MODULE__ do
    defdelegate to_param(term), to: EctoEncryptedId, as: :plain_param
  end
  ...
end
```
The library provides `Phoenix.HTML.Safe` implementation that outputs encrypted 
versions in HTML automatically. This way you won't accidentally leak plain text
ids.


## Important Considerations

It may take a bit of time getting used to non-scalar id in models. But the library
doesn't try to make important decisions implicitly - as a developer you will
have to decide whether to use encrypted version or integer one, on a case-by-case
basis. Also, the additional decryption/encryption step for URLs may seem annoying,
and maybe it is, but the advantages brought by the library are worth the trouble
in many cases.

The encryption we use is deterministic - the encrypted id is defined by the secret
key and the salt. As long as you don't change them you can use the encrypted ids in
permalinks.

Also, as we discussed earlier, every field module should use different salt. The salt
is not secret, but the encryption key is.

Don't use existing secret keys from your project as the key for this library -
in case there's a possible leak, you should always change secrets that guard
real security stuff, like passwords and bank accounts, but in the case of this 
library, you could even prefer to keep using the leaked key just to avoid breaking
the permalinks. It's not like we are guarding government secrets here, right ? RIGHT ?

The encryption is intended to be strong enough for most cases (unless the attacker
is a 3-letter agency). But if you know something about cryptography your feedback
would be welcome.
