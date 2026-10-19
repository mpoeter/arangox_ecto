defmodule ArangoXEcto.AdapterTest do
  use ExUnit.Case, async: true

  alias ArangoXEcto.Adapter

  describe "dumpers/2" do
    # Ecto calls dumpers with nil for unset fields inside embedded schemas
    for {primitive, type} <- [
          date: :date,
          time: :time,
          utc_datetime: :utc_datetime,
          naive_datetime: :naive_datetime,
          decimal: :decimal
        ] do
      test "#{primitive} dumps nil" do
        assert [dumper] = Adapter.dumpers(unquote(primitive), unquote(type))
        assert {:ok, nil} = dumper.(nil)
      end
    end

    test "date dumps to an ISO 8601 string" do
      assert [dumper] = Adapter.dumpers(:date, :date)
      assert {:ok, "2024-01-02"} = dumper.(~D[2024-01-02])
    end
  end
end
