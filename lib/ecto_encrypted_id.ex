defmodule EctoEncryptedId do
  @moduledoc """
  Documentation for `EctoEncryptedId`.
  """

  @doc false
  def app_env_key() do
    Application.fetch_env!(:ecto_encrypted_id, :settings)[:secret_key]
  end

  @doc """
  Helper function to delegate to Phoenix.Param implementations for Ecto schemas.
  Returns encrypted version of the id.

  ## Example

  In your schema module:

      defimpl Phoenix.Param, for: __MODULE__ do
        defdelegate to_param(term), to: EctoEncryptedId, as: :encrypted_param
      end
  """
  def encrypted_param(%{id: %{encrypted: id}}), do: id

  @doc """
  Helper function to delegate to Phoenix.Param implementations for Ecto schemas.
  Returns plain version of the id.

  ## Example

  In your schema module:

      defimpl Phoenix.Param, for: __MODULE__ do
        defdelegate to_param(term), to: EctoEncryptedId, as: :plain_param
      end
  """
  def plain_param(%{id: %{plain: id}}), do: id

  defmodule DecryptionError do
    @moduledoc """
    Exception raised when bang `from_encrypted!/2` functions can't decrypt a value
    """
    defexception [:message, plug_status: 400]
  end

  defmacro __using__(opts) do
    iv_salt = Keyword.fetch!(opts, :salt)
    secret_key_fn = Keyword.get(opts, :secret_key_fn, &EctoEncryptedId.app_env_key/0)

    quote location: :keep do
      use Ecto.Type

      defmodule Id do
        @moduledoc """
        Container type for the encrypted field.
        Implements struct storing the id and related functions.
        """
        alias EctoEncryptedId.Encryption

        @type t :: %__MODULE__{
                encrypted: String.t(),
                plain: integer()
              }

        @enforce_keys [:encrypted, :plain]
        defstruct [:encrypted, :plain]

        @doc """
        Create id struct from an encrypted value.

        Supported options:
        - :secret_key_fn - custom function to fetch secret key

        Returns `{:ok, %Id{}}` on success or :error on failure
        """
        @spec from_encrypted(id :: String.t(), opts :: keyword()) :: {:ok, t()} | :error
        def from_encrypted(id, opts \\ []) do
          key = Keyword.get(opts, :secret_key_fn, unquote(secret_key_fn)).()

          case Encryption.decrypt(id, key) do
            {:ok, decrypted} -> {:ok, %__MODULE__{encrypted: id, plain: decrypted}}
            :error -> :error
          end
        end

        @doc """
        Create id struct from an encrypted value.
        When `key` argument is not provided use the secret key function
        (default function gets the key from the application environment).

        Supported options:
        - :secret_key_fn - custom function to fetch secret key

        Returns `%Id{}` on success.
        Raises `EctoEncryptedId.DecryptionError` on failure.
        """
        @spec from_encrypted!(id :: String.t(), opts :: keyword()) :: t()
        def from_encrypted!(id, opts \\ []) do
          key = Keyword.get(opts, :secret_key_fn, unquote(secret_key_fn)).()

          case Encryption.decrypt(id, key) do
            {:ok, decrypted} -> %__MODULE__{encrypted: id, plain: decrypted}
            :error -> raise(DecryptionError, "Invalid encrypted id: " <> id)
          end
        end

        @doc """
        Create id struct from a plain integer value.

        Supported options:
        - :secret_key_fn - custom function to fetch secret key

        Returns %Id{}.
        """
        @spec from_plain(id :: integer(), opts :: keyword()) :: t()
        def from_plain(id, opts \\ []) do
          key = Keyword.get(opts, :secret_key_fn, unquote(secret_key_fn)).()

          %__MODULE__{
            encrypted: Encryption.encrypt(id, key, unquote(iv_salt)),
            plain: id
          }
        end
      end

      # To avoid leaking plain ids in HTML
      if Code.ensure_loaded?(Phoenix.HTML.Safe) do
        defimpl Phoenix.HTML.Safe, for: Id do
          def to_iodata(id), do: id.enc
        end
      end

      # Ecto callbacks
      def type, do: :id

      def cast(id) when is_integer(id), do: {:ok, Id.from_plain(id)}
      def cast(id) when is_binary(id), do: Id.from_encrypted(id)
      def cast(%Id{} = id), do: {:ok, id}
      def cast(_), do: :error

      def dump(%Id{plain: plain}) when is_integer(plain), do: {:ok, plain}
      def dump(_), do: :error

      def load(id) when is_integer(id), do: {:ok, Id.from_plain(id)}
    end
  end
end
