defmodule ArangoXEcto.Behaviour.Transaction do
  @moduledoc false

  alias ArangoXEcto.Adapter

  @behaviour Ecto.Adapter.Transaction

  @impl true
  def in_transaction?(%{pid: pool}) do
    match?(%DBConnection{conn_mode: :transaction}, Adapter.get_conn(pool))
  end

  @impl true
  def transaction(adapter_meta, opts, callback) do
    opts = declare_collections(adapter_meta, opts)

    Adapter.checkout_or_transaction(:transaction, adapter_meta, opts, callback)
  end

  @impl true
  def rollback(%{pid: pool}, value) do
    case Adapter.get_conn(pool) do
      %DBConnection{conn_mode: :transaction} = conn -> Arangox.abort(conn, value)
      _ -> raise "cannot call rollback outside of transaction"
    end
  end

  # Ecto starts transactions on its own, e.g. when inserting a struct with changed embeds, and
  # has no way of telling us which collections are written to. ArangoDB rejects writes to
  # collections that were not declared when the stream transaction began, so in that case all
  # collections of the database are declared as writable.
  @declarable_keys [:read, :write, :exclusive]
  defp declare_collections(%{repo: repo} = adapter_meta, opts) do
    if Enum.any?(@declarable_keys, &Keyword.has_key?(opts, &1)) or in_transaction?(adapter_meta) do
      opts
    else
      url = ArangoXEcto.__build_connection_url__(repo, "collection", opts, "?excludeSystem=true")

      case ArangoXEcto.api_query(adapter_meta, :get, url, "", %{}, opts) do
        {:ok, %{body: %{"result" => collections}}} ->
          Keyword.put(opts, :write, Enum.map(collections, & &1["name"]))

        _ ->
          opts
      end
    end
  end
end
