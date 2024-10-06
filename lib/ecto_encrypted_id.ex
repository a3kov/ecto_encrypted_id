defmodule EctoEncryptedId do
  @moduledoc """
  Documentation for `EctoEncryptedId`.
  """

  def app_env_key() do
    Application.fetch_env!(:ecto_encrypted_id, :settings)[:secret_key]
  end

  defmodule DecryptionError do
    defexception [:message, plug_status: 400]
  end

  defmacro __using__(opts) do
    iv_salt = Keyword.fetch!(opts, :salt)
    secret_key_fn = Keyword.get(opts, :secret_key_fn, &EctoEncryptedId.app_env_key/0)

    quote location: :keep do
      use Ecto.Type

      defmodule Id do
        alias EctoEncryptedId.Encryption

        @type t :: %__MODULE__{
          encrypted: String.t(),
          plain: integer()
        }

        @enforce_keys [:encrypted, :plain]
        defstruct [:encrypted, :plain]

        @spec from_encrypted(String.t(), binary()) :: {:ok, __MODULE__.t()} | :error
        def from_encrypted(id, key \\ unquote(secret_key_fn).()) do
          case Encryption.decrypt(id, key) do
            {:ok, decrypted} -> {:ok, %__MODULE__{encrypted: id, plain: decrypted}}
            :error -> :error
          end
        end

        @spec from_encrypted!(String.t(), binary()) :: __MODULE__.t()
        def from_encrypted!(id, key \\ unquote(secret_key_fn).()) do
          case Encryption.decrypt(id, key) do
            {:ok, decrypted} -> %__MODULE__{encrypted: id, plain: decrypted}
            :error -> raise(DecryptionError, "Invalid encrypted id: " <> id)
          end
        end

        @spec from_plain(integer(), binary()) :: __MODULE__.t()
        def from_plain(id, key \\ unquote(secret_key_fn).()) do
          %__MODULE__{
            encrypted: Encryption.encrypt(id, key, unquote(iv_salt)),
            plain: id
          }
        end
      end

      # Optional Phoenix.Param impl
      def encrypted_param(%{id: %Id{encrypted: id}}), do: id
      def plain_param(%{id: %Id{plain: id}}), do: id

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
