defmodule App.CommunicationBroadcaster do
  @moduledoc """
  Communicationデータのブロードキャストを行うモジュール
  """

  # このモジュール名の文字列("App.CommunicationBroadcaster")をtopicにする
  @topic inspect(__MODULE__)

  @doc false
  def subscribe do
    Phoenix.PubSub.subscribe(App.PubSub, @topic)
  end

  @doc false
  def broadcast({event, data}) do
    Phoenix.PubSub.broadcast(App.PubSub, @topic, {event, data})
    {:ok, data}
  end
end
