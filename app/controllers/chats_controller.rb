class ChatsController < ApplicationController
  before_filter :authenticate_user!

  def show
    render_ember
  end

  def create
    if params.has_key?(:message)
      MessageBus.publish "/chat", {
        id: params[:id],
        message: params[:message],
        formatted_message: MessageFormatter.format_message(params[:message]),
        username: current_user.name,
        delivered: true
      }
    end

    render json: true
  end

  def ping
    $redis.with do |conn|
      time = Time.now.to_i
      conn.zadd "chat_online", time, current_user.id
      active_user_ids = conn.zrangebyscore "chat_online", time-60, "+inf"
      active_users = User.where(id: active_user_ids).order(:id)
      render json: (active_users.map do |user|
        {
          username: user.name,
          avatar: user.avatar.url(:thumb_small)
        }
      end).to_json
    end
  end
end
