defmodule EctoEncryptedId.Encryption do
  @moduledoc """
  Module that allows to work with encrypted values directly.
  """

  @doc """
  Encrypt the value using AES256GCM cypher, then encode using Base62
  """
  @spec encrypt(num :: integer(), key :: binary(), salt :: binary()) :: String.t()
  def encrypt(num, key, salt) do
    <<num::integer-signed-64>>
    |> aes_encrypt(key, salt)
    |> :binary.decode_unsigned()
    |> Base62.encode()
  end

  @doc """
  Decode the value from Base62, then decrypt using AES256GCM cypher.
  """
  @spec decrypt(encrypted :: String.t(), key :: binary()) :: {:ok, integer()} | :error
  def decrypt(encrypted, key) do
    with {:ok, decoded_int} <- Base62.decode(encrypted),
         # encrypted size is 40 bytes
         encrypted_bin <- <<decoded_int::integer-unsigned-320>>,
         decrypted when is_binary(decrypted) <- aes_decrypt(encrypted_bin, key) do
      <<num::integer-signed-64>> = decrypted
      {:ok, num}
    end
  end

  defp aes_encrypt(plaintext, key, salt) do
    # Use mac as deterministic Initialisation Vector.
    # poly1305 is a great fit because of short 16 byte results.
    # Append salt before hashing to make sure different id have different IVs.
    iv = :crypto.mac(:poly1305, [key], [plaintext, salt])
    {encrypted, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, "", true)
    iv <> tag <> encrypted
  end

  defp aes_decrypt(encrypted, key) do
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = encrypted
    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, "", tag, false)
  end
end
