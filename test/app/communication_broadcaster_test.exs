defmodule App.CommunicationBroadcasterTest do
  use App.DataCase
  alias App.CommunicationBroadcaster

  describe "broadcaster" do
    test "broadcast/2 ブロードキャストされたデータを受信できること" do
      data = {:create_message, "some message"}

      CommunicationBroadcaster.subscribe()
      CommunicationBroadcaster.broadcast(data)
      assert_receive ^data
    end
  end
end
