class ChatAction < Cramp::Websocket
  on_start :create_redis
  on_finish :handle_leave, :destroy_redis
  on_data :received_data
  
  def create_redis
    @pub = EM::Hiredis.connect("redis://localhost:6379")
    @sub = EM::Hiredis.connect("redis://localhost:6379")
  end
  
  def destroy_redis
    @pub.close_connection
    @sub.close_connection
  end
  
  def received_data(data)
    msg = parse_json(data)
    case msg[:action]
    when 'join'
      handle_join(msg)
    when 'message'
      handle_message(msg)
    else
      # skip
    end
  end
  
  def handle_join(msg)
    @user = msg[:user]
    subscribe
    publish :action => 'control', :user => @user, :message => 'joined the chat room'
  end
  
  def handle_leave
    publish :action => 'control', :user => @user, :message => 'left the chat room'
  end
  
  def handle_message(msg)
    publish msg.merge(:user => @user)
  end
  
  private

  def subscribe
    @sub.subscribe('chat')
    @sub.on(:message) {|channel, message| render(message) }    
  end
  
  def publish(message)
    @pub.publish('chat', encode_json(message))
  end
  
  def encode_json(obj)
    Yajl::Encoder.encode(obj)
  end
  
  def parse_json(str)
    Yajl::Parser.parse(str, :symbolize_keys => true)
  end
end
